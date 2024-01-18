defmodule Ovo.Builtins do
  @moduledoc """
  Ovo's standard library. Currently supports very few operations.
  """
  alias Ovo.Ast

  defp map_nodes(nodes, env) do
    Enum.map(nodes, fn node ->
      {_, v} = Ovo.Interpreter.evaluate(node, env)
      v
    end)
  end

  def builtins do
    %{
      "add" => &add(&1, &2),
      "map" => &map(&1, &2),
      "reduce" => &reduce(&1, &2),
      "access" => &access(&1, &2),
      "concat" => &concat(&1, &2),
      "arg" => &arg(&1, &2),
      "equals" => &equals(&1, &2),
      "invoke" => &invoke(&1, &2),
      "to_string" => &to_string(&1, &2),
      "errored" => &errored(&1, &2),
      "subtract" => &subtract(&1, &2),
      "multiply" => &multiply(&1, &2),
      "divide" => &divide(&1, &2),
      "map_access" => &map_access(&1, &2),
      "map_set" => &map_set(&1, &2),
      "shake" => &shake(&1, &2),
      "rshake" => &rshake(&1, &2),
      "greater_or_equals" => &greater_or_equals(&1, &2)
    }
  end

  defp concat(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: :string, value: v}, %{kind: :string, value: v2}] ->
        Ovo.Ast.string("#{v}#{v2}")

      _ ->
        :error
    end
  end

  defp to_string(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: k, value: v}] when k in [:string, :float, :integer] ->
        Ovo.Ast.string("#{v}")

      _ ->
        :error
    end
  end

  defp invoke(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: :string, value: hash}, %{kind: :list, nodes: ns}] ->
        Ovo.Registry.run_chain([hash], ns)

      _ ->
        :error
    end
  end

  defp errored(nodes, env) do
    case map_nodes(nodes, env) do
      [:error] -> Ovo.Ast.bool(true)
      _ -> Ovo.Ast.bool(false)
    end
  end

  defp arg(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: :integer, value: v}] ->
        data = Ovo.Env.find_value("data", env)
        Map.get(data.value, "arg#{v}")

      _ ->
        :error
    end
  end

  defp access(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: :string, value: v}] = n ->
        data = Ovo.Env.find_value("data", env)
        Map.get(data.value, v)

      b ->
        :error
    end
  end

  defp greater_or_equals(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: k1, value: v1}, %{kind: k2, value: v2}]
      when k1 in [:float, :integer] and k2 in [:float, :integer] ->
        if v1 >= v2 do
          Ovo.Ast.bool(true)
        else
          Ovo.Ast.bool(false)
        end

      _ ->
        :error
    end
  end

  defp equals(nodes, env) do
    case map_nodes(nodes, env) do
      [a, a] -> Ovo.Ast.bool(true)
      _ -> Ovo.Ast.bool(false)
    end
  end

  defp shake(nodes, env) do
    case map_nodes(nodes, env) do
      [%{callable: _fun, key: k}] ->
        Agent.get_and_update(env, fn state ->
          case state.shakes |> Map.get(k) do
            nil -> {:error, state}
            [] -> {:error, state}
            [a] -> {a, state |> put_in([:shakes, k], [])}
            [h | t] -> {h, state |> put_in([:shakes, k], t)}
          end
        end)

      _ ->
        :error
    end
  end

  defp rshake(nodes, env) do
    case map_nodes(nodes, env) do
      [%{kind: :string, value: v}] ->
        Ovo.Runner.shake(v)

      _ ->
        :error
    end
  end

  defp map(nodes, env) do
    case map_nodes(nodes, env) do
      [fun, %Ast{kind: :list, nodes: items}] when is_function(fun) ->
        Ovo.Ast.list(Enum.map(items, fn i -> fun.([i]) end))

      _ ->
        :error
    end
  end

  defp reduce(nodes, env) do
    case map_nodes(nodes, env) do
      [fun, %Ast{kind: :list, nodes: items}, %Ast{} = initial_value] when is_function(fun) ->
        Enum.reduce(items, initial_value, fn i, acc ->
          fun.([acc, i])
        end)

      _ ->
        :error
    end
  end

  defp add(nodes, env) do
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
  end

  defp subtract(nodes, env) do
    case map_nodes(nodes, env) do
      [%Ast{kind: :integer, value: v1}, %Ast{kind: :integer, value: v2}] ->
        Ast.integer(v1 - v2)

      [%Ast{kind: :float, value: v1}, %Ast{kind: :float, value: v2}] ->
        Ast.float(v1 - v2)

      [%Ast{kind: k1, value: v1}, %Ast{kind: k2, value: v2}]
      when k1 in [:integer, :float] and k2 in [:integer, :float] ->
        Ast.float(v1 - v2)

      _ ->
        :error
    end
  end

  defp multiply(nodes, env) do
    case map_nodes(nodes, env) do
      [%Ast{kind: :integer, value: v1}, %Ast{kind: :integer, value: v2}] ->
        Ast.integer(v1 * v2)

      [%Ast{kind: :float, value: v1}, %Ast{kind: :float, value: v2}] ->
        Ast.float(v1 * v2)

      [%Ast{kind: k1, value: v1}, %Ast{kind: k2, value: v2}]
      when k1 in [:integer, :float] and k2 in [:integer, :float] ->
        Ast.float(v1 * v2)

      _ ->
        :error
    end
  end

  defp divide(nodes, env) do
    case map_nodes(nodes, env) do
      [%Ast{kind: :integer, value: v1}, %Ast{kind: :integer, value: v2}] ->
        Ast.integer(v1 / v2)

      [%Ast{kind: :float, value: v1}, %Ast{kind: :float, value: v2}] ->
        Ast.float(v1 / v2)

      [%Ast{kind: k1, value: v1}, %Ast{kind: k2, value: v2}]
      when k1 in [:integer, :float] and k2 in [:integer, :float] ->
        Ast.float(v1 / v2)

      _ ->
        :error
    end
  end

  defp map_access(nodes, env) do
    case map_nodes(nodes, env) do
      [%Ast{kind: :map, value: v}, %Ast{kind: :string, value: v2}] -> Map.get(v, v2)
      _ -> :error
    end
  end

  defp map_set(nodes, env) do
    case map_nodes(nodes, env) do
      [%Ast{kind: :map, value: v}, %Ast{kind: :string, value: v2}, %Ast{} = v3] ->
        Map.put(v, v2, v3)

      _ ->
        :error
    end
  end
end
