defmodule Ovo.Runner do
  @moduledoc """
  An ovo Runner holds on an AST and is managed by an Ovo.Registry, holding on a stack of previous results.
  A runner is publicly identified by its hash and internally by its pid.
  """
  require Logger

  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end)
  end

  def register(code) do
    tokens = Ovo.Tokenizer.tokenize(code)
    {:ok, ast, _} = Ovo.Parser.parse(tokens)
    normalized_form = Ovo.Printer.print(ast)
    hash = :crypto.hash(:sha256, normalized_form) |> Base.encode64() |> String.slice(0..8)
    Logger.info("Registered program at hash #{hash}")

    case Ovo.Registry.find_runner(hash) do
      {:ok, pid} ->
        {:ok, hash}

      {:error, _} ->
        case Ovo.Runner.instantiate(ast, hash) do
          {:error, reason} = e -> e
          {:ok, pid} -> {:ok, hash}
        end
    end
  end

  defp to_positional_args(%Ovo.Ast{kind: :list, nodes: n}), do: to_positional_args(n)

  defp to_positional_args(inputs) do
    Enum.with_index(inputs)
    |> Enum.reduce(%{}, fn {v, i}, out ->
      Map.put(out, "arg#{i}", v)
    end)
  end

  def run(hash, input) do
    p_inputs = input |> to_positional_args
    {:ok, pid} = Ovo.Registry.find_runner(hash)
    ast = Agent.get(pid, fn %{ast: a} -> a end)
    {output, last_env} = Ovo.Interpreter.run(ast, p_inputs)
    Ovo.Registry.push_result(hash, output, last_env)
    output
  end

  def bonk(hash) do
    Ovo.Registry.pop_result(hash)
  end

  def instantiate(ast, hash) do
    {:ok, pid} = start_link(%{ast: ast, hash: hash})
    Ovo.Registry.register_runner(pid, hash)
    {:ok, pid}
  end
end
