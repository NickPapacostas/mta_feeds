defmodule MtaClient.Repo.Migrations.CreateTrains do
  use Ecto.Migration

  def change do
    create table(:trains) do
      add :train_id, :string, null: false
      add :current_status, :string

      timestamps()
    end

    create unique_index(:trains, [:train_id])
  end
end
