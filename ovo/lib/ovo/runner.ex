defmodule Ovo.Runner do
  @type t() :: %{ast: Ovo.Ast.t(), code: binary(), hash: binary(), name: binary()}

  defstruct ast: nil, code: "", hash: "", name: ""

  @moduledoc """
  An ovo Runner holds on an AST and is managed by an Ovo.Registry, holding on a stack of previous results.
  A runner is publicly identified by its hash and internally by its pid.
  """
  require Logger

  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end)
  end

  @spec register(binary(), binary()) :: {:ok, binary()} | {:error, any()}
  def register(code, name, args \\ []) do
    tokens = Ovo.Tokenizer.tokenize(code)
    {:ok, ast, _} = Ovo.Parser.parse(tokens)
    normalized_form = Ovo.Printer.print(ast)
    hash = :crypto.hash(:md5, normalized_form) |> Base.encode64() |> String.slice(0..4)
    Logger.info("Registered program with code #{code} at hash #{hash}")

    case Ovo.Runner.instantiate(ast, code, name, hash, args) do
      {:error, _reason} = e -> e
      :ok -> {:ok, hash}
    end
  end

  def to_positional_args({:list, n, _}), do: to_positional_args(n)

  def to_positional_args(inputs) when is_list(inputs) do
    Enum.with_index(inputs)
    |> Enum.reduce(%{}, fn {v, i}, out ->
      Map.put(out, "arg#{i}", v)
    end)
  end

  def to_positional_args(inputs), do: to_positional_args([inputs])

  @spec run(binary(), list() | Ovo.Ast.t()) :: Ovo.Ast.t()
  def run(hash, input) do
    p_inputs = input |> to_positional_args
    {:ok, pid} = Ovo.Registry.find_runner(hash)
    ast = Agent.get(pid, fn %{ast: a} -> a end)
    {output, last_env} = Ovo.Interpreter.run(ast, p_inputs)
    Ovo.Registry.push_result(hash, output, last_env)
    output
  end

  @spec shake(binary()) :: Ovo.Ast.t()
  def shake(hash) do
    Ovo.Registry.pop_result(hash)
  end

  @spec instantiate(Ovo.Ast.t(), binary(), binary(), binary(), integer()) :: {:ok, pid()}
  def instantiate(ast, code, name, hash, args) do
    Ovo.Registry.wrap_registration(ast, code, name, hash, args)
    :ok
  end
end
