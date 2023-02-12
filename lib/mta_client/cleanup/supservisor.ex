defmodule MtaClient.Cleanup.Supervisor do
  use Supervisor

  def start_link(args), do: Supervisor.start_link(__MODULE__, args)

  @impl true
  def init(_args) do
    Supervisor.init(children(), strategy: :one_for_one, name: MtaClient.Cleanup.Supervisor)
  end

  def children() do
    [
      {MtaClient.Cleanup.Server, []}
    ]
  end
end
