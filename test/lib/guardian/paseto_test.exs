defmodule Guardian.Token.PasetoTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Guardian.Token.Paseto

  property "Property tests for token_id/0" do
    check all _ <- StreamData.integer,
      token_id = Paseto.token_id(),
      max_runs: 50 do

      {retatom, _retval} = UUID.info(token_id)
      assert retatom == :ok
    end
  end
end
