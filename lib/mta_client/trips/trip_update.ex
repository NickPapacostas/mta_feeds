defmodule MtaClient.Trips.TripUpdate do
  use Ecto.Schema
  import Ecto.Changeset
  alias MtaClient.Trips.{Trip, TripUpdate}
  alias MtaClient.Stations.Station

  @required_fields [
    :trip_id,
    # for now ignore updates for unknown stations
    # https://www.patrickweaver.net/blog/making-a-real-time-nyc-subway-map-with-real-weird-nyc-subway-data/
    :station_id,
    :arrival_time,
    :departure_time
  ]

  schema "trip_updates" do
    belongs_to(:trip, Trip)
    belongs_to(:station, Station)
    field :arrival_time, :naive_datetime_usec
    field :departure_time, :naive_datetime_usec

    timestamps()
  end

  def changeset(%TripUpdate{} = trip, attrs) do
    trip
    |> cast(
      attrs,
      @required_fields
    )
    |> validate_required(@required_fields)
  end
end
