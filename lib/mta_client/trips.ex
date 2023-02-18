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
          |> Multi.insert(multi_key, changeset, on_conflict: :nothing)

        Multi.append(acc_multi, trip_multi)
      else
        Logger.error("invalid: #{inspect(trip_map)}#{inspect(changeset)}")
        acc_multi
      end
    end)
  end

  defp append_trip_destination_id(
         %{
           trip_id: trip_id,
           route_id: route,
           direction: direction
         } = trip_map
       ) do
    service_code = trip_to_service_code(trip_map)

    destination_query =
      from(
        td in TripDestination,
        where: td.service_code == ^service_code,
        where: td.route == ^route,
        where: td.direction == ^direction,
        # There are often two destinations for 
        # a service code / direction / route combo
        # and it is hard to tell which is the right 
        # one as the trip id isn't specific enough
        # this hack seems to yield better results
        # e.g. "R" "sourth" goes to bay ridge not whitehall
        # fahgahdsakes
        order_by: [desc: td.id],
        limit: 1,
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

  defp trip_to_service_code(%{start_date: nil}) do
    :weekday
  end

  defp trip_to_service_code(%{start_date: start_date}) do
    start_date
    |> Date.day_of_week()
    |> then(fn day_of_week_int ->
      case day_of_week_int do
        6 ->
          :saturday

        7 ->
          :sunday

        _ ->
          :weekday
      end
    end)
  end
end
