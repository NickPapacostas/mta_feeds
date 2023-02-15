defmodule MtaClient.Feed.Parser do
  require Logger

  alias TransitRealtime.{
    FeedEntity,
    TripUpdate,
    TripDescriptor,
    VehiclePosition
  }

  alias TransitRealtime.TripUpdate.StopTimeUpdate

  @ny_time_zone "America/New_York"

  def parse_feed_entities(feed_entities) do
    feed_entities
    |> Enum.reduce(%{trips: [], trip_updates: [], trains: [], alerts: []}, fn fe, acc ->
      {trip, trip_updates} = parse_trip(fe)

      # train = parse_vehicle_position(fe)

      alerts =
        if !is_nil(fe.alert) do
          acc.alerts ++ [fe]
        else
          acc.alerts
        end

      if trip && !Enum.empty?(trip_updates) do
        %{
          trips: acc.trips ++ [trip],
          trip_updates: acc.trip_updates ++ trip_updates,
          trains: acc.trains,
          alerts: alerts
        }
      else
        acc
      end
    end)
  end

  defp parse_trip(%FeedEntity{
         trip_update: %TripUpdate{
           trip: %TripDescriptor{} = trip,
           stop_time_update: updates
         }
       }) do
    start_date = parse_date_string(trip.start_date)

    start_time =
      case parse_start_time(trip.start_time, start_date) do
        {:ok, ndt} ->
          ndt

        {:error, _} ->
          # Logger.error("Feed.Parser unable to parse start time #{inspect(fe)}")
          nil
      end

    {direction, train_id} =
      case Map.from_struct(trip) do
        %{
          nyct_trip_descriptor: %NyctTripDescriptor{
            direction: direction,
            train_id: train_id
          }
        }
        when not is_nil(direction) ->
          {parse_direction(direction), train_id}

        _ ->
          case String.split(trip.trip_id, "..") do
            [_, second_half] ->
              direction = parse_direction(String.at(second_half, 0))
              {direction, nil}

            _ ->
              {nil, nil}
          end
      end

    trip_map = %{
      trip_id: trip.trip_id,
      start_time: start_time,
      start_date: start_date,
      route_id: trip.route_id,
      train_id: train_id,
      direction: direction
    }

    trip_updates = parse_trip_updates(trip.trip_id, updates)

    {trip_map, trip_updates}
  end

  defp parse_trip(_), do: {nil, []}

  defp parse_trip_updates(nil, _), do: []
  defp parse_trip_updates(_, []), do: []

  defp parse_trip_updates(trip_id, updates) do
    Enum.map(updates, fn %StopTimeUpdate{} = update ->
      arrival_time =
        if update.arrival do
          Map.get(update.arrival, :time)
          |> DateTime.from_unix!()
          |> DateTime.to_naive()
        end

      departure_time =
        if update.departure && update.departure.time do
          Map.get(update.departure, :time)
          |> DateTime.from_unix!()
          |> DateTime.to_naive()
        end

      %{
        stop_id: String.slice(update.stop_id, 0..-2),
        arrival_time: arrival_time,
        departure_time: departure_time,
        trip_id: trip_id
      }
    end)
  end

  # defp parse_vehicle_position(%FeedEntity{
  #        vehicle: %VehiclePosition{} = vp
  #      }) do
  #   case vp do
  #     %{trip: %TripDescriptor{nyct_trip_descriptor: %NyctTripDescriptor{train_id: train_id}}} ->
  #       %{
  #         train_id: train_id,
  #         current_status: parse_status(vp.current_status)
  #       }

  #     _ ->
  #       Logger.error("Feed.Parser unable to parse VehiclePosition #{inspect(vp)}")
  #       nil
  #   end
  # end

  # defp parse_vehicle_position(_), do: nil

  # e.g. "20230115" 
  defp parse_date_string(date_string) do
    case date_string do
      <<year::binary-4, month::binary-2, day::binary-2>> ->
        Date.new!(
          String.to_integer(year),
          String.to_integer(month),
          String.to_integer(day)
        )

      _ ->
        Logger.error("Feed.Parser unable to parse date string #{inspect(date_string)}")
        :parse_date_error
    end
  end

  defp parse_start_time(start_time, :parse_date_error) do
    {:ok, ny_today} = DateTime.now!(@ny_time_zone) |> DateTime.to_date()
    parse_start_time(start_time, ny_today)
  end

  defp parse_start_time(nil, _date) do
    {:error, nil}
  end

  defp parse_start_time(start_time, date) do
    case Time.from_iso8601(start_time) do
      {:ok, time} ->
        ndt =
          DateTime.new!(
            date,
            time,
            @ny_time_zone
          )
          |> DateTime.shift_zone!("UTC")
          |> DateTime.to_naive()

        {:ok, ndt}

      _ ->
        Logger.error("Feed.Parser unable to parse start_time #{inspect(start_time)}")
        {:error, :parse_start_time_error}
    end
  end

  defp parse_direction(:SOUTH), do: "south"
  defp parse_direction(:NORTH), do: "north"
  defp parse_direction(:EAST), do: "east"
  defp parse_direction(:WEST), do: "west"
  defp parse_direction("N"), do: "north"
  defp parse_direction("S"), do: "south"

  # defp parse_status(:STOPPED_AT), do: :stopped_at
  # defp parse_status(:IN_TRANSIT_TO), do: :in_transit_to
  # defp parse_status(:INCOMING_AT), do: :incoming_at
  # defp parse_status(_), do: nil
end
