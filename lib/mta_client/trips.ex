defmodule MtaClient.Trips do
  require Logger

  alias Ecto.Multi

  alias MtaClient.Trips.Trip

  def build_multis(multi, trip_maps) do
    trip_maps
    |> Enum.uniq_by(& &1.trip_id)
    |> Enum.reduce(multi, fn trip_map, acc_multi ->
      changeset = Trip.changeset(%Trip{}, trip_map)

      if changeset.valid? do
        multi_key = {:trip, trip_map.trip_id}

        trip_multi =
          Multi.new()
          |> Multi.insert(multi_key, changeset,
            on_conflict: {:replace, [:direction]},
            conflict_target: [:trip_id, :start_time]
          )

        Multi.append(acc_multi, trip_multi)
      else
        Logger.error("invalid: #{inspect(trip_map)}#{inspect(changeset)}")
        acc_multi
      end
    end)
  end
end
