defmodule MtaClient.Trips do
  require Logger

  import Ecto.Query

  alias Ecto.Multi

  alias MtaClient.Repo
  alias MtaClient.Trips.{Trip, TripUpdate}

  def without_destination() do
    Repo.all(from(t in Trip, where: is_nil(t.destination)))
  end

  def insert(raw_trip) do
    changeset = Trip.changeset(%Trip{}, raw_trip)

    result =
      Repo.insert(
        changeset,
        # ensures we get back the db record with an id
        on_conflict: {:replace, [:updated_at]},
        conflict_target: [:trip_id, :start_date, :start_time],
        returning: true
      )

    case result do
      {:ok, trip} ->
        {:ok, trip}

      {:error, %{errors: errors}} ->
        handle_null_start_time_constraint_error(errors, raw_trip)
    end
  end

  defp handle_null_start_time_constraint_error(errors, %{trip_id: trip_id, start_date: start_date}) do
    case Keyword.get(errors, :start_time) do
      nil ->
        {:error, errors}

      _ ->
        Repo.one(
          from(
            t in Trip,
            where: t.start_date == ^start_date,
            where: t.trip_id == ^trip_id
          )
        )
    end
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
        changeset = Trip.changeset(trip, %{destination: name})
        Repo.update(changeset)
      end)
  end

  def delete_removed_upcoming_trips(recent_trips_payload) do
    now = NaiveDateTime.utc_now()
    look_ahead_threshold = NaiveDateTime.add(now, 60, :minute)
    ongoing_trip_ids = Enum.map(recent_trips_payload, & &1.trip_id)
    relevant_routes = Enum.map(recent_trips_payload, & &1.route_id)

    trip_ids_to_delete =
      from(
        u in TripUpdate,
        where: u.arrival_time > ^now,
        where: u.arrival_time < ^look_ahead_threshold,
        join: t in assoc(u, :trip),
        where: t.trip_id not in ^ongoing_trip_ids,
        where: t.route_id in ^relevant_routes,
        select: t.id,
        distinct: true
      )
      |> Repo.all()

    {deleted_trip_count, _} =
      Repo.delete_all(
        from(
          u in TripUpdate,
          where: u.trip_id in ^trip_ids_to_delete
        )
      )

    {deleted_update_count, _} =
      Repo.delete_all(
        from(
          t in Trip,
          where: t.id in ^trip_ids_to_delete
        )
      )

    Logger.info(
      "Removed upcoming trips deleted: #{deleted_trip_count}, updates deleted: #{deleted_update_count}"
    )

    :ok
  end

  defp append_destination(trip_with_updates) do
  end
end
