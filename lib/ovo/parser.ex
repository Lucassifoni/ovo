defmodule Ovo.Parser do
  alias Ovo.Ast
  alias Ovo.Combinators, as: C

  def err(tokens), do: {:error, nil, tokens}
  def ok(result, rest), do: {:ok, result, rest}

  def parse_number([{:number, val} | rest] = tokens) do
    if String.contains?(val, ".") do
      case Float.parse(val) do
        {n, ""} -> ok(Ast.float(n), rest)
        _ -> err(tokens)
      end
    else
      case Integer.parse(val, 10) do
        {n, ""} -> ok(Ast.integer(n), rest)
        _ -> err(tokens)
      end
    end
  end

  def parse_number(a), do: err(a)

  def parse_string([{:string, val} | rest]), do: ok(Ast.string(val), rest)
  def parse_string(a), do: err(a)

  def parse_symbol([{:symbol, val} | rest]), do: ok(Ast.symbol(val), rest)
  def parse_symbol(a), do: err(a)

  def parse_comma(input), do: C.match(:comma).(input)
  def parse_close_paren(input), do: C.match(:close_paren).(input)
  def parse_close_bracket(input), do: C.match(:close_bracket).(input)

  @doc """
  Parses a list of values
      iex> tokens = Ovo.Tokenizer.tokenize("[a, b, c, 5]")
      iex> {:ok, _, []} = Ovo.Parser.parse_list(tokens)
  """
  def parse_list([{:open_bracket, nil} | rest]),
    do:
      C.then(
        C.then(C.repeat(C.then(&parse_value/1, &parse_comma/1)), &parse_value/1),
        &parse_close_bracket/1
      ).(rest)

  @doc """
  Parses a primitive value.

      iex> Ovo.Parser.parse_value([{:number, "5"}])
      {:ok, %Ovo.Ast{kind: :integer, nodes: [], value: 5}, []}
      iex> Ovo.Parser.parse_value([{:string, "foo"}])
      {:ok, %Ovo.Ast{kind: :string, nodes: [], value: "foo"}, []}
      iex> Ovo.Parser.parse_value([{:arrow, nil}])
      {:error, nil, [{:arrow, nil}]}
  """
  def parse_value(tokens), do: C.any([&parse_number/1, &parse_string/1, &parse_symbol/1]).(tokens)

  def parse_parenthesized_expression([{:open_paren, nil} | rest]),
    do: C.then(&parse_expression/1, &parse_close_paren/1).(rest)

  def parse_expression(tokens) do
    C.any([&parse_value/1]).(tokens)
  end
end
