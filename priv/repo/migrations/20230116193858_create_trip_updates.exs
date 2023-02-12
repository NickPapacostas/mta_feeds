defmodule MtaClient.Repo.Migrations.CreateTripUpdates do
  use Ecto.Migration

  def change do
    create table(:trip_updates) do
      add :trip_id, references(:trips), null: false
      add :station_id, references(:stations)
      add :arrival_time, :naive_datetime_usec
      add :departure_time, :naive_datetime_usec

      timestamps()
    end

    create unique_index(:trip_updates, [:trip_id, :station_id])
    create index(:trip_updates, [:trip_id])
    create index(:trip_updates, [:station_id])
  end
end
