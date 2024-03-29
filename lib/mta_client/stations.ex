defmodule MtaClient.Stations do
  import Ecto.Query

  alias Ecto.Multi
  alias MtaClient.Repo
  alias MtaClient.Stations.{Parse, Station}
  alias MtaClient.Trips.{Trip, TripUpdate}

  @stations_csv_path Application.get_env(
                       :mta_client,
                       :stations_csv_path,
                       "/app/lib/mta_client-0.1.0/priv/static/stations.csv"
                     )

  def parse_and_insert_from_csv(path \\ @stations_csv_path) do
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

  def upcoming_trips_by_station(minutes_ahead) do
    now = NaiveDateTime.utc_now()
    a_minute_ago = NaiveDateTime.add(now, -1, :minute)
    look_ahead_threshold = NaiveDateTime.add(now, minutes_ahead, :minute)

    upcoming_trips_query =
      from(
        s in Station,
        left_join: u in TripUpdate,
        on: u.station_id == s.id,
        left_join: t in assoc(u, :trip),
        where: u.arrival_time > ^now,
        where: u.arrival_time < ^look_ahead_threshold,
        order_by: [asc: u.arrival_time],
        select: %{
          station: %{
            name: s.name,
            gtfs_stop_id: s.gtfs_stop_id,
            borough: s.borough,
            north_direction_label: s.north_direction_label,
            south_direction_label: s.south_direction_label
          },
          arrival_time: u.arrival_time,
          route: t.route_id,
          direction: t.direction,
          trip_id: t.trip_id,
          destination: t.destination,
          destination_boroughs: u.destination_boroughs
        }
      )

    upcoming_trips_query
    |> Repo.all()
    |> Enum.uniq_by(&{&1.trip_id, &1.station.gtfs_stop_id})
    |> Enum.group_by(& &1.station.gtfs_stop_id)
    |> Enum.sort()
  end

  defp shift_to_ny_time(%NaiveDateTime{} = time) do
    time
    |> DateTime.from_naive!("UTC")
    |> DateTime.shift_zone!("America/New_York")
  end
end
