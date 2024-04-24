defmodule Ovo.Printer do
  @moduledoc """
  Prints an Ovo.Ast to Ovo code. Note that non-significant symbols like parentheses in parenthesized expressions are discarded (until the eventual introductions of operators and precedence problems).
  """

  def print({:ok, tree, []}) do
    print(tree)
  end

  def print(ast) when is_tuple(ast) and tuple_size(ast) == 3 do
    {_, nodes, _} = ast

    Enum.reduce(nodes, "", fn node, output ->
      output <> print_node(node) <> "\n"
    end)
  end

  def print_node({:expr, _, val}), do: "(#{print_node(val)})"

  def print_node({:call, children, val}) do
    {_, _, vv} = val
    "#{vv}(#{Enum.map_join(children, ", ", &print_node/1)})"
  end

  def print_node({:infix, [e1, e2], symbol}) do
    s = Ovo.Infix.token_to_text(symbol)
    "#{print_node(e1)} #{s} #{print_node(e2)}"
  end

  def print_node({:assignment, expr, sym}) do
    {_, _, vv} = sym
    "#{vv} = #{print_node(expr)}"
  end

  def print_node({:shake, _, v}) do
    "!#{print_node(v)}"
  end

  def print_node({:bool, _, s}), do: if(s, do: "T", else: "F")

  def print_node({:symbol, _, val}) do
    "#{val}"
  end

  def print_node({:integer, _, val}) do
    "#{val}"
  end

  def print_node({:lambda, body, head}) do
    """
      \\#{Enum.map_join(head, ", ", &print_node/1)} ->
        #{print_node(body)}
      end
    """
  end

  def print_node({:float, _, val}) do
    "#{val}"
  end

  def print_node({:string, _, val}) do
    "`#{val |> String.replace("`", "\\`")}`"
  end

  def print_node({:condition, [predicate, valid, invalid], _}) do
    """
    if #{print_node(predicate)} then
      #{print_node(valid)}
    else
      #{print_node(invalid)}
    end
    """
  end

  def print_node({:list, nodes, _}) do
    "[#{Enum.map_join(nodes, ", ", &print_node/1)}]"
  end

  def print_node({:block, nodes, _}) do
    "#{Enum.map_join(nodes, "\n", &print_node/1)}"
  end

  def print_node(_), do: ""
end
