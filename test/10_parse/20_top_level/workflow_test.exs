defmodule Parse.TopLevel.WorkflowTest do
  use TransformerTestSupport.Case
  alias TransformerTestSupport.SmartGet
  use T.Parse.All

  defmodule Examples do
    use Template.EctoClassic.Insert
    
    def create_test_data() do
      started()
      |> workflow(:success, ok:    [params(a: 1,  b: 2)])
         # Note repeated workflow name
      |> workflow(:success, other: [params_like(:ok, except: [b: 22])])
    end
  end

  test "workflows are attached to examples" do
    SmartGet.Example.get(Examples, :ok)
    |> SmartGet.Example.workflow_name
    |> assert_equal(:success)
  end
  
  test "the parts a workflow adds" do
    ok = Examples.Tester.example(:ok)
    other = Examples.Tester.example(:other)
    
    assert ok.params == %{a: 1, b: 2}
    assert other.params == %{a: 1, b: 22}

    assert ok.metadata.workflow_name == :success
    assert ok.metadata.name == :ok
    assert other.metadata.workflow_name == :success
    assert other.metadata.name == :other
  end

  test "workflow examples accumulate" do
    assert Examples.Tester.params(:ok) ==    %{"a" => "1",  "b" => "2"}
    assert Examples.Tester.params(:other) == %{"a" => "1", "b" => "22"}
  end
end  