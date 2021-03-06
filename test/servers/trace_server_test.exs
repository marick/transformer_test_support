defmodule TraceServerTest do
  use EctoTestDSL.Drink.Me
  use EctoTestDSL.Drink.AndRun
  
  use ExUnit.Case, async: false
  alias T.TraceServer

  test "indentation leaders" do
    pass = fn arg, expected -> 
      TraceServer.nested(fn ->
        actual = TraceServer.indented(arg) |> IO.iodata_to_binary
        assert actual == expected
      end)
    end

    "hi"   |> pass.("  hi")
    ["hi"] |> pass.("  hi")

    "hi\nbye" |> pass.("  hi\n  bye")
  end
end
