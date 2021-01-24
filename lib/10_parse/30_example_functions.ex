defmodule TransformerTestSupport.Parse.ExampleFunctions do
  use TransformerTestSupport.Drink.Me
  use TransformerTestSupport.Drink.AssertionJuice
  alias Parse.ParamsLike

  # ----------------------------------------------------------------------------
  def params(opts \\ []),
    do: {:params, Enum.into(opts, %{})}
  
  def params_like(example_name, opts),
    do: {:params, ParamsLike.new(example_name, opts)}
  def params_like(example_name), 
    do: params_like(example_name, except: [])


  # ----------------------------------------------------------------------------
  # Nothing is 
  
  def previously(opts) do
    {:setup_instructions, opts}
  end

  def changeset(opts), do: {:validation_changeset_checks, opts}
  def constraint_changeset(opts), do: {:constraint_changeset_checks, opts}
  def fields(opts), do: {:fields, opts}

  # ----------------------------------------------------------------------------

  # This is expanded during normalization.
  def insert_twice(example_name),
    do: {:__flatten, [previously(insert: example_name), params_like(example_name)]}

end
