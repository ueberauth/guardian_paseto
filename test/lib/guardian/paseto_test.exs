defmodule Guardian.Token.PasetoTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Guardian.Token.Paseto, as: GuardianPaseto

  defp claims_generator() do
    ExUnitProperties.gen all key <- StreamData.string(:ascii, min_length: 1),
                             value <- StreamData.string(:ascii, min_length: 1) do
      %{key => value} |> Poison.encode!()
    end
  end

  defp secret_key_generator(version, purpose) do
    key_len = 32

    ExUnitProperties.gen all key <-
                               StreamData.string(:ascii, min_length: key_len, max_length: key_len) do
      case purpose do
        "local" ->
          key

        "public" ->
          case version do
            "v1" ->
              :crypto.generate_key(:rsa, {2048, 65_537})

            "v2" ->
              {:ok, pk, sk} = Salty.Sign.Ed25519.keypair()
              {pk, sk}
          end
      end
    end
  end

  defp version_generator() do
    ExUnitProperties.gen all key <- StreamData.member_of(["v1", "v2"]) do
      key
    end
  end

  defp purpose_generator() do
    ExUnitProperties.gen all key <- StreamData.member_of(["local", "public"]) do
      key
    end
  end

  defp token_generator(claims, kwargs) do
    ExUnitProperties.gen all _x <- StreamData.integer() do
      GuardianPaseto.create_token(%{}, claims, kwargs)
    end
  end

  property "Property tests for create_token/3" do
    check all claims <- claims_generator(),
              version <- version_generator(),
              purpose <- purpose_generator(),
              secret_key <- secret_key_generator(version, purpose),
              chosen_version = [version, purpose] |> Enum.join("_") |> String.to_atom(),
              kwargs = [secret_key: secret_key, allowed_algos: chosen_version],
              retval <- token_generator(claims, kwargs) do
      case retval do
        {:ok, token} ->
          assert is_binary(token)
          {:ok, %Paseto.Token{payload: payload}} = Paseto.parse_token(token, secret_key)
          assert payload == claims

        {:error, _reason} ->
          refute true
      end
    end
  end

  property "Property tests for revoke/4" do
    check all claims <- claims_generator(),
              revokation_response = GuardianPaseto.revoke(%{}, claims, "token", []),
              max_runs: 50 do
      assert revokation_response == {:ok, claims}
    end
  end

  property "Property tests for token_id/0" do
    check all _ <- StreamData.integer(),
              token_id = GuardianPaseto.token_id(),
              max_runs: 50 do
      {retatom, _retval} = UUID.info(token_id)
      assert retatom == :ok
    end
  end
end
