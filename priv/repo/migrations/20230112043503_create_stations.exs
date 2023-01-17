defmodule MtaClient.Repo.Migrations.CreateStations do
  use Ecto.Migration

  def change do
    create table(:stations) do
      add :borough, :string
      add :daytime_routes, {:array, :string}
      add :name, :string
      add :gtfs_stop_id, :string
      add :line, :string
      add :north_direction_label, :string
      add :south_direction_label, :string
      add :mta_station_id, :integer

      timestamps()
    end

    create unique_index(:stations, [:gtfs_stop_id])
  end
end
