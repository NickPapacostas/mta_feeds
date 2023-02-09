defmodule MtaClient.Repo.Migrations.AddDestinationIdToTrips do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :trip_destination_id, references(:trip_destinations)
    end
  end
end
