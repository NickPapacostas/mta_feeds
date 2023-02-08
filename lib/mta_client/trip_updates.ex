defmodule MtaClient.TripUpdates do
  require Logger
  import Ecto.Query

  alias Ecto.Multi
  alias MtaClient.Repo

  alias MtaClient.Trips.{Trip, TripUpdate}
  alias MtaClient.Stations.Station

  def build_multis(multi, trip_updates) do
    trip_updates
    |> Enum.group_by(& &1.trip_id)
    |> Enum.reduce(multi, fn {trip_id, update_maps}, acc_multi ->
      latest_trip_with_trip_id =
        Repo.one(
          from(
            t in Trip,
            where: t.trip_id == ^trip_id,
            order_by: [desc: :start_date, desc: :start_time],
            select: t.id,
            limit: 1
          )
        )

      if latest_trip_with_trip_id do
        append_update_multis(acc_multi, latest_trip_with_trip_id, update_maps)
      else
        acc_multi
      end
    end)
  end

  defp append_update_multis(multi, nil, _updates), do: multi

  defp append_update_multis(multi, latest_trip_id, updates) do
    Enum.reduce(updates, multi, fn update, acc_multi ->
      station_gtfs_id = update.stop_id

      station_id =
        Repo.one(
          from(
            s in Station,
            where: s.gtfs_stop_id == ^station_gtfs_id,
            select: s.id
          )
        )

      map_with_station_and_trip =
        update
        |> Map.delete(:stop_id)
        |> Map.put(:trip_id, latest_trip_id)
        |> Map.put(:station_id, station_id)

      changeset = TripUpdate.changeset(%TripUpdate{}, map_with_station_and_trip)

      multi_key = {:trip_update, latest_trip_id, station_id}

      update_already_in_multi? =
        acc_multi.operations
        |> Enum.map(fn {multi_key, _changeset} -> multi_key end)
        |> Enum.member?(multi_key)

      if changeset.valid? && !update_already_in_multi? do
        trip_update_multi =
          Multi.new()
          |> Multi.insert(multi_key, changeset,
            on_conflict: :replace_all,
            conflict_target: [:trip_id, :station_id]
          )

        Multi.append(acc_multi, trip_update_multi)
      else
        acc_multi
      end
    end)
  end
end
