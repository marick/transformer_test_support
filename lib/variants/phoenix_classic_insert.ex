defmodule TransformerTestSupport.Variants.PhoenixClassic.Insert do
  use TransformerTestSupport.Drink.Me
  alias T.Run.Steps
  alias T.Variants.PhoenixClassic.Insert, as: ThisVariant
  import T.Variants.Macros
  alias T.Parse.Start
  alias T.Parse.Callbacks
  import FlowAssertions.Define.BodyParts
  # ------------------- Step functions -----------------------------------------

  defsteps [
    :previously,
    :params,
    :changeset_from_params,
    {:check_validation_changeset, [:changeset_from_params]},
    
    {:insert_changeset,           [:changeset_from_params]},
    {:check_insertion_result,     [:insert_changeset]},
    {:check_constraint_changeset, [:insert_changeset]}
  ], from: Steps

  def workflows() do
    from_start_through_changeset = [
      :previously,
      :params,
      :changeset_from_params,
    ]

    from_start_through_validation = from_start_through_changeset ++ [
      :check_validation_changeset, 
    ]
    
    %{
      validation_success: from_start_through_validation,
      validation_error: from_start_through_changeset,
      
      constraint_error: from_start_through_validation ++ [
        :insert_changeset, 
        :check_constraint_changeset
      ],
      success: from_start_through_validation ++ [
        :insert_changeset, 
        :check_insertion_result
      ],
    }
  end

  def default_start_opts, do: [
    changeset_with: &Steps.changeset_with__default_insert/2,
    insert_with: &Steps.insert_with__default/2,
    format: :phoenix
  ]
  
  def start(opts) do
    opts = Keyword.merge(default_start_opts(), opts)
    Start.start_with_variant(ThisVariant, opts)
  end

  def assert_valid_keys(top_level) do
    required_keys = [:examples_module, :repo] ++ Keyword.keys(default_start_opts())
    optional_keys = []
    
    top_level
    |> Callbacks.validate_top_level_keys(required_keys, optional_keys)
  end

  def assert_valid_workflow_name(workflow_name) do 
    workflows = Map.keys(workflows())
    elaborate_assert(
      workflow_name in workflows,
      "The PhoenixClassic.Insert variant only allows these workflows: #{inspect workflows}",
      left: workflow_name
    )
  end
  
    
  # ------------------- Hook functions -----------------------------------------

  def hook(:start, top_level, []) do 
    assert_valid_keys(top_level)
    top_level
  end

  def hook(:workflow, top_level, [workflow_name]) do
    assert_valid_workflow_name(workflow_name)
    top_level
  end

  # ----------------------------------------------------------------------------

  IO.puts "inserted and friends should take trace arguments"

  defmacro __using__(_) do
    quote do
      use TransformerTestSupport.Predefines
      alias TransformerTestSupport.Variants.PhoenixClassic
      alias __MODULE__, as: ExamplesModule

      def start(opts) do
        PhoenixClassic.Insert.start([{:examples_module, ExamplesModule} | opts])
      end

      defmodule Tester do
        use TransformerTestSupport.Predefines.Tester
        alias T.Run.Steps

        def validation_changeset(example_name) do
          check_workflow(example_name, stop_after: :changeset_from_params)
          |> Keyword.get(:changeset_from_params)
        end

        def inserted(example_name) do
          {:ok, value} = 
            check_workflow(example_name, stop_after: :check_insertion_result)
            |> Keyword.get(:insert_changeset)
          value
        end

        def allow_asynchronous_tests(example_name),
          do: example(example_name) |> Steps.start_sandbox
        
      end
    end
  end
end
