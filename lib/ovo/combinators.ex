defmodule Ovo.Combinators do
  @moduledoc """
  Parser combinators. Samples operate on primitives instead of ovo tokens for clarity.
  """

  def sample_one([1 | rest]), do: {:ok, 1, rest}
  def sample_one(a), do: {:error, nil, a}
  def sample_comma(["," | rest]), do: {:ok, ",", rest}
  def sample_comma(a), do: {:error, nil, a}

  def sample_letter(["a" | rest]), do: {:ok, "a", rest}
  def sample_letter(a), do: {:error, nil, a}

  @doc """
  Succeeds if either parserA or parserB succeeds.

      iex> Ovo.Combinators.either(&Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1).([",", 1])
      {:ok, ",", [1]}
  """
  def either(a, b) do
    fn tokens ->
      case a.(tokens) do
        {:ok, _, _} = res ->
          res

        _ ->
          case b.(tokens) do
            {:ok, _, _} = res -> res
            _ -> {:error, nil, tokens}
          end
      end
    end
  end

  @doc """
  Utility to quickly match a valueless token, with reduced duplication in Ovo.Parser
  """
  def match(sigil),
    do: fn input ->
      case input do
        [{^sigil, nil} | rest] -> {:ok, nil, rest}
        _ -> {:error, nil, input}
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
                {:ok, [result, bresult], brest}

              _ ->
                {:error, nil, tokens}
            end

          _ ->
            {:error, nil, tokens}
        end
    end
  end

  @doc """
  Succeeds if one of the given parsers succeeds.

      iex> Ovo.Combinators.any([&Ovo.Combinators.sample_letter/1, &Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1]).(["a", "x", ","])
      {:ok, "a", ["x", ","]}
  """
  def any(parsers) do
    fn tokens ->
      Enum.reduce(parsers, {:error, nil, tokens}, fn parser, out ->
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

  defp decide(parser, res, rest, tokens) do
    case parser.(rest) do
      {:ok, resn, restn} -> {:ok, [resn | res], restn}
      _ -> {:error, nil, tokens}
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
        {:ok, out, rest} when is_list(out) -> {:ok, Enum.reverse(out), rest}
        a -> a
      end
    end
  end

  defp accum(parser, res, tokens) do
    o =
      case parser.(tokens) do
        {:ok, result, rest} ->
          accum(parser, [result | res], rest)

        {:error, nil, rest} ->
          case res do
            [] -> {:error, [], tokens}
            a -> {:ok, a, rest}
          end
      end

    case o do
      {:ok, out, rest} when is_list(out) -> {:ok, List.flatten(Enum.reverse(out)), rest}
      a -> a
    end
  end

  @doc """
  Repeats a parser until it fails. Fails only if the parser does not succeed a single time.

      iex> Ovo.Combinators.repeat(Ovo.Combinators.all([&Ovo.Combinators.sample_letter/1, &Ovo.Combinators.sample_one/1, &Ovo.Combinators.sample_comma/1])).(["a", 1, ",", "a", 1, ",", 5])
      {:ok, ["a", 1, ",", "a", 1, ","], [5]}
  """
  def repeat(parser) do
    fn tokens ->
      accum(parser, [], tokens)
    end
  end
end
