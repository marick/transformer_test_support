defmodule TransformerTestSupport.Drink.Me do
  defmacro __using__(_) do
    quote do
      alias TransformerTestSupport, as: T
      import T.Nouns.EEN.Macros
      alias T.Nouns.{EEN,FieldRef,FieldCalculator,AsCast,TestData}
      alias T.{Parse,Run,Neighborhood}
      alias T.SmartGet
      alias T.Messages
      alias T.Trace

      alias T.{ChangesetX, EnumX, KeywordX, MapX}
    end
  end
end
