defmodule Ovo.Converter do
  @moduledoc """
  Converts between Ovo values (Ast nodes) and Elixir values (primitives).
  """
  alias Ovo.Ast

  @spec elixir_to_ovo(term()) :: Ovo.Ast.t()
  def elixir_to_ovo(%Ast{} = term), do: term
  def elixir_to_ovo(term) when is_integer(term), do: Ast.integer(term)
  def elixir_to_ovo(term) when is_number(term), do: Ast.float(term)
  def elixir_to_ovo(term) when is_number(term), do: Ast.float(term)
  def elixir_to_ovo(term) when is_boolean(term), do: Ast.bool(term)
  def elixir_to_ovo(term) when is_binary(term), do: Ast.string(term)
  def elixir_to_ovo(term) when is_list(term), do: Ast.list(term |> Enum.map(&elixir_to_ovo/1))

  def elixir_to_ovo(term) when is_map(term),
    do: Ast.map(Enum.map(term, fn {k, v} -> {k, elixir_to_ovo(v)} end) |> Enum.into(%{}))

  @spec elixir_to_ovo(Ovo.Ast.t()) :: term()
  def ovo_to_elixir(%Ast{kind: :bool, value: v}), do: v
  def ovo_to_elixir(%Ast{kind: :float, value: v}), do: v
  def ovo_to_elixir(%Ast{kind: :integer, value: v}), do: v
  def ovo_to_elixir(%Ast{kind: :string, value: v}), do: v
  def ovo_to_elixir(%Ast{kind: :symbol, value: v}), do: v
  def ovo_to_elixir(%Ast{kind: :expr, value: v}), do: ovo_to_elixir(v)

  def ovo_to_elixir(%Ast{kind: :map, value: v}),
    do: v |> Enum.map(fn {k, v1} -> {k, ovo_to_elixir(v1)} end) |> Enum.into(%{})

  def ovo_to_elixir(%Ast{kind: :list, nodes: n}), do: n |> Enum.map(&ovo_to_elixir/1)
end
