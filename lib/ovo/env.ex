defmodule Ovo.Env do
  @moduledoc """
  Default environment for Ovo.
  """
  alias Ovo.Interpreter
  alias Ovo.Ast

  use Agent
  require Logger

  def start_link(initial_value) do
    Logger.info("Starting an environment")
    Agent.start_link(fn -> initial_value end)
  end

  defp map_nodes(nodes, env) do
    Enum.map(nodes, fn node ->
      {_, v} = Ovo.Interpreter.evaluate(node, env)
      v
    end)
  end

  def make(bindings, evaluator_pid),
    do: %{
      evaluator_pid: evaluator_pid,
      parent: nil,
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

  def fork(env) do
    Logger.info("Forking an environment")

    state =
      Agent.get(env, & &1)
      |> Map.put(:parent, env)
      |> Map.put(:user, %{})
      |> Map.put(:builtins, %{})

    {:ok, fork_pid} = start_link(state)
    Interpreter.register_pid(state.evaluator_pid, fork_pid)
    {:ok, fork_pid}
  end

  def bind_input(env, input), do: put_in(env, [:user, "data"], input)

  def update_env(env, key, val) do
    Agent.update(env, fn state ->
      put_in(state, [:user, key], val)
    end)

    env
  end

  def find_callable(name, env, chain \\ []) do
    Agent.get(env, fn state ->
      if Map.has_key?(state.user, name) do
        {:user, Map.get(state.user, name)}
      else
        if Map.has_key?(state.builtins, name) do
          Logger.info("Found #{name}")
          {:builtins, Map.get(state.builtins, name)}
        else
          case state.parent do
            nil ->
              Logger.info("FAILED finding #{name} #{chain}")
              :error

            pid ->
              # Logger.info("Looking for #{name}, going up")
              find_callable(name, pid, [env | chain])
          end
        end
      end
    end)
  end

  def find_value(name, env, chain \\ []) do
    Agent.get(env, fn state ->
      if Map.has_key?(state.user, name) do
        Map.get(state.user, name)
      else
        if Map.has_key?(state.builtins, name) do
          Map.get(state.builtins, name)
        else
          case state.parent do
            nil ->
              Logger.info("FAILED finding #{name}, walked #{chain |> Enum.map_join(", ", &(:erlang.pid_to_list(&1)))}")
              :error

            pid ->
              # Logger.info("Looking for #{name}, going up")
              find_value(name, pid, [env | chain])
          end
        end
      end
    end)
  end
end
