defmodule Ovo.Tokenizer do
  @digits ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

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
  Goes to next state while accumulating a token if the buffer wasn't empty, mainly for deduplication purposes.
  """
  @spec accumulate([String.t()], atom(), list(Ovo.Token.t()), binary(), atom()) :: list(Ovo.Token.t())
  def accumulate(rest, state, out, buf, next_state, next_buf \\ "") do
    if buf != "" do
      walk(rest, next_state, [{state, buf} | out], next_buf)
    else
      walk(rest, next_state, out, next_buf)
    end
  end

  @spec binary_to_pattern(String.t()) :: any
  @doc """

  """
  def binary_to_pattern(bin) do
    [first | rest] = String.graphemes(bin) |> Enum.reverse()

    base = [{:|, [], [first, {:tail, [], nil}]}]

    Enum.reduce(rest, base, fn element, out ->
      [
        {:|, [],
         [
           element,
           out
         ]}
      ]
    end)
  end

  defmacro defpat(pattern) do
    binary_to_pattern(pattern)
  end

  @spec walk([String.t()]) :: list(Ovo.Token.t())
  def walk(graphemes), do: walk(graphemes, :undefined, [], "")

  @spec walk([String.t()], atom(), list(Ovo.Token.t()), String.t()) :: list(Ovo.Token.t())
  def walk(defpat("\\`"), :string, out, buf), do: walk(tail, :string, out, buf <> "`")
  def walk(defpat("`"), :string, out, buf), do: accumulate(tail, :string, out, buf, :undefined)
  def walk([h | t], :string, out, buf), do: walk(t, :string, out, buf <> h)

  def walk(["." | t], :number, out, buf) do
    if has_dot?(buf) do
      walk(["."|t], :undefined, out, buf)
    else
      walk(t, :number, out, buf <> ".")
    end
  end
  def walk([a | rest], :number, out, buf) when a in @digits, do: walk(rest, :number, out, buf <> a)
  def walk(input, :number, out, buf), do: accumulate(input, :number, out, buf, :undefined)

  def walk(defpat("`"), state, out, buf), do: accumulate(tail, state, out, buf, :string)
  def walk(defpat("->"), state, out, buf), do: accumulate(tail, state, out, buf, :arrow, nil)
  def walk(defpat("="), state, out, buf), do: accumulate(tail, state, out, buf, :equals, nil)
  def walk(defpat("if"), state, out, buf), do: accumulate(tail, state, out, buf, :if, nil)
  def walk(defpat("else"), state, out, buf), do: accumulate(tail, state, out, buf, :else, nil)
  def walk(defpat("then"), state, out, buf), do: accumulate(tail, state, out, buf, :then, nil)
  def walk(defpat("end"), state, out, buf), do: accumulate(tail, state, out, buf, :end, nil)
  def walk(defpat(","), state, out, buf), do: accumulate(tail, state, out, buf, :comma, nil)
  def walk(defpat("("), state, out, buf), do: accumulate(tail, state, out, buf, :open_paren, nil)
  def walk(defpat("["), state, out, buf), do: accumulate(tail, state, out, buf, :open_bracket, nil)
  def walk(defpat(")"), state, out, buf), do: accumulate(tail, state, out, buf, :close_paren, nil)
  def walk(defpat("]"), state, out, buf), do: accumulate(tail, state, out, buf, :close_bracket, nil)
  def walk(defpat("\\"), state, out, buf), do: accumulate(tail, state, out, buf, :backslash, nil)


  def walk([a | rest], state, out, buf) do
    cond do
      is_whitespace?(a) ->
        accumulate(rest, state, out, buf, :undefined)
      is_numeric?(a) ->
        walk(rest, :number, out, a)
      true ->
        if is_nil(buf) do
          walk(rest, :symbol, [{state, nil} | out], a)
        else
          walk(rest, :symbol, out, buf <> a)
        end
    end
  end

  def walk([], state, out, buf),
    do: if(buf != "", do: [{state, buf} | out], else: out) |> Enum.reverse()
end
