defmodule MtaClient.Feed.Server do
  require Logger

  use GenServer

  alias MtaClient.Feed.Processor
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
    # Process.send(self(), :process_feed, [])
    {:ok, %{tick: 0, stopped: false}}
  end

  @impl true
  def handle_cast(:start, state) do
    Logger.warning("Feed.Server starting...")
    Process.send(self(), :process_feed, [])
    {:noreply, %{state | stopped: false}}
  end

  def handle_cast(:stop, state) do
    Logger.warning("Feed.Server stopping...")
    {:noreply, %{state | stopped: true}}
  end

  @impl true
  def handle_info(:process_feed, %{stopped: true} = state) do
    schedule_feed_processing()

    {:noreply, state}
  end

  def handle_info(:process_feed, %{tick: tick} = state) do
    Processor.process_feeds()
    broadcast_update()
    schedule_feed_processing()
    Logger.info("Feed.Server processed feeds...")
    {:noreply, %{state | tick: tick + 1}}
  end

  defp broadcast_update() do
    upcoming_trips = MtaClient.Stations.upcoming_trips_by_station(10)
    PubSub.broadcast(MtaClient.PubSub, "upcoming_trips_update", {:upcoming_trips, upcoming_trips})
  end

  defp schedule_feed_processing() do
    Process.send_after(self(), :process_feed, 60_000)
  end
end
