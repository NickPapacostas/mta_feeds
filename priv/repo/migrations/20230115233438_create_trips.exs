defmodule MtaClient.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips) do
      add :trip_id, :string
      add :start_time, :naive_datetime_usec
      add :start_date, :date
      add :route_id, :string
      add :direction, :string
      add :train_id, :string

      timestamps()
    end

    create unique_index(:trips, [:trip_id, :start_time])
  end
end
