defmodule TransformerTestSupport.Impl.SmartGet.ChangesetChecks.Util do
    
  @moduledoc """
  """

  def unique_fields(changeset_checks) do
    changeset_checks
    |> Enum.filter(&is_tuple/1)
    |> Keyword.values
    |> Enum.flat_map(&from_check_args/1)
    |> Enum.uniq
  end

  def from_check_args(field) when is_atom(field), do: [field]
  def from_check_args(list) when is_list(list), do: Enum.map(list, &field/1)
  def from_check_args(map)  when is_map(map), do: Enum.map(map,  &field/1)

  def field({field, _value}), do: field
  def field(field), do: field
    

  def remove_fields_named_by_user(default_fields, reject_fields) do
    Enum.reject(default_fields, &Enum.member?(reject_fields, &1))
  end

  # ----------------------------------------------------------------------------

  def as_cast_fields(example) do
    example.metadata.field_transformations
    |> Keyword.get_values(:as_cast)
    |> Enum.concat
  end
  
end
