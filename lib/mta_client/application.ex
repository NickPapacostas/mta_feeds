defmodule MtaClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      MtaClient.Repo,
      # Start the Telemetry supervisor
      MtaClientWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MtaClient.PubSub},
      {Finch, name: MtaFinch},
      # Start the Endpoint (http/https)
      MtaClientWeb.Endpoint
      # Start a worker by calling: MtaClient.Worker.start_link(arg)
      # {MtaClient.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MtaClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MtaClientWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
