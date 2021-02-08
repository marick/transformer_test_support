defmodule EctoTestDSL.Run.Steps.Util do
  use EctoTestDSL.Drink.Me
  use EctoTestDSL.Drink.AssertionJuice
  use EctoTestDSL.Drink.AndRun
  
  def context(name, message),
    do: "Example `#{inspect name}`: #{message}"

  def identify_example(name) do
    fn message -> context(name, message) end
  end

  # ----------------------------------------------------------------------------
  defmacro from(running, use: keys) do
    varlist = Enum.map(keys, &one_var/1)    
    calls = Enum.map(keys, &(field_access(&1, running)))
    emit(varlist, calls)
  end

  defmacro from_history(running, kws) do
    varlist = Enum.map(kws, &one_var/1)
    calls = Enum.map(kws, &(history_access &1, running))
    emit(varlist, calls)
  end

  defp one_var({var_name, _step_name}), do: Macro.var(var_name, nil)
  defp one_var( var_name),              do: Macro.var(var_name, nil)

  defp field_access(key, running) do
    quote do: mockable(RunningExample).unquote(key)(unquote(running))
  end

  defp history_access({_var_name, step_name}, running),
    do: history_access(step_name, running)

  defp history_access(step_name, running) do
    quote do 
      mockable(RunningExample).step_value!(unquote(running), unquote(step_name))
    end
  end

  defp emit(varlist, calls) do
    quote do: {unquote_splicing(varlist)} = {unquote_splicing(calls)}
  end
end
