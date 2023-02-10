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
    look_ahead_threshold = NaiveDateTime.add(now, minutes_ahead, :minute)

    upcoming_trips_query =
      from(
        s in Station,
        left_join: u in TripUpdate,
        on: u.station_id == s.id,
        left_join: t in assoc(u, :trip),
        left_join: td in assoc(t, :trip_destination),
        where: u.arrival_time > ^now,
        where: u.arrival_time < ^look_ahead_threshold,
        order_by: [asc: u.arrival_time],
        select: %{
          station: s.name,
          station_id: s.gtfs_stop_id,
          arrival_time: u.arrival_time,
          departure_time: u.departure_time,
          route: t.route_id,
          destination: td.destination_name,
          direction: t.direction,
          trip_id: t.trip_id,
          trip_start: t.start_time,
          train_id: t.train_id
        }
      )

    upcoming_trips_query
    |> Repo.all()
    |> Enum.group_by(& &1.station_id)
    |> Enum.sort()
  end

  defp shift_to_ny_time(%NaiveDateTime{} = time) do
    time
    |> DateTime.from_naive!("UTC")
    |> DateTime.shift_zone!("America/New_York")
  end
end
