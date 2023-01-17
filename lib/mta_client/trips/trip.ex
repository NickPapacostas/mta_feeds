defmodule MtaClient.Trips.Trip do
  use Ecto.Schema
  import Ecto.Changeset
  alias MtaClient.Trips.Trip

  @required_fields [
    :trip_id,
    :start_time,
    :start_date,
    :route_id
  ]

  schema "trips" do
    field :trip_id, :string
    field :start_time, :naive_datetime_usec
    field :start_date, :date
    field :route_id, :string
    field :direction, :string

    timestamps()
  end

  def changeset(%Trip{} = trip, attrs) do
    trip
    |> cast(
      attrs,
      @required_fields
    )
    |> validate_required(@required_fields)
  end
end
