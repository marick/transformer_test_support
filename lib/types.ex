defmodule TransformerTestSupport.Types do
  alias TransformerTestSupport.Types.EEN

  @moduledoc """
  These are constructors for everything I'm boldly treating as an
  abstract data type. All the manipulation functions are in submodules.
  That's probably a bad idea, but it hides the difference between constructors
  that are macros and ones that are true functions.

  Though having any macros at all (in order to capture __MODULE__) is pretty
  dubious.
  """
  
  defmacro een_t([{example_name, module}]) do 
    quote do
      EEN.new(unquote(example_name), unquote(module))
    end
  end

  defmacro een_t(example_name) when is_atom(example_name) do
    quote do
      EEN.new(unquote(example_name), __MODULE__)
    end
  end

  defmacro een_t(example_name, module) do 
    quote do
      EEN.new([{unquote(example_name), unquote(module)}])
    end
  end
end
