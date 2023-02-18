defmodule MtaClient.Trips.TripDestination do
  require Logger

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Multi
  alias MtaClient.Repo
  alias MtaClient.Trips.TripDestination
  alias MtaClient.Stations.Station

  @required_fields [
    :trip_id_string,
    :destination_name,
    :route,
    :direction,
    :service_code
  ]

  @trip_destination_csv Application.compile_env(
                          :mta_client,
                          :trip_destinations_csv_path,
                          "/app/lib/mta_client-0.1.0/priv/static/trip_destinations.csv"
                        )

  schema "trip_destinations" do
    field :trip_id_string, :string
    field :destination_name, :string
    field :route, :string
    field :direction, Ecto.Enum, values: [:north, :south]
    field :service_code, Ecto.Enum, values: [:weekday, :saturday, :sunday]

    timestamps()
  end

  def changeset(%TripDestination{} = trip_destination, attrs) do
    trip_destination
    |> cast(
      attrs,
      @required_fields
    )
    |> validate_required(@required_fields)
    |> unique_constraint([:route, :direction, :service_code],
      name: :trip_destinations_trip_id_string_destination_name_index
    )
  end

  def parse_and_insert_csv(file_path \\ @trip_destination_csv) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    parsed_maps =
      file_path
      |> File.stream!()
      |> CSV.decode(headers: true)
      |> Enum.to_list()
      |> Enum.map(fn
        {:ok, trip_map} -> trip_map
      end)
      |> Enum.uniq_by(&{info_from_trip_id(&1["trip_id"]), csv_trip_id(&1["trip_id"])})
      |> Enum.map(fn %{"trip_id" => trip_id, "trip_headsign" => destination_name} ->
        {route, direction, service_code} = info_from_trip_id(trip_id)

        %{
          trip_id_string: csv_trip_id(trip_id),
          destination_name: destination_name,
          route: route,
          direction: direction,
          service_code: service_code,
          inserted_at: now,
          updated_at: now
        }
      end)

    # transaction times out insert all goes over allocations
    # ... edit i bet it wouldn't anymore with uniquness in parsing
    Enum.map(parsed_maps, fn td ->
      Repo.insert(TripDestination.changeset(%TripDestination{}, td))
    end)
  end

  # returns {route, direction, service_code}
  def info_from_trip_id(trip_id) do
    {route, direction} =
      case String.split(trip_id, "..") do
        [ends_with_route, direction] ->
          direction =
            direction
            |> String.at(0)
            |> parse_direction

          {String.at(ends_with_route, -1), direction}

        single_dot ->
          [ends_with_route, direction] = String.split(trip_id, ".")

          direction =
            direction
            |> String.at(0)
            |> parse_direction

          {String.at(ends_with_route, -1), direction}
      end

    service_code =
      case String.split(trip_id, "-") do
        [_, _, service_code_string, _] ->
          String.downcase(service_code_string)

        [_, _, _, service_code_string, _] ->
          String.downcase(service_code_string)

        _ ->
          Logger.warning("TripDestination.parse cant find service_code #{inspect(trip_id)}")
          nil
      end

    {route, direction, service_code}
  end

  def csv_trip_id(csv_trip_id) do
    [_, _, trip_id_suffix] = String.split(csv_trip_id, "_")

    trip_id_suffix
  end

  defp parse_direction("N"), do: "north"
  defp parse_direction("S"), do: "south"
  defp parse_direction(_), do: nil
end
