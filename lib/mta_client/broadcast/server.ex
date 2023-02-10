defmodule MtaClient.Broadcast.Server do
  require Logger

  use GenServer

  alias Phoenix.PubSub

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start() do
    GenServer.cast(__MODULE__, :start)
  end

  def stop() do
    GenServer.cast(__MODULE__, :stop)
  end

  ## Callbacks

  @impl true
  def init(_) do
    GenServer.cast(self(), :start)
    {:ok, %{tick: 0, stopped: false}}
  end

  @impl true
  def handle_cast(:start, state) do
    Logger.warning("Broadcast.Server starting...")
    Process.send(self(), :broadcast_upcoming_trips, [])
    {:noreply, %{state | stopped: false}}
  end

  def handle_cast(:stop, state) do
    Logger.warning("Broadcast.Server stopping...")
    {:noreply, %{state | stopped: true}}
  end

  @impl true
  def handle_info(:broadcast_upcoming_trips, %{stopped: true} = state) do
    schedule_broadcast()

    {:noreply, state}
  end

  def handle_info(:broadcast_upcoming_trips, %{tick: tick} = state) do
    broadcast_update()
    schedule_broadcast()
    Logger.info("Broadcast.Server broadcasted upcoming trips...")
    {:noreply, %{state | tick: tick + 1}}
  end

  defp broadcast_update() do
    upcoming_trips = MtaClient.Stations.upcoming_trips_by_station(30)
    PubSub.broadcast(MtaClient.PubSub, "upcoming_trips_update", {:upcoming_trips, upcoming_trips})
  end

  defp schedule_broadcast() do
    Process.send_after(self(), :broadcast_upcoming_trips, 15_000)
  end
end
