defmodule OvoPlayground.Transforms do
  alias Ovo.Ast

  @moduledoc """
  Transforms are functions that ultimately produce an Ovo.Ast,
  either from nothing, some input, an Ast, or combinations of these things.
  """

  @default_code """
  val = arg(0)
  foo = `bar`
  add(val, 10)
  """

  defp produce(input) when is_binary(input) do
    case Ovo.tokenize(input) |> Ovo.parse() do
      {:ok, %{nodes: nodes}, []} -> nodes
      _ -> []
    end
  end

  defp list([a]), do: [a]
  defp list(a), do: [a]
  defp nodes(%Ovo.Ast{nodes: nodes}), do: nodes
  defp concat(a, b), do: list(a) ++ list(b)

  def maybe_rewrap({:ok, %Ovo.Ast{} = ast, []}, fun) do
    {:ok, fun.(ast), []}
  end

  def maybe_rewrap(%Ovo.Ast{} = ast, fun) do
    fun.(ast)
  end

  def wrap_root(nodes) do
    Ast.root(nodes)
  end

  def default() do
    Ovo.tokenize(@default_code) |> Ovo.parse()
  end

  def default_assignment() do
    produce("foo = 5")
  end

  def push_node(arg, node) do
    maybe_rewrap(arg, fn a ->
      %Ovo.Ast{a | nodes: concat(nodes(a), node)}
    end)
  end
end
