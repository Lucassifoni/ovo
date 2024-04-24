defmodule Ovo.Interpreter do
  use Agent
  require Logger

  @moduledoc """
  Basic Ovo Ast interpreter.
  """

  alias Ovo.Ast
  alias Ovo.Env

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end)
  end

  @spec register_pid(pid(), pid()) :: :ok
  def register_pid(pid, fork_pid) do
    Agent.update(pid, fn pids -> [fork_pid | pids] end)
    :ok
  end

  @spec stop_env(pid()) :: :ok
  def stop_env(pid) do
    pids = Agent.get(pid, & &1)

    pids
    |> Enum.each(fn p ->
      Agent.stop(p)
    end)

    Agent.stop(pid)
  end

  @spec run(Ast.t()) :: {Ovo.Ast.t(), map()}
  def run(ast), do: run(ast, %{})

  @spec run(binary() | Ast.t(), map()) :: {Ovo.Ast.t(), map()}
  def run(code, input) when is_binary(code) do
    tokens = Ovo.Tokenizer.tokenize(code)
    {:ok, ast, _} = Ovo.Parser.parse(tokens)
    run(ast, input)
  end

  def run(ast, input) do
    {:ok, evaluator_pid} = start_link([])

    ovo_input = Ovo.Converter.elixir_to_ovo(input)

    initial_state = Env.make(evaluator_pid) |> Env.bind_input(ovo_input)

    {:ok, env} = Env.start_link(initial_state)

    register_pid(evaluator_pid, env)

    rewritten = Ovo.Rewrites.rewrite(ast)

    {env, v} = evaluate(rewritten, env)

    user_env = Env.get_user_env(env)

    stop_env(evaluator_pid)

    {v, user_env}
  end

  @spec reduce_nodes(list(Ovo.Ast.t()), pid()) :: {Ovo.Ast.t(), map()}
  def reduce_nodes(nodes, env) do
    Enum.reduce(nodes, {env, nil}, fn node, {ev, _lev} ->
      evaluate(node, ev)
    end)
  end

  @spec evaluate(list(Ovo.Ast.t()) | Ovo.Ast.t(), pid()) :: {Ovo.Ast.t(), map()}
  def evaluate(nodes, env) when is_list(nodes), do: reduce_nodes(nodes, env)

  def evaluate(ast, env) when is_tuple(ast) and tuple_size(ast) == 3 do
    {a_kind, a_nodes, a_value} = ast

    res =
      case a_kind do
        :root ->
          evaluate(a_nodes, env)

        :assignment ->
          key = a_value
          {_, _, assi_v} = key
          {_, val} = evaluate(a_nodes, env)
          {Env.update_env(env, assi_v, val), val}

        :block ->
          evaluate(a_nodes, env)

        :condition ->
          [predicate, branch1, branch2] = a_nodes
          {_, val} = evaluate(predicate, env)

          {_, v} =
            case val do
              {:bool, _, true} -> evaluate(branch1, env)
              {:bool, _, false} -> evaluate(branch2, env)
            end

          {env, v}

        :shake ->
          {_env, inner_fn} = evaluate(a_value, env)
          key = :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0..16)

          {env,
           %{
             callable: fn args ->
               res = inner_fn.(args)

               Agent.update(env, fn state ->
                 shake_stack = Map.get(state.shakes, key, [])
                 out = put_in(state, [:shakes, key], [res | shake_stack])
                 out
               end)

               res
             end,
             key: key
           }}

        :lambda ->
          arity = length(a_value)
          program = Ovo.Rewrites.rw(a_nodes)
          user_bindings = Env.user_bindings(env)

          {env,
           fn args ->
             {:ok, captured_env} = Env.fork(env)

             Env.update_captures(env, user_bindings)

             if length(args) != arity do
               {:error, "#{length(args)} argument(s) passed instead of #{arity}"}
             else
               symbols_and_args = Enum.zip(a_value, args)

               env_with_applied_args =
                 Enum.reduce(symbols_and_args, captured_env, fn {sym, arg}, uenv ->
                   {_, _, sv} = sym
                   {_, v} = evaluate(arg, uenv)
                   Env.update_env(uenv, sv, v)
                   uenv
                 end)

               {_, k} = evaluate(program, env_with_applied_args)
               k
             end
           end}

        :call ->
          {_, _, nv} = a_value

          case Env.find_callable(nv, env) do
            {:user, %{callable: fun}} ->
              evaluated_args =
                a_nodes
                |> Enum.map(fn node ->
                  {_, v} = evaluate(node, env)
                  v
                end)

              v = fun.(evaluated_args)
              {env, v}

            {:user, fun} ->
              evaluated_args =
                a_nodes
                |> Enum.map(fn node ->
                  {_, v} = evaluate(node, env)
                  v
                end)

              v = fun.(evaluated_args)
              {env, v}

            {:builtins, fun} ->
              r = fun.(a_nodes, env)
              {env, r}

            {:error, msg} ->
              throw({:error, msg})
          end

        :symbol ->
          {env, Env.find_value(a_value, env)}

        :expr ->
          evaluate(a_value, env)

        :list ->
          {env,
           {
             :list,
             Enum.map(a_nodes, fn n ->
               {_, r} = evaluate(n, env)
               r
             end),
             nil
           }}

        _ ->
          {env, ast}
      end

    case res do
      {_, :error} ->
        throw([ast, env])

      _ ->
        res
    end
  end
end
