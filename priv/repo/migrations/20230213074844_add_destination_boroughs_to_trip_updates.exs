defmodule MtaClient.Repo.Migrations.AddDestinationBoroughsToTripUpdates do
  use Ecto.Migration

  def change do
    alter table(:trip_updates) do
      add :destination_boroughs, {:array, :string}
    end
  end
end
