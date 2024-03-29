defmodule MtaClient.Feed.Processor do
  require Logger

  alias Ecto.Multi
  alias MtaClient.Feed.Parser
  alias MtaClient.{Trips, TripUpdates}

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

  defp decode_feed(path) do
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
