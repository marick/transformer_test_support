defmodule EctoTestDSL.Pnode.FieldsLikeNodeTest do
  use EctoTestDSL.Case
  use T.Drink.AndParse
  use T.Parse.Exports

  describe "ensuring eens" do
    setup do
      run = fn een_or_name, default_module, opts ->
        Pnode.FieldsLike.parse(een_or_name, opts)
        |> Pnode.EENable.ensure_eens(default_module)
      end

      [run: run]
    end

    test "een and id_of", ~M{run} do
      given_een = een(example: Creator)
      actual = run.(een(example: Creator), "unused_default_module",
        except: [species_id: id_of(species: Second)])

      assert Pnode.EENable.eens(actual) == [given_een, een(species: Second)]
      assert actual.with_ensured_eens == %{reference_een: given_een,
                                           opts: actual.parsed.opts}
    end

    test "een alone", ~M{run} do
      given_een = een(example: Creator)
      actual = run.(given_een, "unused_default_module", [])

      assert Pnode.EENable.eens(actual) == [given_een]
      assert actual.with_ensured_eens == %{reference_een: given_een,
                                           opts: actual.parsed.opts}
    end
    
    test "a name rather than an een alone", ~M{run} do
      opts = [except: [species_id: id_of(species: Second)]]
      actual = run.(:example, SomeModule, opts)

      assert Pnode.EENable.eens(actual) == [een(example: SomeModule),
                                           een(species: Second)]
      assert actual.with_ensured_eens == %{reference_een: een(example: SomeModule),
                                           opts: opts}
    end
  end

  test "export" do
    input = %Pnode.FieldsLike{with_ensured_eens: %{reference_een: "...some een...",
                                                  opts: "...some opts..."}}

    expected = %Rnode.FieldsLike{een: "...some een...", opts: "...some opts..."}

    assert Pnode.Exportable.export(input) == expected
  end
end  
