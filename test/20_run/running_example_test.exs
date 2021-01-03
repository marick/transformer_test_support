defmodule TransformerTestSupport.Run.RunningExampleTest do
  use TransformerTestSupport.Drink.Me
  use TransformerTestSupport.Drink.AndRun
  
  alias T.Variants.EctoClassic
  alias Ecto.Changeset

  defmodule Schema do 
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:name])
      |> validate_required([:name])
    end
  end

  defmodule Examples do
    use EctoClassic.Insert

    def fake_insert(changeset),
      do: {:ok, "created `#{changeset.changes.name}`"}

    def create_test_data do 
      start(
        module_under_test: Schema,
        repo: :unused
      ) |>
      
      replace_steps(insert_changeset: step(&fake_insert/1, :make_changeset)) |>
      
      workflow(                                         :success,
        young: [params(name: "young")],
        dependent: [params(name: "dependent"), previously(insert: :young)],
        two_level: [params(name: "dependent"), previously(insert: :dependent)]
      )
    end
  end

  defmodule Tests do
    use TransformerTestSupport.Case

    test "stopping early after a step" do
      assert [
        make_changeset: made, params: %{"name" => "young"},
          previously: %{}, previously: %{}, example: _] = 
        Examples.Tester.example(:young) |> RunningExample.run(stop_after: :make_changeset)
      
      made
      |> assert_shape(%Changeset{})
      |> assert_change(name: "young")
    end

    @presupplied "presupplied, not created"

    test "A starting previously-state can be passed in" do
      expect = fn example_name, expected ->
        actual =  
          Examples.Tester.example(example_name)
          |> RunningExample.run(previously:
                %{een(young: Examples) => "presupplied, not created"})
        assert Keyword.get(actual, :previously) == expected
      end

      :dependent |> expect.(%{een(young: Examples) => @presupplied})
      # There is a recursive call
      :two_level |> expect.(%{
            een(young: Examples) => @presupplied,
            een(dependent: Examples) => "created `dependent`"})
    end
  end
end

  