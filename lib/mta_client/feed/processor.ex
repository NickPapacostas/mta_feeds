defmodule MtaClient.Feed.Processor do
  require Logger

  import Ecto.Query
  alias Ecto.Multi
  alias MtaClient.Repo
  alias MtaClient.Feed.Parser
  alias MtaClient.Trips
  alias MtaClient.Trips.Trip
  alias MtaClient.TripUpdates
  alias MtaClient.Stations.Station

  @api_endpoint "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/"
  @yellow_lines_path "nyct%2Fgtfs-nqrw"
  @blue_lines_path "nyct%2Fgtfs-ace"
  @g_path "nyct%2Fgtfs-g"
  @orange_lines_path "nyct%2Fgtfs-bdfm"
  @brown_lines_path "nyct%2Fgtfs-jz"
  @grey_lines_path "nyct%2Fgtfs-l"
  @manhattan_lines_path "nyct%2Fgtfs"

  def all_line_paths() do
    [
      @yellow_lines_path,
      @blue_lines_path,
      @g_path,
      @orange_lines_path,
      @brown_lines_path,
      @grey_lines_path,
      @manhattan_lines_path
    ]
  end

  def process_feeds() do
    all_line_paths()
    |> Enum.map(&process_feed/1)
    |> Enum.flat_map(fn x -> x end)
    |> Enum.group_by(fn {k, _v} -> k end)
  end

  def process_feeds_v2() do
    all_line_paths()
    |> Enum.map(&process_feed_v2/1)

    Trips.populate_destinations()
  end

  def process_feed_v2(path) do
    Logger.info("Processor processing v2 #{path}...")

    with {:ok, decoded_feed} <- decode_feed(path),
         trips_with_updates <- Parser.parse_feed_entities_v2(decoded_feed.entity) do
      station_gtfs_id_to_id =
        Repo.all(
          from(
            s in Station,
            select: {s.gtfs_stop_id, s.id}
          )
        )
        |> Enum.into(%{})

      insert_results =
        Enum.map(trips_with_updates, fn {trip, updates} ->
          case Trips.insert(trip) do
            {:ok, %Trip{id: trip_id}} ->
              TripUpdates.insert_for_trip(trip_id, updates, station_gtfs_id_to_id)

            error ->
              error
          end
        end)

      trips_with_updates
      |> Enum.map(fn {trip, _updates} -> trip end)
      |> Trips.delete_removed_upcoming_trips()

      Logger.info("Processed v2 #{path}: #{length(insert_results)}")

      insert_results
    end
  end

  def process_feed(path) do
    with {:ok, decoded_feed} <- decode_feed(path),
         # determine feed processed already?
         %{trips: trips, trip_updates: updates} = result <-
           Parser.parse_feed_entities(decoded_feed.entity) do
      Logger.info("Processor processing #{path}...")

      Multi.new()
      |> Trips.build_multis(trips)
      |> MtaClient.Repo.transaction()

      Multi.new()
      |> TripUpdates.build_multis(updates)
      |> MtaClient.Repo.transaction()

      Trips.delete_removed_upcoming_trips(trips)

      Trips.populate_destinations()

      result
    else
      error ->
        Logger.error("Feed.Processor error processing #{path} #{inspect(error)}")
        {:error, error}
    end
  end

  def decode_feed(path) do
    r =
      Finch.build(:get, @api_endpoint <> path, [
        {"x-api-key", api_key()}
      ])

    case Finch.request(r, MtaFinch) do
      {:ok, %{body: body}} ->
        Protox.decode(body, TransitRealtime.FeedMessage)

      error ->
        {:error, error}
    end
  end

  defp api_key(), do: Application.get_env(:mta_client, :mta_api_key)
end
