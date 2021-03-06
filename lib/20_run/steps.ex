defmodule EctoTestDSL.Run.Steps do
  use EctoTestDSL.Drink.Me
  use EctoTestDSL.Drink.Assertively
  use EctoTestDSL.Drink.AndRun
  import Run.From
  alias Run.Rnode
  alias Run.ChangesetChecks, as: CC
  alias Run.ChangesetAsCast
  alias FlowAssertions.MapA
  use Magritte

  Module.register_attribute __MODULE__, :step, accumulate: true, persist: true

  ###################### SETUP #####################################

  @step :repo_setup
  def repo_setup(running) do
    from(running, use: [:neighborhood, :eens])
    Neighborhood.augment(neighborhood, eens)
  end

  ###################### PARAMS #####################################

  @step :params
  def params(running) do
    from(running, use: [:neighborhood, :original_params])

    params =
      original_params
      |> Rnode.Substitutable.substitute(neighborhood)

    Trace.say(params, :params)
    params
  end


  ###################### CHANGESET #####################################


  @step :changeset_from_params
  def changeset_from_params(running) do 
    from(running, use: [:formatted_params, :api_module, :schema, :changeset_with])
    changeset_with.(~M{api_module, schema}, formatted_params)
  end

  @step :changeset_for_update
  def changeset_for_update(running, which_struct) do
    from(running,
      use: [:formatted_params, :api_module, :schema, :changeset_for_update_with])
    from_history(running, struct: which_struct)

    changeset_for_update_with.(~M{api_module, schema}, struct, formatted_params)
  end
  # ----------------------------------------------------------------------------

  @step :assert_valid_changeset
  def assert_valid_changeset(running, which_changeset) do 
    validity_assertions(running, which_changeset,
      ChangesetAssertions.from(:valid), "a valid")
  end

  @step :refute_valid_changeset
  def refute_valid_changeset(running, which_changeset) do 
    validity_assertions(running, which_changeset,
      ChangesetAssertions.from(:invalid), "an invalid")
  end

  defp validity_assertions(running, which_changeset, assertion, error_snippet) do
    from(running, use: [:name, :workflow_name])
    from_history(running, changeset: which_changeset)
      
    message =
      "workflow `#{inspect workflow_name}` expects #{error_snippet} changeset"
    adjust_assertion_message(
      fn ->
        assertion.(changeset)
      end,
      fn _ ->
        Reporting.changeset_error_message(name, message, changeset)
      end)

    :uninteresting_result
  end

  # ----------------------------------------------------------------------------

  @step :example_specific_changeset_checks
  def example_specific_changeset_checks(running, which_changeset) do
    from(running, use: [:name, :neighborhood, :validation_changeset_checks])
    from_history(running, changeset: which_changeset)

    validation_changeset_checks
    |> Neighborhood.Expand.changeset_checks(neighborhood)
    |> ChangesetAssertions.from
    |> ChangesetAssertions.run_assertions(changeset, name)

    :uninteresting_result
  end

  # ----------------------------------------------------------------------------
  @step :as_cast_changeset_checks
  def as_cast_changeset_checks(running, which_changeset) do

    from(running, use: [:name, :as_cast, :schema, :validation_changeset_checks])
    from_history(running, [:params, changeset: which_changeset])

    excluded = CC.fields_mentioned(validation_changeset_checks)

    as_cast
    |> AsCast.subtract(excluded)
    |> ChangesetAsCast.assertions(schema, params)
    |> ChangesetAssertions.run_assertions(changeset, name)

    :uninteresting_result
  end

  @step :field_calculation_checks
  def field_calculation_checks(running, which_changeset) do
    from(running, use: [:name, :field_calculators, :validation_changeset_checks])
    from_history(running, changeset: which_changeset)

    excluded = CC.fields_mentioned(validation_changeset_checks)
    
    field_calculators
    |> FieldCalculator.subtract(excluded)
    |> FieldCalculator.assertions(changeset)
    |> ChangesetAssertions.run_assertions(changeset, name)
    
    :uninteresting_result
  end

  ###################### ECTO #####################################

  @step :try_changeset_insertion
  def try_changeset_insertion(running, which_changeset) do
    from(running, use: [:repo])
    from_history(running, changeset: which_changeset)    

    RunningExample.insert_with(running).(repo, changeset)
  end

  @step :try_params_insertion
  def try_params_insertion(running) do
    from(running, use: [:repo, :formatted_params, :insert_with])
    insert_with.(repo, formatted_params)
  end

  @step :primary_key
  def primary_key(running) do
    from(running, use: [:get_primary_key_with, :neighborhood])
    from_history(running, [:params])

    get_primary_key_with.(~M{neighborhood, params})
  end

  @step :struct_for_update
  def struct_for_update(running, which_primary_key) do
    from(running, use: [:struct_for_update_with, :repo, :api_module])
    from_history(running, primary_key: which_primary_key)

    ~M{repo, api_module, primary_key}
    |> Map.put(:set_hint, :struct_for_update_with)
    |> struct_for_update_with.()
  end

  @step :try_changeset_update
  def try_changeset_update(running, which_changeset) do
    from(running, use: [:repo, :update_with])
    from_history(running, changeset: which_changeset)    

    update_with.(repo, changeset)
  end

  ###################### RESULT CHECKING  #####################################

  @step :ok_content
  def ok_content(running, which_step) do
    extract_content(running, :ok_content, which_step)
  end

  @step :error_content
  def error_content(running, which_step) do
    extract_content(running, :error_content, which_step)
  end

  defp extract_content(running, extractor, which_step) do
    from(running, use: [:name])
    from_history(running, value: which_step)

    adjust_assertion_message(
      fn ->
        apply(FlowAssertions.MiscA, extractor, [value])
      end,
      Reporting.identify_example(name))
  end

  # ----------------------------------------------------------------------------
  @step :check_against_given_fields
  def check_against_given_fields(running, which_step) do
    from(running, use: [:name, :result_fields, :neighborhood])
    from_history(running, actual: which_step)

    adjust_assertion_message(fn ->
      expected = Neighborhood.Expand.values(result_fields, with: neighborhood)
      assert_fields(actual, expected)
    end,
      Reporting.identify_example(name))

    :uninteresting_result
  end

  # ----------------------------------------------------------------------------
  @step :check_against_earlier_example
  def check_against_earlier_example(running, which_step) do
    from(running, use: [:name, :result_matches])
    from_history(running, to_be_checked: which_step)
    
    adjust_assertion_message(fn -> 
      check_against_previous_struct(result_matches, to_be_checked, running)
    end,
      Reporting.identify_example(name))
    
    :uninteresting_result
  end

  defp check_against_previous_struct(:unused, _, _), do: :ok
  defp check_against_previous_struct(fields_from, to_be_checked, running) do 
    from(running, use: [:neighborhood, :usually_ignore])
    
    reference_value = Map.get(neighborhood, fields_from.een)
    opts =
      fields_from.opts
      |> expand_exceptions(neighborhood)
      |> expand_ignoring(usually_ignore)

    MapA.assert_same_map(to_be_checked, reference_value, opts)
  end

  defp expand_exceptions(opts, neighborhood) do
    case Keyword.get(opts, :except) do
      nil ->
        opts
      kws ->
        excepts = Neighborhood.Expand.values(kws, with: neighborhood)
        Keyword.replace(opts, :except, excepts)
    end
  end
  
  defp expand_ignoring(opts, usually_ignore) do
    case Keyword.has_key?(opts, :comparing) do
      true ->
       # Note: if they have both `:comparing` and `:ignoring`, fine.
       # `assert_same_map` will do the complaining.
       opts
       
      false -> 
        {local_ignoring, _rest} = Keyword.pop(opts, :ignoring, [])
        Keyword.put(opts, :ignoring, local_ignoring ++ usually_ignore)
    end
  end

  # ----------------------------------------------------------------------------
  @step :as_cast_field_checks
  def as_cast_field_checks(running, which_struct) do
    from(running, use: [:as_cast, :schema, :name, :result_matches, :result_fields])
    from_history(running, [:params, struct: which_struct])

    if result_matches == :unused do
      relevant = fields_to_check(as_cast.field_names, result_fields)
      expected = ChangesetAsCast.cast_results(schema, relevant, params).changes
          
      Trace.say(expected, :expected)
      run_as_cast_assertion(struct, expected, name)
    end
    :uninteresting_result
  end
      
  defp run_as_cast_assertion(struct, expected, name) do 
    adjust_assertion_message(
      fn ->
        assert_fields(struct, expected)
      end,
      fn message ->
        Reporting.schema_error_message(name,
          "#{message} according to `:as_cast`",
          struct)
      end)
  end

  defp fields_to_check(possibilities, result_fields) do
    result_keys = Map.keys(result_fields)
    Enum.reject(possibilities, &Enum.member?(result_keys, &1))
  end

  ###################### DOUBLE CHECKING  #####################################

  @step :existing_ids
  def existing_ids(running) do
    from(running, use: [:existing_ids_with, :repo, :schema])
    existing_ids_with.(~M{repo, schema})
  end

  @step :assert_no_insertion
  def assert_no_insertion(running) do
    from(running, use: [:name, :schema])
    from_history(running, previous: :existing_ids)
    current = existing_ids(running)
    ids_now = length(current)
    ids_then = length(previous)

    message = """
    #{inspect schema} entries were supposed to be unchanged.
    There were #{ids_then}. Now there are #{ids_now}.
    Here are the before and after ids:
    """

    elaborate_assert(length(current) == length(previous),
      Reporting.context(name, message),
      left: previous, right: current)

    Trace.say([before: previous, now: current], :ids)
    
    :uninteresting_result
  end

  @step :assert_id_inserted
  def assert_id_inserted(running, which_step) do
    from(running, use: [:name, :schema])

    from_history(running, previous: :existing_ids, struct:  which_step)
    current = existing_ids(running)
    desired_id = struct.id
    
    adjust_assertion_message(fn ->
      elaborate_refute(Enum.member?(previous, desired_id),
        "Before the insertion, there already was a `#{inspect schema}` with id #{desired_id}",
        left: previous, right: desired_id)
      
      elaborate_assert(Enum.member?(current, desired_id),
        "There is no `#{inspect schema}` with id #{desired_id}",
        left: current, right: desired_id)
    end,
      Reporting.identify_example(name))
      
    :uninteresting_result
  end

  @step :postcheck
  def postcheck(running) do
    from(running, use: [:postcheck, :name])

    if postcheck do 
      adjust_assertion_message(
        fn ->
          postcheck.(running)
        end,
        fn message ->
          Reporting.context(name, "Postcheck assertion failed.\n#{message}")
        end)
    end
    
    :uninteresting_result
  end

  defmacro __using__(_) do
    step_module = __MODULE__
    for step_name <- @step do
      quote do
        def unquote(step_name)(running, rest_args) do
          args = [running | rest_args]
          apply(unquote(step_module), unquote(step_name), args)
        end
      end
    end
  end
end
