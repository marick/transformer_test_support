defmodule Integration.Species do
  alias Integration.Species

  defmodule Schema do
    use Ecto.Schema
    import Ecto.Changeset

    schema "bogus" do 
      field :name, :string
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:name])
    end
  end

  defmodule Examples do
    use EctoTestDSL.Variants.PhoenixGranular.Insert
    use Integration.Support

   def create_test_data do
      start(
        api_module: Species.Schema,
        repo: "there is no repo",
        insert_with: &tunable_insert/2
      )

      workflow(:success,
        bovine: [
          params(name: "bovine")
        ])
    end
  end
end
