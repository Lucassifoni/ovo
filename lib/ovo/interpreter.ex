defmodule Ovo.Interpreter do
  @moduledoc """
  Basic Ovo Ast interpreter.
  """
  alias Ovo.Ast
  alias Ovo.Env

  def run(ast), do: run(ast, %{}, %{})

  def run(%Ast{} = ast, input, bindings) do
    ovo_input = Ovo.Converter.elixir_to_ovo(input)
    env = Env.make(bindings) |> Env.bind_input(ovo_input)
    {_, v} = evaluate(ast, env)
    v
  end

  def reduce_nodes(nodes, env) do
    Enum.reduce(nodes, {env, nil}, fn node, {ev, _lev} ->
      evaluate(node, ev)
    end)
  end

  def update_env(env, key, val) do
    put_in(env, [:user, key], val)
  end

  def find_callable(name, env) do
    if Map.has_key?(env.user, name) do
      {:user, Map.get(env.user, name)}
    else
      if Map.has_key?(env.builtins, name) do
        {:builtins, Map.get(env.builtins, name)}
      else
        {:error, "Callable not found"}
      end
    end
  end

  def find_value(name, env) do
    if Map.has_key?(env.user, name) do
      Map.get(env.user, name)
    else
      if Map.has_key?(env.builtins, name) do
        Map.get(env.builtins, name)
      else
        {:error, "Symbol does not resolve to a value"}
      end
    end
  end

  def evaluate(nodes, env) when is_list(nodes), do: reduce_nodes(nodes, env)

  def evaluate(%Ovo.Ast{} = ast, env) do
    case ast.kind do
      :root ->
        evaluate(ast.nodes, env)

      :assignment ->
        key = ast.value
        {_, val} = evaluate(ast.nodes, env)
        {update_env(env, key.value, val), val}

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

      :lambda ->
        arity = length(ast.value)
        captured_env = env
        program = ast.nodes

        {env,
         fn args ->
           if length(args) != arity do
             {:error, "#{length(args)} argument(s) passed instead of #{arity}"}
           else
             symbols_and_args = Enum.zip(ast.value, args)

             env_with_applied_args =
               Enum.reduce(symbols_and_args, captured_env, fn {sym, arg}, uenv ->
                 {_, v} = evaluate(arg, uenv)
                 update_env(uenv, sym.value, v)
               end)

             {_, k} = evaluate(program, env_with_applied_args)
             k
           end
         end}

      :call ->
        case find_callable(ast.value.value, env) do
          {:user, fun} ->
            v = fun.(ast.nodes)
            {env, v}

          {:builtins, fun} ->
            r = fun.(ast.nodes, env)
            {env, r}

          {:error, msg} ->
            throw({:error, msg})
        end

      :symbol ->
        {env, find_value(ast.value, env)}

      :expr ->
        evaluate(ast.value, env)

      _ ->
        {env, ast}
    end
  end
end
