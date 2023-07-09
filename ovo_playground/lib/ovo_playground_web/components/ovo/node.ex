defmodule OvoPlaygroundWeb.Components.Ovo.Node do
  use Phoenix.Component
  alias OvoPlaygroundWeb.Components.Ovo.Ast

  defp path_to_string(path), do: Enum.map_join(path |> List.flatten(), ",", & &1)

  defp bg(num) do
    %{
      0 => "bg-slate",
      1 => "bg-slate-100",
      2 => "bg-slate-200",
      3 => "bg-slate-300",
      4 => "bg-slate-400",
      5 => "bg-slate-500",
      6 => "bg-slate-600",
      7 => "bg-slate-700",
      8 => "bg-slate-800",
      9 => "bg-slate-900"
    }
    |> Map.get(num, "")
  end

  defp text(num) do
    %{
      9 => "text-stone",
      8 => "text-stone-100",
      7 => "text-stone-200",
      6 => "text-stone-300",
      5 => "text-stone-400",
      4 => "text-stone-500",
      3 => "text-stone-600",
      2 => "text-stone-700",
      1 => "text-stone-800",
      0 => "text-stone-900"
    }
    |> Map.get(num, "text-stone-100")
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:depth, :integer, required: true)
  attr(:path, :list)

  def show(assigns) do
    ~H"""
    <div class={["ast-node", "ast-node-#{@node.kind}"]}>
     <%= case @node.kind do %>
      <% :root -> %>
        Racine
        <.traverse
          nodes={@node.nodes}
          path={["nodes" | @path]}/>
      <% :float -> %> <.float node={@node} path={@path}/>
      <% :integer -> %> <.integer node={@node} path={@path}/>
      <% :string -> %> <.string node={@node} path={@path}/>
      <% :symbol -> %> <.symbol node={@node} path={@path}/>
      <% :bool -> %> <.bool node={@node} path={@path}/>
      <% :map -> %> <.map node={@node} path={@path} />
      <% :list -> %> <.list node={@node} path={@path}/>
      <% :expr -> %>
        <.show node={@node.value} path={["value" | @path]}/>
      <% :assignment -> %> <.assignment node={@node} path={@path}/>
      <% :block -> %>
        Bloc
        <.traverse nodes={@node.nodes} path={["nodes" | @path]}/>
      <% :condition -> %> <.condition node={@node} path={@path}/>
      <% :lambda -> %> <.lambda node={@node} path={@path}/>
      <% :call -> %> <.call node={@node} path={@path}/>
      <% _ -> %>
    <% end %>
    </div>
    """
  end

  attr(:nodes, :list, required: true)
  attr(:path, :list)

  def traverse(assigns) do
    ~H"""
    <%= for {child, index} <- Enum.with_index(@nodes) do %>
      <.show node={child} path={[index|@path]}/>
    <% end %>
    """
  end

  attr(:name, :string)

  def node_label(assigns) do
    ~H"""
    <div class={["ast-label"]}><%= @name %></div>
    """
  end

  attr(:node, Ovo.Ast, required: true)

  def float(assigns) do
    ~H"""
      <.node_label name="Flottant" />
      <input type="text"
        inputmode="numeric"
        pattern="[0-9.]*"
        value={@node.value}
        phx-keyup={"change_path:#{path_to_string(@path)}"}
        >
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def integer(assigns) do
    ~H"""
      <.node_label name="Entier" />
      <input type="text"
        inputmode="numeric"
        pattern="[0-9]*"
        value={@node.value}
        phx-keyup={"change_path:#{path_to_string(@path)}"}
        >
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def string(assigns) do
    ~H"""
      <.node_label name="Chaîne" />
      <input type="text"
        value={@node.value}
        phx-keyup={"change_path:#{path_to_string(@path)}"}
        >
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def symbol(assigns) do
    ~H"""
    <.node_label name="Symbole" />
    <input type="text"
        value={@node.value}
        phx-keyup={"change_path:#{path_to_string(@path)}"}
        >
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def bool(assigns) do
    ~H"""
    <.node_label name="Booléen" /> <%= @node.value %>
    <input type="checkbox"
        checked={@node.value}
        phx-click={"change_path:#{path_to_string(@path)}"}
      >
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def map(assigns) do
    ~H"""
    <.node_label name="Map" />
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def list(assigns) do
    ~H"""
    <.node_label name="Liste" /> [
      <%= for {node, index} <- Enum.with_index(@node.nodes) do %> <.show node={node} path={[index | ["nodes" | @path]]}/> <%end%>
    ]
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def assignment(assigns) do
    ~H"""
    <.node_label name="Assigner" />
      <%= @node.value.value %> la valeur <.show node={@node.nodes} path={["nodes" | @path]}/>
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def condition(assigns) do
    ~H"""
    <.node_label name="Condition" /> <%= for {node, index} <- Enum.with_index(@node.nodes) do %>
      <.show node={node} path={[index | ["nodes" | @path]]}/>
    <% end %>
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def lambda(assigns) do
    ~H"""
    <.node_label name="Lambda" /> (arguments: <%= for {node, index} <- Enum.with_index(@node.value) do %>
      <.show node={node} path={[index | ["value" | @path]]}/>
    <%end%>)
    <.show node={@node.nodes} path={["nodes" | @path]}/>
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def call(assigns) do
    ~H"""
    <.node_label name={"Appel de #{@node.value.value} avec les arguments"} />
    <%= for {node, index} <- Enum.with_index(@node.nodes) do %>
      <.show node={node} path={[index | @path]}/>
    <%end%>
    """
  end
end
