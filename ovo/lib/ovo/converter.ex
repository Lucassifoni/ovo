defmodule Ovo.Converter do
  @moduledoc """
  Converts between Ovo values (Ast nodes) and Elixir values (primitives).
  """
  alias Ovo.Ast

  def elixir_to_ovo(term) when is_integer(term), do: Ast.integer(term)
  def elixir_to_ovo(term) when is_number(term), do: Ast.float(term)
  def elixir_to_ovo(term) when is_number(term), do: Ast.float(term)
  def elixir_to_ovo(term) when is_boolean(term), do: Ast.bool(term)
  def elixir_to_ovo(term) when is_binary(term), do: Ast.string(term)
  def elixir_to_ovo(term) when is_list(term), do: Ast.list(term |> Enum.map(&elixir_to_ovo/1))

  def elixir_to_ovo(term) when is_map(term),
    do: Ast.map(Enum.map(term, fn {k, v} -> {k, elixir_to_ovo(v)} end) |> Enum.into(%{}))

  def ovo_to_elixir(%Ast{kind: :bool, value: v}), do: v
end
