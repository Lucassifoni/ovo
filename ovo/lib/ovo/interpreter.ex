defmodule Ovo.Interpreter do
  use Agent
  require Logger

  @moduledoc """
  Basic Ovo Ast interpreter.
  """
  alias Ovo.Ast
  alias Ovo.Env

  def start_link(initial_value) do
    Logger.info("Starting an interpreter")
    Agent.start_link(fn -> initial_value end)
  end

  def register_pid(pid, fork_pid) do
    Logger.info("Registering an environment")
    Agent.update(pid, fn pids -> [fork_pid | pids] end)
    :ok
  end

  def stop_env(pid) do
    pids = Agent.get(pid, & &1)

    pids
    |> Enum.each(fn p ->
      Logger.info("Stopping an environment")
      Agent.stop(p)
    end)

    Logger.info("Stopping the interpreter")
    Agent.stop(pid)
  end

  def run(ast), do: run(ast, %{}, %{})

  def run(%Ast{} = ast, input, bindings) do
    {:ok, evaluator_pid} = start_link([])
    ovo_input = Ovo.Converter.elixir_to_ovo(input)
    initial_state = Env.make(bindings, evaluator_pid) |> Env.bind_input(ovo_input)
    Logger.info("Starting the root environment")
    {:ok, env} = Env.start_link(initial_state)
    register_pid(evaluator_pid, env)
    {_, v} = evaluate(ast, env)
    stop_env(evaluator_pid)
    v
  end

  def reduce_nodes(nodes, env) do
    Enum.reduce(nodes, {env, nil}, fn node, {ev, _lev} ->
      evaluate(node, ev)
    end)
  end

  def evaluate(nodes, env) when is_list(nodes), do: reduce_nodes(nodes, env)

  def evaluate(%Ovo.Ast{} = ast, env) do
    case ast.kind do
      :root ->
        evaluate(ast.nodes, env)

      :assignment ->
        key = ast.value
        {_, val} = evaluate(ast.nodes, env)
        {Env.update_env(env, key.value, val), val}

      :block ->
        evaluate(ast.nodes, env)

      :condition ->
        [predicate, branch1, branch2] = ast.nodes
        {_, val} = evaluate(predicate, env)

        {_, v} =
          case val do
            %Ast{kind: :bool, value: true} -> evaluate(branch1, env)
            %Ast{kind: :bool, value: false} -> evaluate(branch2, env)
          end

        {env, v}

      :bonk ->
        {_env, inner_fn} = evaluate(ast.value, env)
        key = :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0..16)

        {env,
         %{
           callable: fn args ->
             res = inner_fn.(args)

             Agent.update(env, fn state ->
               bonk_stack = Map.get(state.bonks, key, [])
               put_in(state, [:bonks, key], [res | bonk_stack])
             end)

             res
           end,
           key: key
         }}

      :lambda ->
        arity = length(ast.value)
        program = ast.nodes

        {env,
         fn args ->
           {:ok, captured_env} = Env.fork(env)

           if length(args) != arity do
             {:error, "#{length(args)} argument(s) passed instead of #{arity}"}
           else
             symbols_and_args = Enum.zip(ast.value, args)

             env_with_applied_args =
               Enum.reduce(symbols_and_args, captured_env, fn {sym, arg}, uenv ->
                 {_, v} = evaluate(arg, uenv)
                 Env.update_env(uenv, sym.value, v)
                 uenv
               end)

             {_, k} = evaluate(program, env_with_applied_args)
             k
           end
         end}

      :call ->
        case Env.find_callable(ast.value.value, env) do
          {:user, %{callable: fun}} ->
            evaluated_args =
              ast.nodes
              |> Enum.map(fn node ->
                {_, v} = evaluate(node, env)
                v
              end)

            v = fun.(evaluated_args)
            {env, v}

          {:user, fun} ->
            evaluated_args =
              ast.nodes
              |> Enum.map(fn node ->
                {_, v} = evaluate(node, env)
                v
              end)

            v = fun.(evaluated_args)
            {env, v}

          {:builtins, fun} ->
            r = fun.(ast.nodes, env)
            {env, r}

          {:error, msg} ->
            throw({:error, msg})
        end

      :symbol ->
        {env, Env.find_value(ast.value, env)}

      :expr ->
        evaluate(ast.value, env)

      _ ->
        {env, ast}
    end
  end
end
