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
    do_create_token(mod, claims, opts, key)
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

  ##############################
  # Internal Private Functions #
  ##############################

  @spec do_create_token(
          mod :: module(),
          claims :: map(),
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
