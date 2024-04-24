defmodule Ovo.Registry do
  require Logger

  @moduledoc """
  The Ovo.Registry holds information about multiple Ovo.Runner, keeping track of their Hash <-> Pid mapping, and of previous results in a stack.
  In a similar way that shakable lambdas keep track of their previous results in a single interpreter run, Runners are globally shakable and can pop back their previous execution results.
  """

  use Agent

  def start, do: start_link(nil)

  def start_link(_) do
    Logger.info("Starting Ovo.Registry")

    Agent.start_link(
      fn ->
        %{}
      end,
      name: __MODULE__
    )
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  defp view_runner(hash, %{metadata: metadata, stack: stack}) do
    %{
      stack: stack,
      metadata: metadata,
      hash: hash
    }
  end

  def runners do
    Agent.get(
      __MODULE__,
      &(Enum.map(&1, fn {k, v} -> {k, view_runner(k, v)} end) |> Enum.into(%{}))
    )
  end

  def run_chain(hashes, inputs) do
    Enum.reduce(hashes, inputs, fn hash, values ->
      {:ok, _pid} = find_runner(hash)
      Ovo.Runner.run(hash, values)
    end)
  end

  def find_runner(hash) do
    case Agent.get(__MODULE__, &(&1 |> Map.get(hash))) do
      %{runner: pid, stack: _stack} -> {:ok, pid}
      _ -> {:error, nil}
    end
  end

  def remove_runner(hash) do
    Agent.update(__MODULE__, fn state ->
      state |> Map.drop([hash])
    end)
  end

  def wrap_registration(ast, code, name, hash, args) do
    Agent.update(__MODULE__, fn state ->
      {:ok, pid} =
        Ovo.Runner.start_link(%Ovo.Runner{ast: ast, code: code, name: name, hash: hash})

      state
      |> Map.put(hash, %{
        runner: pid,
        stack: [],
        last_env: %{},
        metadata: %{code: code, name: name, args: args}
      })
    end)
  end

  def update_runner_arg(hash, position, arg) do
    Agent.update(__MODULE__, fn state ->
      update_in(
        state,
        [Access.key!(hash), Access.key!(:metadata), Access.key!(:args), Access.at!(position)],
        fn {k, _v} -> {k, arg} end
      )
    end)
  end

  def get_runner_args(hash) do
    Agent.get(__MODULE__, fn state ->
      get_in(state, [Access.key!(hash), Access.key!(:metadata), Access.key!(:args)])
    end)
  end

  def push_result(hash, result, last_env) do
    Agent.update(__MODULE__, fn state ->
      {_, nv} =
        Map.get_and_update(state, hash, fn %{
                                             runner: pid,
                                             stack: stack,
                                             last_env: _,
                                             metadata: metadata
                                           } = a ->
          {a, %{runner: pid, stack: [result | stack], last_env: last_env, metadata: metadata}}
        end)

      nv
    end)
  end

  def pop_result(hash) do
    Agent.get_and_update(__MODULE__, fn state ->
      {%{runner: _pid, stack: [h | _t]}, nv} =
        Map.get_and_update(state, hash, fn %{
                                             runner: pid,
                                             stack: [_h | t],
                                             last_env: le,
                                             metadata: metadata
                                           } = m ->
          {m, %{runner: pid, stack: t, last_env: le, metadata: metadata}}
        end)

      {h, nv}
    end)
  end
end
