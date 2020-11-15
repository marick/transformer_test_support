defmodule SmartGet.ChangesetChecks.UtilTest do
  use TransformerTestSupport.Case
  alias TransformerTestSupport.SmartGet.ChangesetChecks.Util

  test "unique_fields" do
    expect = fn changeset_checks, expected ->
      actual = Util.unique_fields(changeset_checks)
      assert actual == expected
    end
    
    # Handling of lone symbols
    [change: :a            ] |> expect.([:a])
    [change: :a, change: :b] |> expect.([:a, :b])
    [change: :a, error:  :a] |> expect.([:a])
    
    
    # Is not fooled by single-element (global) checks
    [:valid, change: :a    ] |> expect.([:a])
  end
  
  
  test "removing fields described by user" do
    expect = fn {fields, changeset_checks}, expected ->
      user_mentioned = Util.unique_fields(changeset_checks)
      actual = Util.remove_fields_named_by_user(fields, user_mentioned)
      assert actual == expected
    end
    
    # Base cases.
    {  [],   [              ] } |> expect.([  ])
    {  [],   [some_check: :b] } |> expect.([  ])
    {  [:a], [              ] } |> expect.([:a])
    
    # singleton arguments
    {  [:default], [some_check: :other]  } |> expect.([:default])
    {  [:default], [some_check: :default]  } |> expect.([])
    
    # List arguments
    {  [:default], [some_check: [:other          ]]  } |> expect.([:default])
    {  [:default], [some_check: [:other, :default]]  } |> expect.([])
    
    # Keyword arguments
    {  [:default], [changes: [other: 5            ]]  } |> expect.([:default])
    {  [:default], [changes: [other: 5, default: 5]]  } |> expect.([])
    
    
    # Keyword arguments
    {  [:default], [changes: %{other: 5            }]  } |> expect.([:default])
    {  [:default], [changes: %{other: 5, default: 5}]  } |> expect.([])
  end

  
  defp with_transformations(xfer), do: %{metadata: %{field_transformations: xfer}}

  test "transformations" do
    expect = fn kws, expected ->
      actual = with_transformations(kws) |> Util.separate_types_of_transformed_fields
      assert actual == expected
    end
    
    complete = [
      as_cast: [:a, :b],
      field1: 1,
      as_cast: [:c],
      field2: 2
    ]

    [] |> expect.([[], []])
    complete |> expect.([[:a, :b, :c], [field1: 1, field2: 2]])
  end
end
