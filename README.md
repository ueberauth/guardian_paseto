# GuardianPaseto

[![CircleCI](https://circleci.com/gh/GrappigPanda/guardian_paseto/tree/master.svg?style=svg)](https://circleci.com/gh/GrappigPanda/guardian_paseto/tree/master)
[![Hex.pm](https://img.shields.io/hexpm/v/guardian_paseto.svg)](https://hex.pm/packages/guardian_paseto)
[HexDocs](https://hexdocs.pm/guardian_paseto/api-reference.html)

## Considerations for using this library

There are a few library/binary requirements required in order for the Paseto 
library to work on any computer:
1. Erlang version >= 20.1
    * This is required because this was the first Erlang version to introduce
      crypto:sign/5.
2. libsodium >= 1.0.13 
    * This is required for cryptography used in Paseto.
    * This can be found at https://github.com/jedisct1/libsodium
3. openssl >= 1.1 
    * This is needed for XChaCha-Poly1305 used for V2.Local Paseto
    
## How to use

NOTE: This was basically 100% plagiarized from the Guardian documentation, so, for further configuration options, please visit their documentation at: [Guardian](https://github.com/ueberauth/guardian)

Guardian requires that you create an "Implementation Module". This module is your applications implementation for a particular type/configuration of token. You do this by `use`ing Guardian in your module and adding the relevant configuration.

Add Guardian to your application

mix.exs

```elixir
defp deps do
  [
    {:guardian, "~> 1.0"},
    {:guardian_paseto, "~> 0.2.0"}
  ]
end
```

Create a module that uses `Guardian`

```elixir
defmodule MyApp.Guardian do
  use Guardian, otp_app: :my_app

  def subject_for_token(resource, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = to_string(resource.id)
    {:ok, sub}
  end
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(claims) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In `above subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.
    id = claims["sub"]
    resource = MyApp.get_resource_by_id(id)
    {:ok,  resource}
  end
  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
```

Add your configuration

```elixir
config :my_app, MyApp.Guardian,
       issuer: "my_app",
       secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"
       allowed_algos: [:v2_local]
```

With this level of configuration, you can have a working installation.

## Installation

This package can be installed by adding `guardian_paseto` to your list of 
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:guardian_paseto, "~> 0.1.0"}
  ]
end
```
