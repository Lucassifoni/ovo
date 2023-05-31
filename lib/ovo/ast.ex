defmodule Ovo.Ast do
  @moduledoc """
  Defines an AST node for Ovo.
  """

  defstruct [:kind, :nodes, :value]

  def make(kind \\ :root, value \\ nil, children \\ []),
    do: %__MODULE__{kind: kind, nodes: children, value: value}

  def root(children), do: make(:root, nil, children)

  def float(val), do: make(:float, val)
  def integer(val), do: make(:integer, val)
  def string(val), do: make(:string, val)

  def symbol(val), do: make(:symbol, val)

  def list(children), do: make(:list, nil, children)

  def expr([val]), do: make(:expr, val, [])
  def expr(val), do: make(:expr, val, [])

  def assignment(symbol, expr), do: make(:assignment, symbol, expr)
  def block(nodes), do: make(:block, nil, nodes)

  def condition([a, b, c]), do: make(:condition, nil, [a, b, c])

  def lambda(head, body), do: make(:lambda, head, body)

  def call(val, children \\ []), do: make(:call, val, children)
end
