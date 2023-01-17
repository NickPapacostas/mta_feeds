defmodule MtaClient.Stations do
  import Ecto.Query

  alias Ecto.Multi
  alias MtaClient.Repo
  alias MtaClient.Stations.{Parse, Station}
  alias MtaClient.Trips.{Trip, TripUpdate}

  def parse_and_insert_from_csv(path) do
    path
    |> Parse.csv()
    |> Enum.reduce(Multi.new(), fn station_map, acc_multi ->
      changeset = Station.changeset(%Station{}, station_map)
      multi_key = {:station, station_map.mta_station_id, station_map.line}

      station_multi =
        Multi.new()
        |> Multi.insert_or_update(multi_key, changeset)

      Multi.append(acc_multi, station_multi)
    end)
    |> Repo.transaction()
  end

  def upcoming_trips_by_station(minutes_ahead, limit \\ 10) do
    now = DateTime.now!("America/New_York") |> DateTime.shift_zone!("UTC") |> DateTime.to_naive()
    look_ahead_threshold = NaiveDateTime.add(now, minutes_ahead, :minute)

    upcoming_trips_query =
      from(
        u in TripUpdate,
        join: t in assoc(u, :trip),
        join: s in assoc(u, :station),
        where: u.arrival_time > ^now,
        where: u.arrival_time < ^look_ahead_threshold,
        select: %{
          station: s.name,
          station_id: s.name,
          arrival_time: u.arrival_time,
          route: t.route_id,
          direction: t.direction
        },
        limit: ^limit
      )

    upcoming_trips_query
    |> Repo.all()
    |> Enum.map(fn %{arrival_time: at} = r -> Map.put(r, :arrival_time, shift_to_ny_time(at)) end)
    |> Enum.group_by(& &1.station)
  end

  defp shift_to_ny_time(%NaiveDateTime{} = time) do
    time
    |> DateTime.from_naive!("UTC")
    |> DateTime.shift_zone!("America/New_York")
  end
end
