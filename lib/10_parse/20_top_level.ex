defmodule TransformerTestSupport.Parse.TopLevel do
  use TransformerTestSupport.Drink.Me
  alias T.Parse.ExampleAdjustments
  import DeepMerge, only: [deep_merge: 2]
  alias T.Nouns.AsCast
  alias T.Parse.Hooks
  alias T.Parse.Nouns.Example

  # ----------------------------------------------------------------------------
  def field_transformations(test_data, opts) do
    as_cast =
      AsCast.new(test_data.module_under_test,
        Keyword.get_values(opts, :as_cast) |> Enum.concat)

    calculators =
      opts
      |> Keyword.delete(:as_cast)
      |> KeywordX.assert_no_duplicate_keys

    test_data
    |> Map.update!(:as_cast, &(AsCast.merge(&1, as_cast)))
    |> Map.update!(:field_calculators, &(Keyword.merge(&1, calculators)))
    |> deep_merge(%{field_transformations: opts})
  end

  # ----------------------------------------------------------------------------
  def workflow(test_data, workflow, raw_examples) do
    Hooks.run_variant(test_data, :assert_workflow_hook, [workflow])
    
    updated_examples =
      ExampleAdjustments.adjust(:example_pairs, raw_examples)
      |> attach_workflow_metadata(workflow)
      |> ExampleAdjustments.CrossExample.expand_likes(test_data.examples)
      |> KeywordX.map_over_values(&Example.add_setup_required_by_refs/1)

    Map.update!(test_data, :examples, &(updated_examples ++ &1))
  end

  defp attach_workflow_metadata(pairs, workflow) do
    for {name, example} <- pairs do
      metadata = %{metadata: %{workflow_name: workflow, name: name}}
      {name, deep_merge(example, metadata)}
    end
  end
  
  # ----------------------------------------------------------------------------
  def replace_steps(test_data, replacements) do
    replacements = Enum.into(replacements, %{})
    DeepMerge.deep_merge(test_data, %{steps: replacements})
  end

  # ----------------------------------------------------------------------------
  @doc """
  May be useful for debugging
  """
  def example(test_data, example_name),
    do: test_data.examples |> Keyword.get(example_name)

  # ----------------------------------------------------------------------------
  def propagate_metadata(test_data) do
    metadata = Map.delete(test_data, :examples) # Let's not have a recursive structure.
    new_examples = 
      for {name, example} <- test_data.examples do
        {name, deep_merge(example, %{metadata: metadata})}
      end
    Map.put(test_data, :examples, new_examples)
  end
  
end
