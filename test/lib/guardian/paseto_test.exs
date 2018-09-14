defmodule Guardian.Token.PasetoTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Guardian.Token.Paseto

  defp claims_generator() do
    ExUnitProperties.gen all key <- StreamData.string(:ascii, min_length: 1),
      value <- StreamData.string(:ascii, min_length: 1) do
      %{key => value}
    end
  end

  property "Property tests for revoke/4" do
    check all claims <- claims_generator(),
      revokation_response = Paseto.revoke(%{}, claims, "token", []),
      max_runs: 50 do

      assert revokation_response == {:ok, claims}
    end
  end

  property "Property tests for token_id/0" do
    check all _ <- StreamData.integer,
      token_id = Paseto.token_id(),
      max_runs: 50 do

      {retatom, _retval} = UUID.info(token_id)
      assert retatom == :ok
    end
  end
end
