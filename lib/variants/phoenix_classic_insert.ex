defmodule EctoTestDSL.Variants.PhoenixClassic.Insert do
  use EctoTestDSL.Drink.Me
  alias T.Variants.PhoenixClassic.Insert, as: ThisVariant
  alias T.Parse.Start
  alias T.Parse.Callbacks
  import FlowAssertions.Define.BodyParts
  alias T.Variants.Common.DefaultFunctions

  # ------------------- Workflows -----------------------------------------

  use T.Run.Steps

  def workflows() do
    common = [
      :repo_setup,
      :params,
      :try_params_insertion,
    ]

    %{
      validation_error: common ++ [
      [:error_content,                     uses: [:try_params_insertion]],
      [:refute_valid_changeset,            uses: [:error_content]],
      [:example_specific_changeset_checks, uses: [:error_content]],
      [:as_cast_checks,                    uses: [:error_content]],
    ]
    } 
  end

  # ------------------- Startup -----------------------------------------

  def start(opts) do
    opts = Keyword.merge(default_start_opts(), opts)
    Start.start_with_variant(ThisVariant, opts)
  end

  defp default_start_opts, do: [
    insert_with: &DefaultFunctions.plain_insert/2,
    format: :phoenix,
    usually_ignore: [],
  ]

  
  # ------------------- Hook functions -----------------------------------------

  def hook(:start, top_level, []) do 
    assert_valid_keys(top_level)
    top_level
  end

  def hook(:workflow, top_level, [workflow_name]) do
    assert_valid_workflow_name(workflow_name)
    top_level
  end

  defp assert_valid_keys(top_level) do
    required_keys = [:examples_module, :repo] ++ Keyword.keys(default_start_opts())
    optional_keys = []
    
    top_level
    |> Callbacks.validate_top_level_keys(required_keys, optional_keys)
  end

  defp assert_valid_workflow_name(workflow_name) do 
    workflows = Map.keys(workflows())
    elaborate_assert(
      workflow_name in workflows,
      "The PhoenixClassic.Insert variant only allows these workflows: #{inspect workflows}",
      left: workflow_name
    )
  end

  # ----------------------------------------------------------------------------

  defmacro __using__(_) do
    quote do
      use EctoTestDSL.Predefines
      alias EctoTestDSL.Variants.PhoenixClassic
      alias __MODULE__, as: ExamplesModule

      def start(opts) do
        PhoenixClassic.Insert.start([{:examples_module, ExamplesModule} | opts])
      end

      defmodule Tester do
        use EctoTestDSL.Predefines.Tester
        alias T.Run.Steps
      end
    end
  end
end