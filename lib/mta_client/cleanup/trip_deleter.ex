defmodule MtaClient.Cleanup.TripDeleter do
  require Logger

  import Ecto.Query

  alias MtaClient.Trips.{Trip, TripUpdate}
  alias MtaClient.Repo

  @days_threshold 2

  def delete_old_trips() do
    two_days_ago =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-@days_threshold, :day)
      |> NaiveDateTime.to_date()

    trip_updates_query =
      from(
        tu in TripUpdate,
        join: t in assoc(tu, :trip),
        where: t.start_date < ^two_days_ago
      )

    trips_query =
      from(
        t in Trip,
        where: t.start_date < ^two_days_ago
      )

    result =
      Repo.transaction(fn ->
        {
          Repo.delete_all(trip_updates_query),
          Repo.delete_all(trips_query)
        }
      end)

    vacuum_result = Ecto.Adapters.SQL.query!(MtaClient.Repo, "VACUUM FULL")

    Logger.info("Cleanup.TripDeleter result: #{inspect(result)}, #{inspect(vacuum_result)}")
    result
  end
end
