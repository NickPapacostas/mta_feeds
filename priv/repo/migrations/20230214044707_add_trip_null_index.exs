defmodule MtaClient.Repo.Migrations.AddTripNullIndex do
  use Ecto.Migration

  def change do
    create unique_index(
      :trips, 
      [:trip_id, :start_date], 
      name: :trips_start_null_index,
      where: "start_time IS NULL"
    )
  end
end
