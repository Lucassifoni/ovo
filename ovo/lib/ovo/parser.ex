defmodule Ovo.Parser do
  @moduledoc """
  Parses a list of Ovo.Token.t() to generate an Ovo.Ast.
  """

  alias Ovo.Ast
  alias Ovo.Combinators, as: C

  def err(tokens), do: {:error, [], tokens}
  def ok(result, rest), do: {:ok, result, rest}

  def p_number([{:number, val} | rest] = tokens) do
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

  def p_number(a), do: err(a)

  def p_string([{:string, val} | rest]), do: ok(Ast.string(val), rest)
  def p_string(a), do: err(a)

  def p_symbol([{:symbol, val} | rest]), do: ok(Ast.symbol(val), rest)
  def p_symbol(a), do: err(a)

  def p_comma(tokens), do: C.match(:comma).(tokens)
  def p_close_paren(tokens), do: C.match(:close_paren).(tokens)
  def close_bracket(tokens), do: C.match(:close_bracket).(tokens)

  def p_multiple_element_list(tokens) do
    case C.all([
           C.match(:open_bracket),
           C.repeat(C.then(&p_expression/1, &p_comma/1)),
           &p_expression/1,
           &close_bracket/1
         ]).(tokens) do
      {:ok, nodes, rest} ->
        {:ok, Ast.list(nodes), rest}

      b ->
        b
    end
  end

  def p_empty_list(tokens) do
    case C.then(C.match(:open_bracket), &close_bracket/1).(tokens) do
      {:ok, _, rest} -> {:ok, Ast.list([]), rest}
      b -> b
    end
  end

  def p_single_element_list(tokens) do
    case C.all([C.match(:open_bracket), &p_expression/1, &close_bracket/1]).(tokens) do
      {:ok, node, rest} -> {:ok, Ast.list(node), rest}
      b -> b
    end
  end

  @doc """
    Parses a list of expressions
      iex> tokens = Ovo.Tokenizer.tokenize("[a, b, c, 5]")
      iex> {:ok, _, []} = Ovo.Parser.p_list(tokens)
  """
  def p_list(tokens) do
    case C.any([&p_multiple_element_list/1, &p_empty_list/1, &p_single_element_list/1]).(tokens) do
      {:ok, node, rest} ->
        {:ok, node, rest}

      b ->
        b
    end
  end

  def p_bool([{true, _} | rest]), do: {:ok, Ast.bool(true), rest}
  def p_bool([{false, _} | rest]), do: {:ok, Ast.bool(false), rest}
  def p_bool(tokens), do: {:error, [], tokens}

  @doc """
  Parses a primitive value.

      iex> Ovo.Parser.p_value([{:number, "5"}])
      {:ok, %Ovo.Ast{kind: :integer, nodes: [], value: 5}, []}
      iex> Ovo.Parser.p_value([{:string, "foo"}])
      {:ok, %Ovo.Ast{kind: :string, nodes: [], value: "foo"}, []}
      iex> Ovo.Parser.p_value([{:arrow, nil}])
      {:error, [], [{:arrow, nil}]}
  """
  def p_value(tokens),
    do: C.any([&p_number/1, &p_string/1, &p_symbol/1, &p_list/1, &p_bool/1]).(tokens)

  def p_parenthesized_expression(tokens) do
    case C.all([C.match(:open_paren), &p_expression/1, &p_close_paren/1]).(tokens) do
      {:ok, nodes, rest} ->
        {:ok, Ast.expr(nodes), rest}

      b ->
        b
    end
  end

  def p_if_head(tokens) do
    case C.all([C.match(:if), &p_expression/1, C.match(:then)]).(tokens) do
      {:ok, nodes, rest} -> {:ok, nodes, rest}
      b -> b
    end
  end

  def p_else(tokens), do: C.match(:else).(tokens)
  def p_end(tokens), do: C.match(:end).(tokens)

  def p_if(tokens) do
    case C.all([
           &p_if_head/1,
           C.repeat(&p_block/1),
           &p_else/1,
           C.repeat(&p_block/1),
           &p_end/1
         ]).(tokens) do
      {:ok, nodes, rest} ->
        case nodes do
          [predicate, true_branch, false_branch] ->
            {:ok, Ast.condition([predicate, true_branch, false_branch]), rest}

          _ ->
            throw("If parsing failed : three nodes should have been found.")
        end

      b ->
        b
    end
  end

  def p_single_arg_call(tokens) do
    case C.all([&p_symbol/1, C.match(:open_paren), &p_expression/1, C.match(:close_paren)]).(
           tokens
         ) do
      {:ok, nodes, rest} ->
        case nodes do
          [a, b] -> {:ok, Ast.call(a, [b]), rest}
          b -> b
        end

      b ->
        b
    end
  end

  def p_multiple_arg_call(tokens) do
    case C.all([
           &p_symbol/1,
           C.match(:open_paren),
           C.repeat(C.then(&p_expression/1, &p_comma/1)),
           &p_expression/1,
           C.match(:close_paren)
         ]).(tokens) do
      {:ok, [a | b], rest} -> {:ok, Ast.call(a, b), rest}
      b -> b
    end
  end

  def p_argless_call(tokens) do
    case C.all([&p_symbol/1, C.match(:open_paren), C.match(:close_paren)]).(tokens) do
      {:ok, [%Ast{kind: :symbol} = a | _], rest} -> {:ok, Ast.call(a), rest}
      b -> b
    end
  end

  def p_call(tokens) do
    C.any([&p_single_arg_call/1, &p_multiple_arg_call/1, &p_argless_call/1]).(tokens)
  end

  def p_assignment(tokens) do
    case C.all([&p_symbol/1, C.match(:equals), &p_expression/1]).(tokens) do
      {:ok, [symb, expr], rest} -> {:ok, Ast.assignment(symb, expr), rest}
      b -> b
    end
  end

  def p_shake(tokens) do
    case C.match(:shake).(tokens) do
      {:ok, _, rest} ->
        case p_lambda(rest) do
          {:ok, lambda, rest} -> {:ok, Ast.shake(lambda), rest}
          _ -> {:error, nil, tokens}
        end

      b ->
        b
    end
  end

  def p_lambda(tokens) do
    case C.all([
           C.match(:backslash),
           C.any([
             &p_multiple_lambda/1,
             &p_single_lambda/1,
             &p_zero_lambda/1
           ]),
           C.match(:arrow),
           &p_block/1,
           &p_end/1
         ]).(tokens) do
      {:ok, a, rest} ->
        case a do
          [c, b] ->
            {:ok, Ast.lambda([c], b), rest}

          other when is_list(other) ->
            l = length(other)
            args = other |> Enum.slice(0..(l - 2))
            body = other |> List.last()
            {:ok, Ast.lambda(args, body), rest}

          _ ->
            raise "This branch should never match."
        end

      b ->
        b
    end
  end

  def p_single_lambda(tokens) do
    case p_symbol(tokens) do
      {:ok, node, rest} -> {:ok, node, rest}
      b -> b
    end
  end

  def p_multiple_lambda(tokens) do
    case C.all([
           C.repeat(
             C.then(
               &p_symbol/1,
               &p_comma/1
             )
           ),
           &p_symbol/1
         ]).(tokens) do
      {:ok, nodes, rest} -> {:ok, [nodes], rest}
      b -> b
    end
  end

  def p_zero_lambda(tokens), do: {:ok, nil, tokens}

  def p_lambda_body(tokens), do: p_block(tokens)

  @doc """
  Parses an expression.
    iex> alias Ovo.Tokenizer, as: Tok
    iex> tokens = Tok.tokenize("if foo then 5 bar else 6 end")
    iex> {:ok, _, []} = Ovo.Parser.p_expression(tokens)
  """
  def p_expression(tokens) do
    case C.any([
           &p_shake/1,
           &p_lambda/1,
           &p_assignment/1,
           &p_if/1,
           &p_call/1,
           &p_parenthesized_expression/1,
           &p_value/1
         ]).(tokens) do
      {:ok, nodes, rest} -> {:ok, Ast.expr(nodes), rest}
      b -> b
    end
  end

  def p_block(tokens) do
    case C.repeat(&p_expression/1).(tokens) do
      {:ok, nodes, rest} -> {:ok, Ast.block(nodes), rest}
      b -> b
    end
  end

  def parse(tokens) do
    case C.repeat(&p_expression/1).(tokens) do
      {:ok, ast, []} -> {:ok, Ast.root(ast), []}
      b -> b
    end
  end
end
