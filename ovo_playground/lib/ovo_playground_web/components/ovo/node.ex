defmodule OvoPlaygroundWeb.Components.Ovo.Node do
  use Phoenix.Component
  alias OvoPlaygroundWeb.Components.Ovo.Ast
  import OvoPlaygroundWeb.CoreComponents, only: [icon: 1]
  defp path_to_string(path), do: Enum.map_join(path |> List.flatten(), ",", & &1)

  attr(:node, Ovo.Ast, required: true)
  attr(:depth, :integer, required: true)
  attr(:path, :list)

  def show_node(assigns) do
    ~H"""
    <div class={["border border-black ast-node", "ast-node-#{@node.kind}"]}>
      <%= Jason.encode!(@path) %>
      <%= case @node.kind do %>
        <% :root -> %>
         <.traverse nodes={@node.nodes} path={["nodes" | @path]} />
        <% :float -> %>
          <.float node={@node} path={@path} />
        <% :integer -> %>
          <.integer node={@node} path={@path} />
        <% :string -> %>
          <.string node={@node} path={@path} />
        <% :symbol -> %>
          <.symbol node={@node} path={@path} />
        <% :bool -> %>
          <.bool node={@node} path={@path} />
        <% :map -> %>
          <.map node={@node} path={@path} />
        <% :list -> %>
          <.list node={@node} path={@path} />
        <% :expr -> %>
          <.show_node node={@node.value} path={["value" | @path]} />
        <% :assignment -> %>
          <.assignment node={@node} path={@path} />
        <% :block -> %>
           <.traverse nodes={@node.nodes} path={["nodes" | @path]} />
        <% :condition -> %>
          <.condition node={@node} path={@path} />
        <% :lambda -> %>
          <.lambda node={@node} path={@path} />
        <% :call -> %>
          <.call node={@node} path={@path} />
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
      <.show_node node={child} path={[index | @path]} />
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
    <.node_label name="Float" />
    <input
      type="text"
      inputmode="numeric"
      pattern="[0-9.]*"
      value={@node.value}
      phx-keyup={"change_path:#{path_to_string(@path)}"}
    />
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def integer(assigns) do
    ~H"""
    <.node_label name="Integer" />
    <input
      type="text"
      inputmode="numeric"
      pattern="[0-9]*"
      value={@node.value}
      phx-keyup={"change_path:#{path_to_string(@path)}"}
    />
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def string(assigns) do
    ~H"""
    <.node_label name="String" />
    <%= if String.length(@node.value) > 50 do %>
      <textarea style="min-height: 100px"><%= @node.value %></textarea>
    <% else %>
      <input type="text" value={@node.value} phx-keyup={"change_path:#{path_to_string(@path)}"} />
    <% end %>
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def symbol(assigns) do
    ~H"""
    <.node_label name="Symbol" />
    <input type="text" value={@node.value} phx-keyup={"change_path:#{path_to_string(@path)}"} />
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def bool(assigns) do
    ~H"""
    <.node_label name="Boolean" /> <%= @node.value %>
    <input type="checkbox" checked={@node.value} phx-click={"change_path:#{path_to_string(@path)}"} />
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
    <.node_label name="List" /> [
    <%= for {node, index} <- Enum.with_index(@node.nodes) do %>
      <.show_node node={node} path={[index | ["nodes" | @path]]} />
    <% end %>
    ]
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def assignment(assigns) do
    ~H"""
    <.node_label name="Assign"/>
    <input
      type="text"
      value={@node.value.value}
      phx-keyup={"change_path:#{path_to_string(["value" | @path])}"}
    />
    <.icon name="hero-pause-circle-solid rotate-90" class="h-5 w-5" />
    <.show_node node={@node.nodes} path={["nodes" | @path]} />
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def condition(assigns) do
    ~H"""
    <.node_label name="Condition" />
    <%= for {node, index} <- Enum.with_index(@node.nodes) do %>
      <.show_node node={node} path={[index | ["nodes" | @path]]} />
    <% end %>
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def lambda(assigns) do
    ~H"""
    <.node_label name="Lambda" /> (arguments:
    <%= for {node, index} <- Enum.with_index(@node.value) do %>
      <.show_node node={node} path={[index | ["value" | @path]]} />
    <% end %>) <.show_node node={@node.nodes} path={["nodes" | @path]} />
    """
  end

  attr(:node, Ovo.Ast, required: true)
  attr(:path, :list)

  def call(assigns) do
    ~H"""
    <.node_label name={"Call #{@node.value.value}"} />
    <%= for {node, index} <- Enum.with_index(@node.nodes) do %>
      <.show_node node={node} path={[index | ["nodes" | @path]]} />
    <% end %>
    """
  end
end
