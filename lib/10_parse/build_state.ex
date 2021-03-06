defmodule EctoTestDSL.Parse.BuildState do
  use EctoTestDSL.Drink.Me
  alias T.Parse.BuildState

  def put(map) do
    Process.put(BuildState, map)
    map
  end

  def current do
    Process.get(BuildState)
  end

  def examples_module do
    current().examples_module
  end

  # This N^2 process of building up examples makes it easier to 
  # correctly have one example refer to a previous one.
  # It shouldn't be necessary to keep them in order, but I like the
  # internal representation to look like the source.
  def add_example(example_pair) do
    current()
    |> Map.update!(:examples, &(&1 ++ [example_pair]))
    |> put
  end
end
