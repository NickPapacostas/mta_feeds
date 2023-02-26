defmodule MtaClient.Trips do
  require Logger

  import Ecto.Query

  alias Ecto.Multi

  alias MtaClient.Repo
  alias MtaClient.Trips.{Trip, TripUpdate}

  def without_destination() do
    Repo.all(from(t in Trip, where: is_nil(t.destination)))
  end

  def build_multis(multi, trip_maps) do
    trip_maps
    |> Enum.uniq_by(& &1.trip_id)
    |> Enum.reduce(multi, fn trip_map, acc_multi ->
      changeset = Trip.changeset(%Trip{}, trip_map)

      if changeset.valid? do
        multi_key = {:trip, trip_map.trip_id}

        trip_multi =
          Multi.new()
          |> Multi.insert(multi_key, changeset, on_conflict: :nothing)

        Multi.append(acc_multi, trip_multi)
      else
        Logger.error("invalid: #{inspect(trip_map)}#{inspect(changeset)}")
        acc_multi
      end
    end)
  end

  def populate_destinations() do
    l =
      from(
        t in Trip,
        as: :trips,
        where: is_nil(t.destination),
        inner_lateral_join:
          last_station in subquery(
            from(
              u in TripUpdate,
              where: u.trip_id == parent_as(:trips).id,
              order_by: [desc: u.arrival_time],
              join: s in assoc(u, :station),
              limit: 1,
              select: s.name
            )
          ),
        select: {t, last_station.name}
      )
      |> Repo.all()
      |> Enum.map(fn {trip, name} ->
        # changeset =
        #   if trip.direction == :north do
        #     Trip.changeset(trip, %{destination: north_direction_label})
        #   else
        #     Trip.changeset(trip, %{destination: south_direction_label})
        #   end

        changeset = Trip.changeset(trip, %{destination: name})
        Repo.update(changeset)
      end)
  end

  defp append_destination(trip_with_updates) do
  end
end
