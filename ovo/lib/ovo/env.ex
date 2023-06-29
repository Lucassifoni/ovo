defmodule Ovo.Env do
  @moduledoc """
  Environment module for Ovo. Handles assigning values to an environment, forking environments, and linking them to their parent as well as to the root interpreter, who then keeps a list of child environments in the reverse order they are created.
  """
  alias Ovo.Interpreter

  use Agent
  require Logger

  @doc """
  Starts an Env Agent.
  """
  def start_link(initial_value) do
    Logger.info("Starting an environment")
    Agent.start_link(fn -> initial_value end)
  end

  @doc """
  Returns a new environment state map. The :parent field is only filled by Ovo.Env.fork/1.
  """
  def make(bindings, evaluator_pid),
    do: %{
      evaluator_pid: evaluator_pid,
      parent: nil,
      user: bindings,
      bonks: %{},
      builtins: Ovo.Builtins.builtins()
    }

  @doc """
  Creates a new environment, keeping track of the parent environment.
  """
  def fork(env) do
    Logger.info("Forking an environment")

    state =
      Agent.get(env, & &1)
      |> Map.put(:parent, env)
      |> Map.put(:user, %{})
      |> Map.put(:bonks, %{})
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
              Logger.info("FAILED finding #{name}, walked #{chain |> Enum.map_join(", ", &(:erlang.pid_to_list(&1)))}")
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
