require Protocol
Protocol.derive(Jason.Encoder, Ovo.Ast, only: [:kind, :nodes, :value])

defmodule OvoPlaygroundWeb.PageLive do
  use OvoPlaygroundWeb, :live_view

  alias OvoPlaygroundWeb.Components.Ovo.Node

  @code """
  radd = 5
  foo = `bar`
  """

  def mount(_params, _, socket) do
    parsed = Ovo.tokenize(@code) |> Ovo.parse()
    {:ok, assign(socket, code: @code, ast: parsed, result: nil)}
  end

  def handle_event("code_change", %{"value" => value}, socket) do
    {:noreply, assign(socket, code: value, ast: Ovo.tokenize(value) |> Ovo.parse(), result: nil)}
  end

  defp string_to_path(str) do
    String.split(str, ~r/,/)
    |> Enum.map(fn term ->
      case term do
        "value" -> Access.key!(:value)
        "nodes" -> Access.key!(:nodes)
        a -> Access.at!(String.to_integer(a))
      end
    end)
    |> Enum.reverse()
  end

  def node_at_path(ast, [:value | rest]), do: node_at_path(ast.value, rest)
  def node_at_path(ast, [:nodes | rest]), do: node_at_path(ast.nodes, rest)
  def node_at_path(ast, [p | rest]), do: node_at_path(ast |> Enum.at(p), rest)
  def node_at_path(ast, []), do: ast

  def handle_event("change_path:" <> rest, params, socket) do
    value = Map.get(params, "value", nil)
    ast = socket.assigns.ast |> elem(1)
    path = string_to_path(rest)
    node = get_in(ast, path)

    new_value =
      case node do
        %Ovo.Ast{kind: :boolean} -> value
        %Ovo.Ast{kind: :integer} -> String.to_integer(value)
        %Ovo.Ast{kind: :float} -> Float.parse(value)
        %Ovo.Ast{kind: :bool} -> !node.value
        _ -> value
      end

    ast = update_in(ast, string_to_path(rest), fn a -> %Ovo.Ast{a | value: new_value} end)

    {:noreply,
     socket
     |> assign(:ast, {:ok, ast, []})
     |> assign(:code, Ovo.Printer.print(ast))}
  end

  def handle_event("evaluate", _, socket) do
    parsed = Ovo.tokenize(socket.assigns.code) |> Ovo.parse()

    case parsed do
      {:ok, ast, _} ->
        try do
          {result, _} = Ovo.Interpreter.run(ast)
          {:noreply, assign(socket, result: result)}
        rescue
          _ -> {:noreply, assign(socket, result: :error)}
        end

      _ ->
        {:noreply, assign(socket, result: :error)}
    end
  end

  def handle_event(_, e, socket) do
    {:noreply, socket}
  end
end
