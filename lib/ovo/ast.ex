defmodule Ovo.Ast do
  @moduledoc """
  Defines an AST node for Ovo.
  """
  defstruct [:kind, :nodes, :value]

  def make(kind \\ :root, value \\ nil), do: %__MODULE__{kind: kind, nodes: [], value: value}

  def float(val), do: make(:float, val)
  def integer(val), do: make(:integer, val)
  def string(val), do: make(:string, val)

  def symbol(val), do: make(:symbol, val)
end
