defmodule Ovo.ElixirPrinter do
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
