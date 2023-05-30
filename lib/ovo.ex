defmodule Ovo do
  @moduledoc """
  Ovo is a small data transformation language hosted in Elixir.

  ### Sample syntax

  ```elixir
  bar = 6
  age = add(access(data, `age`), bar)

  say_hi = \\name, age ->
    join([name, `has the age`, to_string(age)], ``)
  end

  say_hi(access(data, `name`), age)

  fibs = \\a ->
      if greater_or_equals(a, 2) then
          add(fibs(subtract(a, 1)), fibs(subtract(a, 2)))
      else
          1
      end
  end

  fibs(10)
  ```
  """

  @spec tokenize(String.t()) :: [Ovo.Token.t()]
  def tokenize(input), do: Ovo.Tokenizer.tokenize(input)

  def parse(tokens), do: Ovo.Parser.parse(tokens)

  def run_as_elixir(input, bindings \\ []) do
    tokens = Ovo.Tokenizer.tokenize(input)
    {:ok, ast, _} = Ovo.Parser.parse(tokens)
    code = Ovo.ElixirPrinter.print(ast)
    Code.eval_string(code, bindings)
  end

  def demo() do
    {res, _bindings} =
      run_as_elixir(
        """
          if (foo) then
            ([5])
          else
            ([4, [5, 4, []], [[[]]], 6])
          end
        """,
        foo: false
      )

    res
  end
end
