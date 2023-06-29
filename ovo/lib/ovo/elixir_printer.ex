defmodule Ovo.ElixirPrinter do
  @moduledoc """
  Prints an Ovo Abstract Syntax Tree to Elixir code.
  """

  def print(%Ovo.Ast{} = ast) do
    Enum.reduce(ast.nodes, "", fn node, output ->
      output <> print_node(node) <> "\n"
    end)
  end

  def print_node(%Ovo.Ast{kind: :expr, value: val}), do: print_node(val)

  def print_node(%Ovo.Ast{kind: :call, value: val, nodes: children}) do
    "#{val.value}(#{Enum.map_join(children, ", ", &print_node/1)})"
  end

  def print_node(%Ovo.Ast{kind: :symbol, value: val}) do
    "#{val}"
  end

  def print_node(%Ovo.Ast{kind: :bool, value: s}), do: if(s, do: "true", else: "false")

  def print_node(%Ovo.Ast{kind: :assignment, value: sym, nodes: expr}) do
    "#{sym.value} = #{print_node(expr)}"
  end

  def print_node(%Ovo.Ast{kind: :lambda, value: head, nodes: body}) do
    """
      fn (#{Enum.map_join(head, ", ", &print_node/1)}) ->
        #{print_node(body)}
      end
    """
  end

  def print_node(%Ovo.Ast{kind: :integer, value: val}) do
    "#{val}"
  end

  def print_node(%Ovo.Ast{kind: :float, value: val}) do
    "#{val}"
  end

  def print_node(%Ovo.Ast{kind: :string, value: val}) do
    "\"#{val |> String.replace("\"", "\\\"")}\""
  end

  def print_node(%Ovo.Ast{kind: :condition, nodes: [predicate, valid, invalid]}) do
    """
    if #{print_node(predicate)} do
      #{print_node(valid)}
    else
      #{print_node(invalid)}
    end
    """
  end

  def print_node(%Ovo.Ast{kind: :list, nodes: nodes}) do
    "[#{Enum.map_join(nodes, ", ", &print_node/1)}]"
  end

  def print_node(%Ovo.Ast{kind: :block, nodes: nodes}) do
    "#{Enum.map_join(nodes, "\n", &print_node/1)}"
  end

  def print_node(_), do: ""
end