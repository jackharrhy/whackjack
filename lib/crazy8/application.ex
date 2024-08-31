defmodule Crazy8.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
      Crazy8Web.Telemetry,
      {DNSCluster, query: Application.get_env(:crazy8, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Crazy8.PubSub},
      # Start a worker by calling: Crazy8.Worker.start_link(arg)
      # {Crazy8.Worker, arg},
      # Start to serve requests, typically the last entry
      Crazy8Web.Endpoint,
      Crazy8.GameSupervisor,
      {Registry, keys: :unique, name: Crazy8.GameRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crazy8.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Crazy8Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
