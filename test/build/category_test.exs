defmodule Build.CategoryTest do
  use TransformerTestSupport.Case
  alias TransformerTestSupport.SmartGet

  defmodule Repeat do
    use TransformerTestSupport.Variants.Trivial
    
    def create_test_data() do
      start_with_variant(Trivial, module_under_test: Anything)
      |> category(:valid, ok:    [params(a: 1,  b: 2)])
      |> category(:valid, other: [params(a: 11, b: 22)])
    end
  end

  test "categories are attached to examples" do
    assert SmartGet.Example.get(Repeat, :ok).metadata.category_name == :valid
  end

  test "you can repeat a category" do
    assert Repeat.Tester.params(:ok) ==    %{a: 1,  b: 2}
    assert Repeat.Tester.params(:other) == %{a: 11, b: 22}
  end
end  
