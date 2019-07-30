defmodule Guardian.Token.Paseto do
  @moduledoc """
  Implements the Guardian Token callbacks for Paseto.

  This module ought to only be used _from Guardian_. I.e.,
  please don't touch this module. If you're needing the underlying primitives
  for Paseto, please visit https://github.com/GrappigPanda/Paseto

  A short summary of what a token is (as a string):

  Tokens are broken up into several components:
  * version: v1 or v2 -- v2 suggested
  * purpose: Local or Public -- Local -> Symmetric Encryption for payload & Public -> Asymmetric Encryption for payload
  * payload: A signed or encrypted & b64 encoded string
  * footer: An optional value, often used for storing keyIDs or other similar info.
  """

  alias Guardian.Config

  @allowed_versions [:v1_local, :v1_public, :v2_local, :v2_public]
  @typep paseto_versions :: :v1_local | :v1_public | :v2_local | :v2_public

  @doc """
  Creates a Guardian.claims map with stringified keys.
  """
  @spec build_claims(
          mod :: module(),
          resource :: any(),
          sub :: String.t(),
          optional(claims) :: Guardian.claims(),
          optional(opts) :: Keyword.t()
        ) :: {:ok, Guardian.claims()} | {:error, atom()}
  def build_claims(_mod, _resource, _sub, claims \\ %{}, opts \\ [])

  def build_claims(_mod, _resource, _sub, claims, _opts) do
    stringified_claims =
      claims
      |> Guardian.stringify_keys()

    {:ok, stringified_claims}
  end

  @doc """
  Handles generating a token:

  Tokens are broken up into several components:
  * version: v1 or v2 — v2 suggested
  * purpose: Local or Public — Local -> Symmetric Encryption for payload & Public -> Asymmetric Encryption for payload
  * payload: A signed or encrypted & b64 encoded string
  * footer: An optional value, often used for storing keyIDs or other similar info.
  """
  @spec create_token(mod :: module(), claims :: map(), opts :: Keyword.t()) ::
          {:ok, String.t()}
          | Guardian.Token.signing_error()
          | Guardian.Token.encoding_error()
          | Guardian.Token.secret_error()
  def create_token(mod, claims, opts) do
    key = secret_key(mod, opts)
    claims = Poison.encode!(claims)
    do_create_token(mod, claims, opts, key)
  end

  @doc """
  Handles decoding a token to get the claims.

  NOTE: This is the first part of a 2-part hack involving `decode_token` and `verify_claims`. See `verify_claims` for more information, but, in short, we'll be returning the `token` within a map so that `verify_claims` can fully work.
  """
  @spec decode_token(mod :: module(), token :: String.t(), Keyword.t()) ::
          {:ok, %{required(:token) => String.t()}}
          | Guardian.secret_error()
          | Guardian.decoding_error()
  def decode_token(_mod, token, _opts) do
    {:ok, %{token: token}}
  end

  @doc """
  Grabs the claims from the token _without_ having done any verification.

  NOTE: This will only work on `public` purposed Paseto tokens due to the fact that encrytped tokens inherently can't be looked at without also verifying.
  """
  @spec peek(mod :: module(), token :: Guardian.token()) :: map()
  def peek(_mod, token) do
    token
    |> Paseto.peek()
    |> case do
      claims when is_binary(claims) ->
        Poison.decode!(claims)

      error ->
        error
    end
  end

  @doc """
  Refreshes a token.
  """
  @spec refresh(mod :: module(), token :: Guardian.token(), opts :: Keyword.t()) ::
          {:ok, {Guardian.token(), Guardian.claims()}, {Guardian.token(), Guardian.claims()}}
          | {:error, any()}
  def refresh(mod, original_token, opts) do
    with {:ok, decoded_token} <- decode_token(mod, original_token, opts),
         {:ok, original_claims} <- verify_claims(mod, decoded_token, opts),
         {:ok, new_token} <- create_token(mod, original_claims, opts) do
      {:ok, {original_token, original_claims}, {new_token, original_claims}}
    else
      error ->
        error
    end
  end

  @doc """
  `revoke` callback specifically implemented for `Guardian.Token`.

  NOTE: There is no actual revokation method for a Paseto, so this just returns the claims
  """
  @spec revoke(mod :: module(), claims :: map(), token :: String.t(), opts :: Keyword.t()) ::
          {:ok, map()}
  def revoke(_mod, claims, _token, _opts), do: {:ok, claims}

  @doc """
  Generates a unique identifier for the token.
  """
  @spec token_id() :: String.t()
  def token_id, do: UUID.uuid4()

  @doc """
  Verifies a claims object was issued by the issuing key.

  NOTE: The `claims` argument being passed in will actually be an entire token due to the limitations of verification for Guardian--in short, the entire token is needed to verify the validity of a Paseto.
  """
  @spec verify_claims(
          mod :: module(),
          token :: %{required(:token) => String.t()},
          opts :: Keyword.t()
        ) :: {:ok, Guardian.claims()} | {:error, any()}
  def verify_claims(mod, %{token: token}, opts) do
    secret_key =
      mod
      |> secret_key(opts)

    token
    |> Paseto.parse_token(secret_key)
    |> case do
      {:ok, %Paseto.Token{payload: payload}} ->
        {:ok, payload}

      {:error, error} = retval when is_atom(error) ->
        retval

      {:error, _error} ->
        {:error, :verification_failed}
    end
  end

  ##############################
  # Internal Private Functions #
  ##############################

  @spec do_create_token(
          mod :: module(),
          claims :: String.t(),
          opts :: Keyword.t(),
          secret_key :: any() | nil
        ) ::
          {:ok, String.t()}
          | Guardian.Token.signing_error()
          | Guardian.Token.encoding_error()
          | Guardian.Token.secret_error()
  defp do_create_token(_mod, _claims, _opts, nil) do
    {:error, :secret_not_found}
  end

  defp do_create_token(mod, claims, opts, secret_key) do
    {version, purpose} =
      case chosen_version(mod, opts) do
        :v1_local ->
          {"v1", "local"}

        :v1_public ->
          {"v1", "public"}

        :v2_local ->
          {"v2", "local"}

        :v2_public ->
          {"v2", "public"}
      end

    case Paseto.generate_token(version, purpose, claims, secret_key) do
      token when is_binary(token) ->
        {:ok, token}

      {:error, _reason} ->
        {:error, :encoding_error}
    end
  end

  @spec chosen_version(mod :: module(), opts :: Keyword.t()) :: paseto_versions
  defp chosen_version(mod, opts) do
    get_config_value(mod, opts, :allowed_algos, [:allowed_algos, @allowed_versions])
  end

  @spec secret_key(mod :: module(), opts :: Keyword.t()) :: any()
  defp secret_key(mod, opts) do
    get_config_value(mod, opts, :secret_key, [:secret_key])
  end

  @spec get_config_value(mod :: module(), opts :: Keyword.t(), key_name :: atom(), args :: list()) ::
          any()
  defp get_config_value(mod, opts, key_name, args) do
    opts
    |> Keyword.get(key_name)
    |> Config.resolve_value() || apply(mod, :config, args)
  end
end
