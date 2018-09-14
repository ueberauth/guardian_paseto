defmodule Guardian.Token.PasetoTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Guardian.Token.Paseto, as: GuardianPaseto

  defp claims_generator(_x \\ :string)

  defp claims_generator(:atom) do
    ExUnitProperties.gen all key <- StreamData.atom(:alphanumeric),
                             value <- StreamData.atom(:alphanumeric) do
      %{key => value}
    end
  end

  defp claims_generator(:string) do
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

  property "Property tests for build_claims/5" do
    check all claims <- claims_generator(:atom),
              {:ok, built_claims} = GuardianPaseto.build_claims(%{}, %{}, %{}, claims) do
      assert Enum.all?(Enum.map(Map.keys(built_claims), &is_binary/1))
    end
  end

  property "Property tests for create_token/3" do
    check all claims <- claims_generator(),
              version <- version_generator(),
              purpose <- purpose_generator(),
              secret_key <- secret_key_generator(version, purpose),
              chosen_version = [version, purpose] |> Enum.join("_") |> String.to_atom(),
              kwargs = [secret_key: secret_key, allowed_algos: chosen_version],
              {:ok, token} <- token_generator(claims, kwargs) do
      assert is_binary(token)
      {:ok, %Paseto.Token{payload: payload}} = Paseto.parse_token(token, secret_key)
      assert payload == claims

      {:ok, decoded_token} = GuardianPaseto.decode_token(%{}, token, kwargs)
      assert {:ok, claims} == GuardianPaseto.verify_claims(%{}, decoded_token, kwargs)

      case purpose do
        "public" ->
          assert Poison.decode!(claims) == GuardianPaseto.peek(%{}, token, kwargs)

        "local" ->
          assert {:error, :no_peek_for_encrypted_tokens} ==
                   GuardianPaseto.peek(%{}, token, kwargs)
      end
    end
  end

  property "Property tests for revoke/3" do
    check all claims <- claims_generator(),
              version <- version_generator(),
              purpose <- purpose_generator(),
              secret_key <- secret_key_generator(version, purpose),
              chosen_version = [version, purpose] |> Enum.join("_") |> String.to_atom(),
              kwargs = [secret_key: secret_key, allowed_algos: chosen_version],
              {:ok, token} <- token_generator(claims, kwargs),
              {:ok, {_old_token, old_claims}, {_new_token, new_claims}} =
                GuardianPaseto.refresh(%{}, token, kwargs) do
      assert old_claims == new_claims
      assert new_claims == claims
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
