# GuardianPaseto

[![CircleCI](https://circleci.com/gh/GrappigPanda/guardian_paseto/tree/master.svg?style=svg)](https://circleci.com/gh/GrappigPanda/guardian_paseto/tree/master)
[![Hex.pm](https://img.shields.io/hexpm/v/guardian_paseto.svg)](https://hex.pm/packages/guardian_paseto)
[HexDocs](https://hexdocs.pm/guardian_paseto/api-reference.html)

**TODO: Add description**

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
