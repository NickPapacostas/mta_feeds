defmodule MtaClient.Trips.TripDestination do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Multi
  alias MtaClient.Repo
  alias MtaClient.Trips.TripDestination
  alias MtaClient.Stations.Station

  @required_fields [
    :trip_id_string,
    :destination_name
  ]

  @trip_destination_csv Application.compile_env(
                          :mta_client,
                          :trip_destinations_csv_path,
                          "/app/lib/mta_client-0.1.0/priv/static/trip_destinations.csv"
                        )

  schema "trip_destinations" do
    field :trip_id_string, :string
    field :destination_name, :string

    timestamps()
  end

  def changeset(%TripDestination{} = trip_destination, attrs) do
    trip_destination
    |> cast(
      attrs,
      @required_fields
    )
    |> validate_required(@required_fields)
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
      |> Enum.uniq_by(&{csv_trip_id(&1["trip_id"]), &1["trip_headsign"]})
      |> Enum.map(fn %{"trip_id" => trip_id, "trip_headsign" => destination_name} ->
        %{
          trip_id_string: csv_trip_id(trip_id),
          destination_name: destination_name,
          inserted_at: now,
          updated_at: now
        }
      end)

    # transaction times out insert all goes over allocations
    Enum.map(parsed_maps, fn td ->
      Repo.insert(TripDestination.changeset(%TripDestination{}, td))
    end)
  end

  def csv_trip_id(trip_id) do
    [_ | trip_id_parts] = String.split(trip_id, "_")

    Enum.join(trip_id_parts, "_")
  end
end
