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

  def parse_multiple_element_list(tokens) do
    case C.all([
           C.match(:open_bracket),
           C.repeat(C.then(&parse_expression/1, &parse_comma/1)),
           &parse_expression/1,
           &parse_close_bracket/1
         ]).(tokens) do
      {:ok, nodes, rest} ->
        {:ok, Ast.list(nodes |> List.flatten() |> Enum.filter(&(!is_nil(&1))) |> Enum.reverse()),
         rest}

      b ->
        b
    end
  end

  def parse_empty_list(tokens) do
    case C.then(C.match(:open_bracket), C.match(:close_bracket)).(tokens) do
      {:ok, _, rest} -> {:ok, Ast.list([]), rest}
      b -> b
    end
  end

  def parse_single_element_list(tokens) do
    case C.all([C.match(:open_bracket), &parse_expression/1, C.match(:close_bracket)]).(tokens) do
      {:ok, node, rest} -> {:ok, Ast.list([node]), rest}
      b -> b
    end
  end

  @doc """
    Parses a list of expressions
      iex> tokens = Ovo.Tokenizer.tokenize("[a, b, c, 5]")
      iex> {:ok, _, []} = Ovo.Parser.parse_list(tokens)
  """
  def parse_list(tokens) do
    case C.any([&parse_multiple_element_list/1, &parse_empty_list/1, &parse_single_element_list/1]).(
           tokens
         ) do
      {:ok, nodes, rest} ->
        {:ok, Ast.list(nodes), rest}

      b ->
        b
    end
  end

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

  def parse_if(tokens) do
    case C.all([
           &parse_if_head/1,
           C.repeat(&parse_expression/1),
           &parse_else/1,
           C.repeat(&parse_expression/1),
           &parse_end/1
         ]).(tokens) do
      {:ok, nodes, rest} ->
        case nodes |> Enum.filter(&(!is_nil(&1))) do
          [predicate, true_branch, false_branch] ->
            {:ok, Ast.condition([predicate, true_branch, false_branch]), rest}

          _ ->
            throw("If parsing failed : three lists of nodes should have been found.")
        end

      b ->
        b
    end
  end

  def parse_single_arg_call(tokens) do
    case C.all([&parse_symbol/1, C.match(:open_paren), &parse_expression/1, C.match(:close_paren)]).(
           tokens
         ) do
      {:ok, nodes, rest} ->
        case nodes |> Enum.filter(&(!is_nil(&1))) do
          [a, b] -> {:ok, Ast.call(a, [b]), rest}
          b -> b
        end

      b ->
        b
    end
  end

  def parse_multiple_arg_call(tokens) do
    C.all([
      &parse_symbol/1,
      C.match(:open_paren),
      C.then(C.repeat(C.then(&parse_expression/1, &parse_comma/1)), &parse_expression/1),
      C.match(:close_paren)
    ]).(tokens)
  end

  def parse_argless_call(tokens) do
    case C.all([&parse_symbol/1, C.match(:open_paren), C.match(:close_paren)]).(tokens) do
      {:ok, [%Ast{kind: :symbol} = a | _], rest} -> {:ok, Ast.call(a), rest}
      b -> b
    end
  end

  def parse_call(tokens) do
    C.any([&parse_single_arg_call/1, &parse_multiple_arg_call/1, &parse_argless_call/1]).(tokens)
  end

  @doc """
  Parses an expression.
    iex> alias Ovo.Tokenizer, as: Tok
    iex> tokens = Tok.tokenize("if foo then 5 bar else 6 end")
    iex> {:ok, _, []} = Ovo.Parser.parse_expression(tokens)
  """
  def parse_expression(tokens) do
    case C.any([&parse_if/1, &parse_call/1, &parse_parenthesized_expression/1, &parse_value/1]).(
           tokens
         ) do
      {:ok, nodes, rest} -> {:ok, Ast.expr(nodes), rest}
      b -> b
    end
  end

  def parse(tokens) do
    C.repeat(&parse_expression/1).(tokens)
  end
end
