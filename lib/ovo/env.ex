defmodule Ovo.Env do
  @moduledoc """
  Default environment for Ovo.
  """
  alias Ovo.Ast

  defp map_nodes(nodes, env) do
    Enum.map(nodes, fn node ->
      {_, v} = Ovo.Interpreter.evaluate(node, env)
      v
    end)
  end

  def make(bindings),
    do: %{
      user: bindings,
      builtins: %{
        "add" => fn nodes, env ->
          case map_nodes(nodes, env) do
            [%Ast{kind: :integer, value: v1}, %Ast{kind: :integer, value: v2}] ->
              Ast.integer(v1 + v2)

            [%Ast{kind: :float, value: v1}, %Ast{kind: :float, value: v2}] ->
              Ast.float(v1 + v2)

            [%Ast{kind: k1, value: v1}, %Ast{kind: k2, value: v2}]
            when k1 in [:integer, :float] and k2 in [:integer, :float] ->
              Ast.float(v1 + v2)

            _ ->
              :error
          end
        end,
        "map" => fn nodes, env ->
          case map_nodes(nodes, env) do
            [fun, %Ast{kind: :list, nodes: items}] when is_function(fun) ->
              Enum.map(items, fn i -> fun.([i]) end)

            _ ->
              :error
          end
        end,
        "equals" => fn nodes, env ->
          case map_nodes(nodes, env) do
            [a, a] -> Ovo.Ast.bool(true)
            _ -> Ovo.Ast.bool(false)
          end
        end
      }
    }

  def bind_input(env, input), do: put_in(env, [:user, "data"], input)
end
