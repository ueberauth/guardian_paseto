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

  @doc """
  `revoke` callback specifically implemented for `Guardian.Token`.

  NOTE: There is no actual revokation method for a Paseto, so this just returns the claims
  """
  @spec revoke(module(), map(), String.t(), Keyword.t()) :: {:ok, map()}
  def revoke(_mod, claims, _token, _opts), do: {:ok, claims}

  @doc """
  Generates a unique identifier for the token.
  """
  @spec token_id() :: String.t()
  def token_id, do: UUID.uuid4()
end
