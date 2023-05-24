defmodule Ovo.Parser do
  alias Ovo.Ast

  @moduledoc """

  """
  @spec parse(list(Ovo.Token.t())) :: %Ovo.Ast{}
  def parse(tokens) do
    %Ast{kind: :root, nodes: parse(tokens, [], :undefined, [])}
  end

  def parse([{:nonstring, b}, {:equals, _}, {type, v} | rest], out, state, buf) do
    assignment = [%Ast{kind: :assignment, nodes: [%Ast{kind: :symbol, value: b}, %Ast{kind: type, value: v}]}]
    parse(rest, out, state, [assignment | buf])
  end

  def parse([], out, state, buf) do
    buf |> Enum.reverse()
  end
end
