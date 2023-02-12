defmodule MtaClient.Trips do
  require Logger

  import Ecto.Query

  alias Ecto.Multi

  alias MtaClient.Repo
  alias MtaClient.Trips.{Trip, TripDestination}

  def build_multis(multi, trip_maps) do
    trip_maps
    |> Enum.uniq_by(& &1.trip_id)
    |> Enum.map(&append_trip_destination_id/1)
    |> Enum.reduce(multi, fn trip_map, acc_multi ->
      changeset = Trip.changeset(%Trip{}, trip_map)

      if changeset.valid? do
        multi_key = {:trip, trip_map.trip_id}

        trip_multi =
          Multi.new()
          |> Multi.insert(multi_key, changeset,
            on_conflict: :nothing,
            conflict_target: [:trip_id, :start_time, :start_date]
          )

        Multi.append(acc_multi, trip_multi)
      else
        Logger.error("invalid: #{inspect(trip_map)}#{inspect(changeset)}")
        acc_multi
      end
    end)
  end

  defp append_trip_destination_id(%{trip_id: trip_id} = trip_map) do
    destination_query =
      from(
        td in TripDestination,
        where: td.trip_id_string == ^trip_id,
        select: td.id
      )

    case Repo.one(destination_query) do
      nil ->
        trip_map

      td_id ->
        Map.put(trip_map, :trip_destination_id, td_id)
    end
  end

  defp append_trip_destination_id(unkown_map) do
    unkown_map
  end
end
