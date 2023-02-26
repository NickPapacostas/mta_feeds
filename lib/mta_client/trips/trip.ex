defmodule MtaClient.Trips.Trip do
  use Ecto.Schema
  import Ecto.Changeset
  alias MtaClient.Trips.{Trip, TripUpdate}

  @required_fields [
    :trip_id,
    :start_date,
    :route_id
  ]

  @optional_fields [
    :train_id,
    :destination,
    :direction,
    :start_time
  ]

  schema "trips" do
    field :trip_id, :string
    field :destination, :string
    field :start_time, :naive_datetime_usec
    field :start_date, :date
    field :route_id, :string
    field :direction, Ecto.Enum, values: [:north, :south]
    field :train_id, :string

    has_many(:trip_updates, TripUpdate)
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
