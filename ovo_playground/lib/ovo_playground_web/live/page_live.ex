require Protocol
Protocol.derive(Jason.Encoder, Ovo.Ast, only: [:kind, :nodes, :value])

defmodule OvoPlaygroundWeb.PageLive do
  alias Ovo.Printer
  alias OvoPlayground.Transforms
  use OvoPlaygroundWeb, :live_view

  alias OvoPlaygroundWeb.Components.Ovo.Node



  def initial_runner_state do
    ast = Transforms.default()
    code = Printer.print(ast)
    %{
      code: code,
      args: [],
      ast: ast
    }
  end

  def get_ast(socket) do
    socket.assigns[:pending_runner].ast
  end

  def update_from_ast(socket, ast) do
    new_runner = socket.assigns[:pending_runner]
      |> Map.put(:code, Ovo.Printer.print(ast))
      |> Map.put(:ast, ast)
    socket |> assign(:pending_runner, new_runner)
  end

  def update_from_code(socket, code) do
    new_runner = socket.assigns[:pending_runner]
    |> Map.put(:code, code)
    |> Map.put(:ast, Ovo.Tokenizer.tokenize(code) |> Ovo.Parser.parse)
    socket |> assign(:pending_runner, new_runner)
  end

  def mount(_params, _, socket) do
    {:ok,
     assign(socket,
       pending_runner: initial_runner_state(),
       result: nil,
       runners: Ovo.Registry.runners(),
       state: :idle,
       pending_chain: [],
       chains: []
     )}
  end

  def update_runners(socket) do
    socket |> assign(runners: Ovo.Registry.runners())
  end

  def transition_to(socket, state) do
    socket |> assign(state: state)
  end

  def make_chain(chain) do
    first = List.first(chain)
    args = Ovo.Registry.get_runner_args(first)

    %{
      args: args,
      chain: chain
    }
  end

  def handle_event("chain", %{"hash" => hash}, socket) do
    {:noreply, assign(socket, :pending_chain, socket.assigns[:pending_chain] ++ [hash])}
  end

  def handle_event("validate_chain", _, socket) do
    {:noreply,
     assign(socket,
       chains: [make_chain(socket.assigns[:pending_chain]) | socket.assigns[:chains]],
       pending_chain: []
     )}
  end

  def handle_event(
        "update_chain_arg",
        %{
          "value" => value,
          "chain_index" => index,
          "arg_index" => aindex
        },
        socket
      ) do
    inti = String.to_integer(index)
    intai = String.to_integer(aindex)

    if socket.assigns.chains == [] do
      {:noreply, socket}
    else
      chain =
        update_in(socket.assigns.chains, [Access.at!(inti), :args, Access.at!(intai)], fn _ ->
          value
        end)

      {:noreply, socket |> assign(:chains, chain)}
    end
  end

  def handle_event("run_chain", %{"chain_index" => index}, socket) do
    aindex = String.to_integer(index)
    c = socket.assigns.chains |> Enum.at(aindex)
    args = c.args |> Enum.map(&Jason.decode!(&1))

    {:noreply,
     assign(
       socket,
       :result,
       Ovo.Registry.run_chain(c.chain, args)
     )
     |> update_runners}
  end

  def handle_event("push_node", _, socket) do
    ast = Transforms.push_node(get_ast(socket), Transforms.default_assignment)
    {:noreply, update_from_ast(socket, ast)}
  end

  def handle_event("code_change", %{"value" => value}, socket) do
    {:noreply,
     assign(socket,
       pending_runner: %{
         socket.assigns[:pending_runner]
         | code: value,
           ast: Ovo.tokenize(value) |> Ovo.parse()
       }
     )}
  end

  def handle_event("cancel", _, socket) do
    {:noreply, socket |> transition_to(:idle)}
  end

  def handle_event("run_runner", %{"hash" => hash}, socket) do
    result =
      Ovo.Runner.run(
        hash,
        Ovo.Registry.get_runner_args(hash)
        |> Enum.map(&Jason.decode!/1)
      )

    {:noreply, socket |> update_runners |> assign(:result, result)}
  end

  def handle_event("shake_runner", %{"hash" => hash}, socket) do
    value = Ovo.Runner.shake(hash)
    {:noreply, socket |> update_runners |> assign(:result, value)}
  end

  def handle_event("create_runner", _, socket) do
    {:noreply,
     socket
     |> transition_to(:create_runner)
     |> assign(:pending_runner, initial_runner_state())}
  end

  def handle_event(
        "change_runner_arg",
        %{
          "hash" => hash,
          "index" => index,
          "value" => value
        },
        socket
      ) do
    inti = String.to_integer(index)
    Ovo.Registry.update_runner_arg(hash, inti, value)
    {:noreply, socket}
  end

  def handle_event("add_arg", _, socket) do
    {:noreply,
     assign(socket,
       pending_runner: %{
         socket.assigns[:pending_runner]
         | args: ["" | socket.assigns[:pending_runner].args]
       }
     )}
  end

  def handle_event("change_arg", %{"index" => i, "value" => v}, socket) do
    inti = i |> String.to_integer()

    {:noreply,
     assign(socket,
       pending_runner: %{
         socket.assigns[:pending_runner]
         | args:
             Enum.with_index(socket.assigns[:pending_runner].args)
             |> Enum.map(fn {a, ix} -> if ix == inti, do: v, else: a end)
       }
     )}
  end

  def handle_event("delete_arg", %{"index" => i}, socket) do
    inti = i |> String.to_integer()

    {:noreply,
     assign(socket,
       pending_runner: %{
         socket.assigns[:pending_runner]
         | args:
             Enum.with_index(socket.assigns[:pending_runner].args)
             |> Enum.filter(fn {a, ix} -> ix != inti end)
             |> Enum.map(&elem(&1, 0))
       }
     )}
  end

  def handle_event("register", _, socket) do
    code = socket.assigns[:pending_runner].code
    args = socket.assigns[:pending_runner].args

    case Ovo.Runner.register(code, args) do
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
    ast = socket.assigns[:pending_runner].ast |> elem(1)
    path = string_to_path(rest)
    try do
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
       |> assign(:pending_runner, %{
         socket.assigns[:pending_runner]
         | ast: {:ok, ast, []},
           code: Ovo.Printer.print(ast)
       })}
    rescue
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("evaluate", _, socket) do
    parsed = Ovo.tokenize(socket.assigns[:pending_runner].code) |> Ovo.parse()

    args =
      socket.assigns[:pending_runner].args
      |> Enum.map(&Jason.decode!/1)

    case parsed do
      {:ok, ast, _} ->
        try do
          {result, _} = Ovo.Interpreter.run(ast, Ovo.Runner.to_positional_args(args))
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

  attr(:label, :string)
  attr(:click, :string)

  def blue_button(assigns) do
    ~H"""
    <button
      phx-click={@click}
      class="bg-slate-700 text-slate-100 px-2 py-1 mt-1 text-base rounded hover:bg-slate-500 transition-colors"
    >
      <%= @label %>
    </button>
    """
  end
end
