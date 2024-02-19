defmodule Ovo.Combinators do
  @moduledoc """
  Parser combinators. Samples below operate on primitives instead of ovo tokens for clarity.
  Parser combinators do not need to be tied to a particular data structure (tokens) because they
  simply are higher-order functions over the idea of matching a pattern, or not.

  Combinators are used to express concepts such as "a parser followed by another" (Ovo.Combinators.then/2),
  "this particular parser, or this one" (Ovo.Combinators.either/2).

  The available combinators in this file are :

  - Ovo.Combinators.nothing/1 : always matches anything, does not emit.
  - Ovo.Combinators.either/2 : ParserA or ParserB
  - Ovo.Combinators.then/2 : ParserA then ParserB
  - Ovo.Combinators.all/1 : All parsers in a list
  - Ovo.Combinators.any/1 : First matching parser in a list
  - Ovo.Combinators.repeat/1 : Emits while the parser matches
  """

  @doc """
  Sample parser that succeeds if the current token is 1, fails otherwise.
  """
  def sample_one([1 | rest]), do: {:ok, [1], rest}
  def sample_one(a), do: {:error, [], a}

  @doc """
  Sample parser that succeeds if the current token is ","
  """
  def sample_comma(["," | rest]), do: {:ok, [","], rest}
  def sample_comma(a), do: {:error, [], a}

  @doc """
  Sample parser that succeeds if the current token is "a" or "b".
  """
  def sample_letter(["a" | rest]), do: {:ok, ["a"], rest}
  def sample_letter(["b" | rest]), do: {:ok, ["b"], rest}
  def sample_letter(a), do: {:error, [], a}

  @doc """
  Utility to avoid adding empty list to the output node list.
  """
  def maybe_cons([], a), do: a
  def maybe_cons(a, b), do: [a | b]

  @doc """
  Succeeds if either parserA or parserB succeeds.

      iex> Ovo.Combinators.either(&Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1).([",", 1])
      {:ok, [","], [1]}
  """
  def either(a, b) do
    fn tokens ->
      case a.(tokens) do
        {:ok, _, _} = res ->
          res

        _ ->
          case b.(tokens) do
            {:ok, _, _} = res -> res
            _ -> {:error, [], tokens}
          end
      end
    end
  end

  @doc """
  Always matches, but does not emit a node.
  """
  def nothing(tokens) do
    {:ok, [], tokens}
  end

  @doc """
  Utility to quickly match a valueless token, with reduced duplication in Ovo.Parser
  """
  def match(sigil),
    do: fn input ->
      case input do
        [{^sigil, nil} | rest] -> {:ok, [], rest}
        _ -> {:error, [], input}
      end
    end

  @doc """
  Succeeds if both parsers succeed. Results are accumulated.

      iex> Ovo.Combinators.then(&Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1).([1, ","])
      {:ok, [1, ","], []}
  """
  def then(a, b) do
    fn
      tokens ->
        case a.(tokens) do
          {:ok, result, rest} ->
            case b.(rest) do
              {:ok, bresult, brest} ->
                {:ok, List.flatten([maybe_cons(result, bresult)]), brest}

              _ ->
                {:error, [], tokens}
            end

          _ ->
            {:error, [], tokens}
        end
    end
  end

  @doc """
  Succeeds if one of the given parsers succeeds.

      iex> Ovo.Combinators.any([&Ovo.Combinators.sample_letter/1, &Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1]).(["a", "x", ","])
      {:ok, ["a"], ["x", ","]}
  """
  def any(parsers) do
    fn tokens ->
      Enum.reduce(parsers, {:error, [], tokens}, fn parser, out ->
        case out do
          {:ok, _, _} ->
            out

          _ ->
            case parser.(tokens) do
              {:ok, _, _} = res -> res
              _ -> out
            end
        end
      end)
    end
  end

  def decide(parser, res, rest, tokens) do
    case parser.(rest) do
      {:ok, resn, restn} -> {:ok, maybe_cons(resn, res), restn}
      _ -> {:error, [], tokens}
    end
  end

  @doc """
  Succeeds if all given parsers succeed.

      iex> Ovo.Combinators.all([&Ovo.Combinators.sample_letter/1, &Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1]).(["a", 1, ","])
      {:ok, ["a", 1, ","], []}
  """
  def all(parsers) do
    fn tokens ->
      o =
        Enum.reduce(parsers, nil, fn parser, out ->
          case out do
            nil -> decide(parser, [], tokens, tokens)
            {:ok, res, rest} -> decide(parser, res, rest, tokens)
            _ -> out
          end
        end)

      case o do
        {:ok, out, rest} -> {:ok, List.flatten(Enum.reverse(out)), rest}
        a -> a
      end
    end
  end

  defp accum(parser, res, tokens) do
    case parser.(tokens) do
      {:ok, result, rest} ->
        accum(parser, maybe_cons(result, res), rest)

      {:error, [], rest} ->
        case res do
          [] -> {:error, [], tokens}
          a -> {:ok, a, rest}
        end
    end
  end

  @doc """
  Repeats a parser until it fails. Fails only if the parser does not succeed a single time.

      iex> Ovo.Combinators.repeat(Ovo.Combinators.all([&Ovo.Combinators.sample_letter/1, &Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1])).(["a", 1, ",", "b", 1, ",", 5])
      {:ok, ["a", 1, ",", "b", 1, ","], [5]}
  """
  def repeat(parser) do
    fn tokens ->
      case accum(parser, [], tokens) do
        {:ok, out, rest} -> {:ok, out |> Enum.reverse() |> List.flatten(), rest}
        a -> a
      end
    end
  end
end
