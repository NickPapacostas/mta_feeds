defmodule MtaClient.Repo.Migrations.CreateTripDestinations do
  use Ecto.Migration

  def change do
    create table(:trip_destinations) do
      add :trip_id_string, :string, null: false
      add :destination_name, :string, null: false

      timestamps()
    end

    create index(:trip_destinations, :trip_id_string)
  end
end
