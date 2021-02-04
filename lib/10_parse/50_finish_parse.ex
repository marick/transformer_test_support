defmodule EctoTestDSL.Parse.FinishParse do
  use EctoTestDSL.Drink.Me
  use EctoTestDSL.Drink.AssertionJuice
  import DeepMerge, only: [deep_merge: 2]
  alias T.Parse.Node
  use Magritte

  @moduledoc """
  """

  def finish(test_data) do
    examples = test_data.examples
    examples_module = test_data.examples_module

    new_test_data = 
      Enum.reduce(examples, test_data, fn {name, example}, acc ->
        improved = 
          example
          |> propagate_metadata(test_data)
          |> Node.Group.parse_time_substitutions(acc.examples)
          |> Map.update(:previously, [], &Node.Previously.parse/1)
          |> Node.Group.handle_eens(examples_module)
        
        # Note: it is important for each example to be put in the
        # test_data map as it's finished because later examples can
        # refer back to earlier ones.
        put_in(acc, [:examples, name], improved)
      end)

    simplified = KeywordX.map_over_values(new_test_data.examples, &Node.Group.simplify/1)
    Map.put(test_data, :examples, simplified)
  end

  def propagate_metadata(example, test_data) do
    metadata = Map.delete(test_data, :examples) # Let's not have a recursive structure.
    deep_merge(example, %{metadata: metadata})
  end
end
