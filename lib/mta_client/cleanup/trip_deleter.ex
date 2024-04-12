defmodule MtaClient.Cleanup.TripDeleter do
  require Logger

  import Ecto.Query

  alias MtaClient.Trips.{Trip, TripUpdate}
  alias MtaClient.Repo

  @delete_after_threshold_seconds 12 * 60 * 60

  def delete_old_trips() do
    twelve_hours_ago =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-@delete_after_threshold_seconds, :second)

    trip_updates_query =
      from(
        tu in TripUpdate,
        join: t in assoc(tu, :trip),
        where: t.inserted_at <= ^twelve_hours_ago
      )

    trips_query =
      from(
        t in Trip,
        where: t.inserted_at < ^twelve_hours_ago
      )

    result = {
      Repo.delete_all(trip_updates_query),
      Repo.delete_all(trips_query)
    }

    vacuum_result = Ecto.Adapters.SQL.query!(MtaClient.Repo, "VACUUM FULL")

    Logger.info("Cleanup.TripDeleter result: #{inspect(result)}, #{inspect(vacuum_result)}")

    :ok
  end
end
