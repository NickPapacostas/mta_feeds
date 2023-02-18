defmodule MtaClient.Repo.Migrations.AddRouteAndDirectionToTripDestination do
  use Ecto.Migration

  def change do
    alter table(:trip_destinations) do
      add :route, :string, null: false
      add :direction, :string, null: false
      add :service_code, :string, null: false
    end
    
    create unique_index(:trip_destinations, [:trip_id_string, :route, :direction, :service_code])
  end
end
