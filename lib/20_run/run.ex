defmodule TransformerTestSupport.Run do
  use TransformerTestSupport.Drink.Me
  use T.Drink.AndRun
  use T.Drink.AssertionJuice

  def example(example, opts \\ []) do
    running = RunningExample.from(example,
      script: workflow_script(example, opts),
      history: History.new(example, opts)
    )

    Trace.apply(&run_steps/1, [running])
  end

  def workflow_script(example, opts) do
    stop = Keyword.get(opts, :stop_after, :"this should not ever be a step name")

    Example.workflow_steps(example)
    |> EnumX.take_until(&(&1 == stop))
  end
  
  defp run_steps(running_start) do
    running_start.script
    |> Enum.reduce(running_start, &run_step/2)
    |> Map.get(:history)
  end

  defp run_step([step_name | opts], running) do
    case opts do
      [uses: rest_args] -> 
        module = RunningExample.variant(running)
        value = apply_or_flunk(module, step_name, [running, rest_args])
        Map.update!(running, :history, &(History.add(&1, step_name, value)))
      _ ->
        flunk("`#{inspect [step_name, opts]}` has bad options. `uses` is required.")
    end
  end

  defp run_step(step_name, running) do
    run_step([step_name, uses: []], running)
  end

  defp apply_or_flunk(module, step_name, args) do 
    unless function_exported?(module, step_name, length(args)) do
      missing = "`#{to_string step_name}/#{inspect length(args)}`"
      flunk """
            Variant is missing step #{missing}".
            Did you leave it out of the list of steps (typically in `defsteps`)?
            """
    end
    Trace.apply(module, step_name, args)
  end
end
