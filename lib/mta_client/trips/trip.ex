defmodule MtaClient.Trips.Trip do
  use Ecto.Schema
  import Ecto.Changeset
  alias MtaClient.Trips.{Trip, TripDestination}

  @required_fields [
    :trip_id,
    :start_date,
    :route_id
  ]

  @optional_fields [
    :train_id,
    :direction,
    :start_time,
    :trip_destination_id
  ]

  schema "trips" do
    belongs_to(:trip_destination, TripDestination)
    field :trip_id, :string
    field :start_time, :naive_datetime_usec
    field :start_date, :date
    field :route_id, :string
    field :direction, :string
    field :train_id, :string

    timestamps()
  end

  def changeset(%Trip{} = trip, attrs) do
    trip
    |> cast(
      attrs,
      @required_fields ++ @optional_fields
    )
    |> validate_required(@required_fields)

    # handle index validation
  end
end
