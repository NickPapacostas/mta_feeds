defmodule MtaClient.Cleanup.Server do
  require Logger

  use GenServer

  alias MtaClient.Cleanup.TripDeleter

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
    Logger.warning("Cleanup.Server starting...")
    Process.send(self(), :cleanup, [])
    {:noreply, %{state | stopped: false}}
  end

  def handle_cast(:stop, state) do
    Logger.warning("Cleanup.Server stopping...")
    {:noreply, %{state | stopped: true}}
  end

  @impl true
  def handle_info(:cleanup, %{stopped: true} = state) do
    TripDeleter.delete_old_trips()
    schedule_cleanup()

    {:noreply, state}
  end

  def handle_info(:cleanup, %{tick: tick} = state) do
    MtaClient.Feed.Server.stop(:infinity)
    TripDeleter.delete_old_trips()
    MtaClient.Feed.Server.start()

    schedule_cleanup()
    {:noreply, %{state | tick: tick + 1}}
  end

  defp schedule_cleanup() do
    six_hours_in_milliseconds = 6 * 60 * 60 * 1000
    Process.send_after(self(), :cleanup, six_hours_in_milliseconds)
  end
end
