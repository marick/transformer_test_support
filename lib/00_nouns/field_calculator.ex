defmodule TransformerTestSupport.Nouns.FieldCalculator do
  use TransformerTestSupport.Drink.Me
  import FlowAssertions.Define.BodyParts
  alias T.Link.ChangesetNotationToAssertion, as: Translate
  
  @moduledoc """
  A description of how a field's value can be calculated in terms of
  other fields (and constants).
  """

  defstruct [:calculation, :args, :from]

  def new(calculation, args, from \\ "unknown"),
    do: %__MODULE__{calculation: calculation, args: args, from: from}

  def merge(kws1, kws2) do
    on_duplicate_key = fn field, val1, val2 ->
      elaborate_assert(val1 == val2, 
        merge_error(field),
        left: val1, right: val2)
      val1
    end
    
    Keyword.merge(kws1, kws2, on_duplicate_key)
  end

  def merge_error(field),
    do: "You gave field `#{inspect field}` two different values"

  def subtract(kws, names) do
    KeywordX.delete(kws, names)
  end

  def assertions(named_calculators, changeset) when is_list(named_calculators) do
    named_calculators
    |> changeset_checks(changeset)
    |> Enum.zip(named_calculators)
    |> Enum.map(&translate_one_check/1)
  end

  defp translate_one_check({check, {_, %__MODULE__{from: from}}}) do
    raw_assertion = Translate.from(check)
    fn changeset ->
      adjust_assertion_error(fn -> 
        raw_assertion.(changeset)
      end,
        expr: from)
    end
  end

  def changeset_checks(named_calculators, changeset) do
    valid_prerequisites = valid_prerequisites(changeset)
    
    for {name, calculator} <- named_calculators do
      case relevant?(calculator, valid_prerequisites) do
        true -> 
          args = translate_args(calculator.args, changeset)
          {:change, [{name, apply(calculator.calculation, args)}]}
        false -> 
          {:no_changes, name}
      end
    end
  end

  def valid_prerequisites(changeset) do
    Map.keys(changeset.changes)
    |> EnumX.difference(Keyword.keys(changeset.errors))
    |> MapSet.new
  end

  def relevant?(calculator, valid_prerequisites) do
    MapSet.subset?(
      calculator.args |> Enum.filter(&is_atom/1) |> MapSet.new,
      valid_prerequisites)
  end

  defp translate_args(args, changeset) do
    for a <- args, do: translate_arg(a, changeset)
  end
    
  defp translate_arg(arg,  changeset) when is_atom(arg), do: changeset.changes[arg]
  defp translate_arg(arg, _changeset),                   do:                   arg

end
