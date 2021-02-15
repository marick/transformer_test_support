defmodule EctoTestDSL.Run.Steps do
  use EctoTestDSL.Drink.Me
  use EctoTestDSL.Drink.AssertionJuice
  use EctoTestDSL.Drink.AndRun
  alias Run.Rnode
  import T.Run.Steps.Util
  alias T.Run.ChangesetChecks, as: CC
  alias FlowAssertions.MapA
  use Magritte

  ###################### SETUP #####################################

  # I can't offhand think of any case where one `repo_setup` might need to
  # use the results of another that isn't part of the same dependency tree.
  # That might change if I add a workflowy-wide or test-data-wide setup.

  # If that is done, the history must be passed in by `Run.example`

  def start_sandbox(example) do
    alias Ecto.Adapters.SQL.Sandbox

    repo = Example.repo(example)
    if repo do  # Convenient for testing, where we might be faking the repo functions.
      Sandbox.checkout(repo) # it's OK if it's already checked out.
    end
  end

  def repo_setup(running) do
    from(running, use: [:neighborhood, :eens])
    Enum.reduce(eens, neighborhood, &Neighborhood.Create.from_an_een/2)
  end

  ###################### PARAMS #####################################

  def params(running) do
    from(running, use: [:neighborhood, :original_params])

    params =
      original_params
      |> Rnode.RunTimeSubstitutable.substitute(neighborhood)
      |> RunningExample.formatted_params_for_history(running, ...)

    Trace.say(params, :params)
    params
  end

  IO.puts "not sure if this serves any purpose"
  def params_from_selecting(running) do
    from(running, use: [:neighborhood, :params_from_selecting])
    Map.get(neighborhood, params_from_selecting)
  end


  ###################### CHANGESET #####################################


  def changeset_from_params(running) do 
    from(running, use: [:expanded_params, :module_under_test, :changeset_with])
    changeset_with.(module_under_test, expanded_params)
  end

  def changeset_for_update(running, which_struct) do
    from(running,
      use: [:expanded_params, :module_under_test, :changeset_for_update_with])
    from_history(running, struct: which_struct)

    changeset_for_update_with.(module_under_test, struct, expanded_params)
  end
  # ----------------------------------------------------------------------------

  def assert_valid_changeset(running, which_changeset) do 
    validity_assertions(running, which_changeset,
      ChangesetAssertions.from(:valid), "a valid")
  end
    
  def refute_valid_changeset(running, which_changeset) do 
    validity_assertions(running, which_changeset,
      ChangesetAssertions.from(:invalid), "an invalid")
  end
    
  defp validity_assertions(running, which_changeset, assertion, error_snippet) do
    from(running, use: [:name, :workflow_name])
    from_history(running, changeset: which_changeset)
      
    message =
      "Example `#{inspect name}`: workflow `#{inspect workflow_name}` expects #{error_snippet} changeset"
    adjust_assertion_message(
      fn ->
        assertion.(changeset)
      end,
      fn _ -> message end)

    :uninteresting_result
  end

  # ----------------------------------------------------------------------------

  def example_specific_changeset_checks(running, which_changeset) do
    from(running, use: [:name])
    from_history(running, changeset: which_changeset)
    
    user_checks(running)
    |> ChangesetAssertions.from
    |> run_assertions(changeset, name)

    :uninteresting_result
  end

  # ----------------------------------------------------------------------------
  def as_cast_checks(running, which_changeset) do
    from(running, use: [:name, :as_cast])
    from_history(running, [:params, changeset: which_changeset])

    as_cast
    |> AsCast.subtract(excluded_fields(running))
    |> AsCast.assertions(params)
    |> run_assertions(changeset, name)

    :uninteresting_result
  end

  def field_calculation_checks(running, which_changeset) do
    from(running, use: [:name, :field_calculators])
    from_history(running, changeset: which_changeset)
    
    field_calculators
    |> FieldCalculator.subtract(excluded_fields(running))
    |> FieldCalculator.assertions(changeset)
    |> run_assertions(changeset, name)
    
    :uninteresting_result
  end

  # ----------------------------------------------------------------------------
  defp user_checks(running) do
    from(running, use: [:neighborhood, :validation_changeset_checks])

    validation_changeset_checks
    |> Neighborhood.Expand.changeset_checks(neighborhood)
  end

  defp excluded_fields(running) do
    user_checks = user_checks(running)
    # as_cast checks
    CC.unique_fields(user_checks)
  end    

  defp run_assertions(assertions, changeset, name) do
    adjust_assertion_message(
      fn ->
        for a <- assertions, do: a.(changeset)
      end,
      fn message ->
        error_message(name, message, changeset)
      end)
  end
  
  def error_message(name, message, changeset) do
    """
    #{context(name, message)}
    Changeset: #{inspect changeset}
    """
  end

  ###################### ECTO #####################################

  def try_changeset_insertion(running, which_changeset) do
    from(running, use: [:repo])
    from_history(running, changeset: which_changeset)    

    RunningExample.insert_with(running).(repo, changeset)
  end

  IO.puts "struct_for_update"
  def struct_for_update(_running) do
  end

  def try_changeset_update(running, which_changeset) do
    from(running, use: [:repo, :update_with])
    from_history(running, changeset: which_changeset)    

    update_with.(repo, changeset)
  end

  

  ###################### RESULT CHECKING  #####################################

  def ok_content(running, which_step) do
    extract_content(running, :ok_content, which_step)
  end

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
      identify_example(name))
  end

  def field_checks(running, which_step) do
    from(running, use: [:neighborhood, :name, :field_checks, :fields_like])
    from_history(running, to_be_checked: which_step)

    adjust_assertion_message(fn -> 
      do_field_checks(field_checks, to_be_checked, neighborhood)
      do_fields_like(fields_like, to_be_checked, neighborhood)
    end,
      identify_example(name))

    :uninteresting_result
  end

  defp do_field_checks(field_checks, to_be_checked, neighborhood) do
    unless Enum.empty?(field_checks) do 
      expected =
        Neighborhood.Expand.keyword_values(field_checks, with: neighborhood)
      assert_fields(to_be_checked, expected)
    end
  end

  defp do_fields_like(:nothing, _, _), do: :ok
  defp do_fields_like(fields_like, to_be_checked, neighborhood) do
    reference_value = Map.get(neighborhood, fields_like.een)
    opts = expand_expected(fields_like.opts, neighborhood)

    MapA.assert_same_map(to_be_checked, reference_value, opts)
  end

  defp expand_expected(opts, neighborhood) do
    case Keyword.get(opts, :except) do
      nil ->
        opts
      kws ->
        excepts = Neighborhood.Expand.keyword_values(kws, with: neighborhood)
        Keyword.replace(opts, :except, excepts)
    end
  end

  
end
