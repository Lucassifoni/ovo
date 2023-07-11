defmodule OvoPlayground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      OvoPlaygroundWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: OvoPlayground.PubSub},
      # Start the Endpoint (http/https)
      OvoPlaygroundWeb.Endpoint,
      {Ovo.Registry, nil}
      # Start a worker by calling: OvoPlayground.Worker.start_link(arg)
      # {OvoPlayground.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OvoPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OvoPlaygroundWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
