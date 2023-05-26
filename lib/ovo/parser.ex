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

  def parse_comma(tokens), do: C.match(:comma).(tokens)
  def parse_close_paren(tokens), do: C.match(:close_paren).(tokens)
  def parse_close_bracket(tokens), do: C.match(:close_bracket).(tokens)

  @doc """
  Parses a list of values
      iex> tokens = Ovo.Tokenizer.tokenize("[a, b, c, 5]")
      iex> {:ok, _, []} = Ovo.Parser.parse_list(tokens)
  """
  def parse_multiple_element_list(tokens),
    do:
      C.then(
        C.match(:open_bracket),
        C.then(
          C.then(C.repeat(C.then(&parse_expression/1, &parse_comma/1)), &parse_value/1),
          &parse_close_bracket/1
        )
      ).(tokens)

  def parse_empty_list(tokens),
    do: C.then(C.match(:open_bracket), C.match(:close_bracket)).(tokens)

  def parse_single_element_list(tokens),
    do: C.all([C.match(:open_bracket), &parse_expression/1, C.match(:close_bracket)]).(tokens)

  def parse_list(tokens),
    do:
      C.any([&parse_multiple_element_list/1, &parse_empty_list/1, &parse_single_element_list/1]).(
        tokens
      )

  @doc """
  Parses a primitive value.

      iex> Ovo.Parser.parse_value([{:number, "5"}])
      {:ok, %Ovo.Ast{kind: :integer, nodes: [], value: 5}, []}
      iex> Ovo.Parser.parse_value([{:string, "foo"}])
      {:ok, %Ovo.Ast{kind: :string, nodes: [], value: "foo"}, []}
      iex> Ovo.Parser.parse_value([{:arrow, nil}])
      {:error, nil, [{:arrow, nil}]}
  """
  def parse_value(tokens),
    do: C.any([&parse_number/1, &parse_string/1, &parse_symbol/1, &parse_list/1]).(tokens)

  def parse_parenthesized_expression(tokens),
    do: C.all([C.match(:open_paren), &parse_expression/1, &parse_close_paren/1]).(tokens)

  def parse_if_head(tokens),
    do: C.all([C.match(:if), &parse_expression/1, C.match(:then)]).(tokens)

  def parse_else(tokens), do: C.match(:else).(tokens)
  def parse_end(tokens), do: C.match(:end).(tokens)

  def parse_if(tokens),
    do:
      C.all([
        &parse_if_head/1,
        C.repeat(&parse_expression/1),
        &parse_else/1,
        C.repeat(&parse_expression/1),
        &parse_end/1
      ]).(tokens)

  @doc """
  Parses an expression.
    iex> alias Ovo.Tokenizer, as: Tok
    iex> tokens = Tok.tokenize("if foo then 5 else 6 end")
    iex> {:ok, _, []} = Ovo.Parser.parse_expression(tokens)
    iex> tokens2 = Tok.tokenize("if (foo) then ([5]) else ([4, [5, 4, []], [[[]]], 6]) (baz) end")
    iex> {:ok, _, []} = Ovo.Parser.parse_expression(tokens2)
  """
  def parse_expression(tokens) do
    C.any([&parse_if/1, &parse_parenthesized_expression/1, &parse_value/1]).(tokens)
  end
end
