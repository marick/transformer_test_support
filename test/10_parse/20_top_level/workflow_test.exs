defmodule Parse.TopLevel.WorkflowTest do
  use EctoTestDSL.Case
  alias T.Parse.TopLevel
  use T.Parse.Exports

  defmodule Examples do
    use Template.PhoenixGranular.Insert
    
    def create_test_data() do
      started()
      workflow(:success, ok:    [params(a: 1,  b: 2)])
      # Note repeated workflow name
      workflow(:success, other: [params_like(:ok, except: [b: 22])])
    end
  end

  test "workflows are attached to examples" do
    TestData.example(Examples, :ok)
    |> Example.workflow_name
    |> assert_equal(:success)
  end
  
  test "the parts a workflow adds" do
    ok = Examples.Tester.example(:ok)
    other = Examples.Tester.example(:other)

    assert ok.metadata.workflow_name == :success
    assert ok.metadata.name == :ok
    assert other.metadata.workflow_name == :success
    assert other.metadata.name == :other
  end

  test "workflow examples accumulate" do
    assert Examples.Tester.params(:ok) ==    %{"a" => "1",  "b" => "2"}
    assert Examples.Tester.params(:other) == %{"a" => "1", "b" => "22"}
  end

  # ----------------------------------------------------------------------------
  test "example may *not* be in a map" do
    assertion_fails(
      "Examples must be given in a keyword list",
      fn -> 
        TopLevel.workflow(%{}, :workflow_name, %{example: []})
      end)
  end

  @tag :skip
  test "duplicate names are rejected"

  describe "flattening raw examples" do 
    test "there's a keyword" do
      input = [__flatten: [a: 1, b: 2], c: 3, __flatten: [d: 4]]
      expected = [a: 1, b: 2, c: 3, d: 4]
      assert TopLevel.testable_flatten(input) == expected
    end
    
    test "flattening preserves order for intermediate processing" do
      input = [__flatten: [a: 1, b: 2], c: 3, __flatten: [d: 4]]
      assert TopLevel.testable_flatten(input) == [a: 1, b: 2, c: 3, d: 4]
    end
  end
end  
