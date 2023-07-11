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

    {:ok,
     assign(socket,
       code: @code,
       ast: parsed,
       result: nil,
       runners: Ovo.Registry.runners(),
       state: :create_runner
     )}
  end

  def update_runners(socket) do
    socket |> assign(runners: Ovo.Registry.runners())
  end

  def transition_to(socket, state) do
    socket |> assign(state: state)
  end

  def handle_event("code_change", %{"value" => value}, socket) do
    {:noreply, assign(socket, code: value, ast: Ovo.tokenize(value) |> Ovo.parse(), result: nil)}
  end

  def handle_event("cancel", _, socket) do
    {:noreply, socket |> transition_to(:idle)}
  end

  def handle_event("run_runner", %{"hash" => hash}, socket) do
    Ovo.Runner.run(hash, [])
    {:noreply, socket |> update_runners}
  end

  def handle_event("bonk_runner", %{"hash" => hash}, socket) do
    Ovo.Runner.bonk(hash)
    {:noreply, socket |> update_runners}
  end

  def handle_event("create_runner", _, socket) do
    {:noreply, socket |> transition_to(:create_runner)}
  end

  def handle_event("register", _, socket) do
    code = socket.assigns[:code]

    case Ovo.Runner.register(code) do
      {:ok, hash} ->
        {:noreply,
         socket
         |> transition_to(:idle)
         |> update_runners()}

      _ ->
        {:noreply, socket}
    end
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
