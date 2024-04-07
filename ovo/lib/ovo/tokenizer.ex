defmodule Ovo.Tokenizer do
  @moduledoc """
  Tokenizes an input string to produce a list of Ovo.Token.t() tuples.
  The tokeniser works by walking each character (as produced by String.graphemes/1),
  accumulating characters into a buffer until a state switch is detected.
  As some states can repeat themselves, like : (,[,],),end
  We keep a list of such states to be able to accumulate multiple occurences.

  """

  @digits ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
  @repeatables [
    :open_paren,
    :close_paren,
    :end,
    :open_bracket,
    :close_bracket
  ]

  @doc """
  Tokenizes the input string

      iex> Ovo.tokenize("foo = `bar`")
      [{:symbol, "foo"}, {:equals, nil}, {:string, "bar"}]
  """
  @spec tokenize(String.t()) :: list(Ovo.Token.t())
  def tokenize(input) do
    input
    |> String.graphemes()
    |> walk()
  end

  @spec is_whitespace?(binary) :: boolean
  @doc """
  Utility to test for unicode whitespace.
  """
  def is_whitespace?(a), do: Regex.match?(~r/\s/, a)
  def is_numeric?(a), do: Regex.match?(~r/\d/, a)
  def has_dot?(a), do: Regex.match?(~r/\./, a)

  @doc """
  Goes to next state while accumulating a token if the buffer
  wasn't empty. We check if the state is different of the next detected
  state, or if the state is in the list of repeatable states. In those two cases,
  we emit a token containing the current state and its string representation.
  """
  @spec acc(
          [String.t()],
          atom(),
          list(Ovo.Token.t()),
          binary() | nil,
          atom(),
          binary() | nil
        ) :: list(Ovo.Token.t())
  def acc(rest, prev_s, o, b, next_s, next_b \\ "") do
    if prev_s != next_s or prev_s in @repeatables do
      walk(rest, next_s, [{prev_s, b} | o], next_b)
    else
      walk(rest, next_s, o, next_b)
    end
  end

  @spec binary_to_pattern(String.t()) :: any
  @doc """
  Used in a macro to emit list-of-character pattern matches.
  More complex than necessary, but written out of curiosity.
  I wanted to know how the AST of ["a" | ["b" | ["c" | tail ]]] looked like,
  and be able to generate it.
  """
  def binary_to_pattern(binary) do
    [first | rest] = String.graphemes(binary) |> Enum.reverse()

    base = [{:|, [], [first, {:tail, [], nil}]}]

    Enum.reduce(rest, base, fn element, o ->
      [
        {:|, [],
         [
           element,
           o
         ]}
      ]
    end)
  end

  defmacro pat(pattern) do
    binary_to_pattern(pattern)
  end

  @spec walk([String.t()]) :: list(Ovo.Token.t())
  @doc """
  Recursive walk over the list of characters. Clauses are ordered in a way that
  allows to detect string delimiters (backticks), but also escaped string delimiters inside strings.
  """
  def walk(graphemes), do: walk(graphemes, :undefined, [], "")

  @spec walk([String.t()], atom(), list(Ovo.Token.t()), String.t()) :: list(Ovo.Token.t())
  def walk(pat("\\`"), :string, o, b),
    do: acc(tail, :string, o, b <> "`", :string, b <> "`")

  def walk(pat("`"), :string, o, b),
    do: acc(tail, :string, o, b, :undefined)

  def walk([h | t], :string, o, b),
    do: acc(t, :string, o, b <> h, :string, b <> h)

  def walk(["." | t], :number, o, b) do
    if has_dot?(b) do
      walk(["." | t], :undefined, o, b)
    else
      acc(t, :number, o, b <> ".", :number, b <> ".")
    end
  end

  def walk([a | rest], :number, o, b) when a in @digits,
    do: acc(rest, :number, o, b <> a, :number, b <> a)

  def walk(input, :number, o, b), do: acc(input, :number, o, b, :undefined)

  def walk(pat("`"), s, o, b), do: acc(tail, s, o, b, :string)
  def walk(pat("->"), s, o, b), do: acc(tail, s, o, b, :arrow, nil)
  def walk(pat("^"), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token("^"), nil)
  def walk(pat(">>"), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token(">>"), nil)
  def walk(pat("<<"), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token("<<"), nil)
  def walk(pat("<="), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token("<="), nil)
  def walk(pat(">="), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token(">="), nil)
  def walk(pat(">"), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token(">"), nil)
  def walk(pat("<"), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token("<"), nil)
  def walk(pat("=="), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token("=="), nil)
  def walk(pat("!="), s, o, b), do: acc(tail, s, o, b, Ovo.Infix.text_to_token("!="), nil)
  def walk(pat("="), s, o, b), do: acc(tail, s, o, b, :equals, nil)
  def walk(pat("!"), s, o, b), do: acc(tail, s, o, b, :shake, nil)
  def walk(pat("if"), s, o, b) when s != :symbol, do: acc(tail, s, o, b, :if, nil)
  def walk(pat("else"), s, o, b) when s != :symbol, do: acc(tail, s, o, b, :else, nil)
  def walk(pat("then"), s, o, b) when s != :symbol, do: acc(tail, s, o, b, :then, nil)
  def walk(pat("end"), s, o, b) when s != :symbol, do: acc(tail, s, o, b, :end, nil)
  def walk(pat(","), s, o, b), do: acc(tail, s, o, b, :comma, nil)
  def walk(pat("("), s, o, b), do: acc(tail, s, o, b, :open_paren, nil)

  def walk(pat("["), s, o, b),
    do: acc(tail, s, o, b, :open_bracket, nil)

  def walk(pat(")"), s, o, b), do: acc(tail, s, o, b, :close_paren, nil)

  def walk(pat("]"), s, o, b),
    do: acc(tail, s, o, b, :close_bracket, nil)

  def walk(pat("\\"), s, o, b), do: acc(tail, s, o, b, :backslash, nil)

  def walk(pat("T"), :undefined, o, b), do: acc(tail, :undefined, o, b, true)
  def walk(pat("F"), :undefined, o, b), do: acc(tail, :undefined, o, b, false)

  def walk([a | rest], s, o, b) do
    cond do
      is_whitespace?(a) ->
        acc(rest, s, o, b, :undefined, nil)

      is_numeric?(a) ->
        acc(rest, s, o, b, :number, a)

      true ->
        if is_nil(b) do
          walk(rest, :symbol, [{s, nil} | o], a)
        else
          walk(rest, :symbol, o, b <> a)
        end
    end
  end

  def walk([], s, o, b),
    do: [{s, b} | o] |> Enum.reverse() |> Enum.filter(fn {k, _v} -> k != :undefined end)
end
