defmodule Ovo do
  @moduledoc """
  Ovo is a small data transformation language hosted in Elixir.
  # Sample syntax
  ```
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
end
