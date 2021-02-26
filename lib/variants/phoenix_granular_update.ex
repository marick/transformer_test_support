defmodule EctoTestDSL.Variants.PhoenixGranular.Update do
  use EctoTestDSL.Drink.Me
  alias T.Run.Steps
  alias T.Variants.PhoenixGranular.Update, as: ThisVariant
  alias T.Parse.Start
  alias T.Parse.Callbacks
  import FlowAssertions.Define.BodyParts
  import ExUnit.Assertions

  # ------------------- Workflows -----------------------------------------

  use T.Run.Steps
  
  def workflows() do 
    from_start_through_changeset = [
      :repo_setup,
      :params,
      :primary_key,
      [:struct_for_update, uses: [:primary_key]],
      [:changeset_for_update, uses: [:struct_for_update]]
    ]

    from_start_through_validation = from_start_through_changeset ++ [
      [:assert_valid_changeset,            uses: [:changeset_for_update]],
      [:example_specific_changeset_checks, uses: [:changeset_for_update]],
      [:as_cast_checks,                    uses: [:changeset_for_update]],
      [:field_calculation_checks,          uses: [:changeset_for_update]],
    ]
    
    %{
      validation_success: from_start_through_validation,

      validation_error: from_start_through_changeset ++ [
        [:refute_valid_changeset,            uses: [:changeset_for_update]],
        [:example_specific_changeset_checks, uses: [:changeset_for_update]],
        [:as_cast_checks,                    uses: [:changeset_for_update]],
      ],
      
      constraint_error: from_start_through_validation ++ [
        [:try_changeset_update,              uses: [:changeset_for_update]],
        [:error_content,                     uses: [:try_changeset_update]],
        [:refute_valid_changeset,            uses: [:error_content]],
        [:example_specific_changeset_checks, uses: [:error_content]],
      ],
      success: from_start_through_validation ++ [
        [:try_changeset_update,      uses: [:changeset_for_update]],
        [:ok_content,                uses: [:try_changeset_update]],
        [:field_checks,              uses: [:ok_content]],
      ],
    }
  end

  # ------------------- Startup -----------------------------------------

  def start(opts) do
    opts = Keyword.merge(default_start_opts(), opts)
    Start.start_with_variant(ThisVariant, opts)
  end

  defp default_start_opts, do: [
    get_for_update_with: &default_get_for_update_with/3,
    changeset_for_update_with: &default_changeset_for_update_with/3,
    update_with: &default_update_with/2,
    get_primary_key_with: &default_get_primary_key_with/1,
    struct_for_update_with: &default_struct_for_update_with/1,
    format: :phoenix,
    usually_ignore: [],
  ]

  def default_get_for_update_with(repo, queryable, example),
    do: repo.get!(queryable, example.id)
  
  def default_changeset_for_update_with(module_under_test, struct, params),
    do: module_under_test.changeset(struct, params)

  def default_update_with(repo, changeset),
    do: repo.update(changeset)

  def default_get_primary_key_with(%{params: params}) do
    message = """
      By default, the primary key of the entity to be updated is taken
      to be the value of key "id" in the form parameters. There is no
      such key. 

      You probably need to set `:get_primary_key_with` in your `start` function.
      To learn more, see the documentation or look at your variant's
      definition of `:get_primary_key_with` in `default_start_opts`.
      """

    primary_key = Map.get(params, "id")
    assert primary_key, message
    primary_key
  end

  def default_struct_for_update_with(
    %{repo: repo, module_under_test: module_under_test, primary_key: primary_key}    
  ) do
    
    message = """
     Could not fetch a #{inspect module_under_test} with primary key `#{primary_key}`.
     You may need to set `:struct_for_update_with` in your `start` function.
     To learn more, see the documentation or look at your variant's
     definition of `:struct_for_update_with` in `default_start_opts`.
     """

    result = repo.get(module_under_test, primary_key)
    assert result, message
    result
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
      "The PhoenixGranular.Update variant only allows these workflows: #{inspect workflows}",
      left: workflow_name
    )
  end

  # ----------------------------------------------------------------------------

  defmacro __using__(_) do
    quote do
      use EctoTestDSL.Predefines
      alias EctoTestDSL.Variants.PhoenixGranular
      alias __MODULE__, as: ExamplesModule

      def start(opts) do
        PhoenixGranular.Update.start([{:examples_module, ExamplesModule} | opts])
      end

      defmodule Tester do
        use EctoTestDSL.Predefines.Tester
        alias T.Run.Steps

        def validation_changeset(example_name) do
          check_workflow(example_name, stop_after: :changeset_for_update)
          |> Keyword.get(:changeset_for_update)
        end

        def updated(example_name) do
          {:ok, value} = 
            check_workflow(example_name, stop_after: :ok_content)
            |> Keyword.get(:try_changeset_update)
          value
        end

        def allow_asynchronous_tests(example_name),
          do: example(example_name) |> Steps.start_sandbox
      end
    end
  end
end
