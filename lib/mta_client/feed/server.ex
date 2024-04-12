defmodule MtaClient.Feed.Server do
  require Logger

  use GenServer

  alias MtaClient.Feed.Processor
  alias MtaClient.TripUpdates
  alias Phoenix.PubSub

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start() do
    GenServer.call(__MODULE__, :start)
  end

  def stop(timeout \\ 10_000) do
    GenServer.call(__MODULE__, :stop, timeout)
  end

  ## Callbacks

  @impl true
  def init(_) do
    Logger.warning("Feed.Server starting...")
    Process.send(self(), :process_feed, [])
    {:ok, %{tick: 0, stopped: false}}
  end

  @impl true
  def handle_call(:start, _from,  state) do
    Logger.warning("Feed.Server starting...")
    {:reply, :ok, %{state | stopped: false}}
  end

  def handle_call(:stop, _from,  state) do
    Logger.warning("Feed.Server stopping...")
    {:reply, :ok, %{state | stopped: true}}
  end

  @impl true
  def handle_info(:process_feed, %{stopped: true} = state) do
    schedule_feed_processing()

    {:noreply, state}
  end

  def handle_info(:process_feed, %{tick: tick} = state) do
    Processor.process_feeds_v2()
    # TripUpdates.populate_destination_boroughs(120)
    schedule_feed_processing()
    Logger.info("Feed.Server processed feeds...")
    {:noreply, %{state | tick: tick + 1}}
  end

  defp schedule_feed_processing() do
    Process.send_after(self(), :process_feed, 60_000)
  end
end
