defmodule TransformerTestSupport.Run.RunningExample do
  use TransformerTestSupport.Drink.Me
  use TransformerTestSupport.Drink.AndRun
  alias T.SmartGet.Example

  @enforce_keys [:example, :history]
  defstruct [:example, :history,
             script: :none_just_testing,
             tracer: :none]

  def run(example, opts \\ []) do
    running = %RunningExample{
      example: example,
      script: Example.workflow_script(example, opts),
      history: History.new(example, opts)
    }

    Trace.apply(&run_steps/1, running) |> Trace.in_out
  end

  defp run_steps(running) do
    case running.script do
      [] ->
        running.history
      [{step_name, function} | rest] ->
        value = 
          Trace.apply(function, running) |> Trace.as_nested_value(step_name)

        running
        |> Map.update!(:history, &(History.add(&1, step_name, value)))
        |> Map.put(:script, rest)
        |> run_steps
    end
  end


  # ----------------------------------------------------------------------------

  def step_value!(running, step_name),
    do: History.step_value!(running.history, step_name)
end
