defmodule MtaClient.Stations.Station do
  use Ecto.Schema
  import Ecto.Changeset
  alias MtaClient.Stations.Station

  @required_fields [
    :daytime_routes,
    :name,
    :gtfs_stop_id,
    :line,
    :mta_station_id
  ]

  schema "stations" do
    field :borough, :string
    field :daytime_routes, {:array, :string}
    field :name, :string
    field :gtfs_stop_id, :string
    field :line, :string
    field :north_direction_label, :string
    field :south_direction_label, :string
    field :mta_station_id, :integer

    timestamps()
  end

  def changeset(%Station{} = station, attrs) do
    station
    |> cast(
      attrs,
      [
        :borough,
        :daytime_routes,
        :name,
        :gtfs_stop_id,
        :line,
        :north_direction_label,
        :south_direction_label,
        :mta_station_id
      ]
    )
    |> validate_required(@required_fields)
  end
end
