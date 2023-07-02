defmodule Ovo.Registry do
  @moduledoc """
  The Ovo.Registry holds information about multiple Ovo.Runner, keeping track of their Hash <-> Pid mapping, and of previous results in a stack.
  In a similar way that bonkable lambdas keep track of their previous results in a single interpreter run, Runners are globally bonkable and can pop back their previous execution results.
  """
  use Agent

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{}
      end,
      name: __MODULE__
    )
  end

  def run_chain(hashes, inputs) do
    Enum.reduce(hashes, inputs, fn hash, values ->
      {:ok, pid} = find_runner(hash)
      Ovo.Runner.run(hash, values)
    end)
  end

  def find_runner(hash) do
    case Agent.get(__MODULE__, &(&1 |> Map.get(hash))) do
      %{runner: pid, stack: stack} -> {:ok, pid}
      _ -> {:error, nil}
    end
  end

  def register_runner(pid, hash) do
    Agent.update(__MODULE__, fn state ->
      state |> Map.put(hash, %{runner: pid, stack: [], last_env: %{}})
    end)
  end

  def push_result(hash, result, last_env) do
    Agent.update(__MODULE__, fn state ->
      {_, nv} =
        Map.get_and_update(state, hash, fn %{runner: pid, stack: stack, last_env: _} = a ->
          {a, %{runner: pid, stack: [result | stack], last_env: last_env}}
        end)

      nv
    end)
  end

  def pop_result(hash) do
    Agent.get_and_update(__MODULE__, fn state ->
      {%{runner: pid, stack: [h | t]}, nv} =
        Map.get_and_update(state, hash, fn %{runner: pid, stack: [h | t], last_env: le} = m ->
          {m, %{runner: pid, stack: t, last_env: le}}
        end)

      {h, nv}
    end)
  end
end
