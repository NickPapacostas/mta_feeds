defmodule MtaClient.Trips.Parse do
  require Logger

  alias TransitRealtime.{
    FeedEntity,
    TripUpdate,
    TripDescriptor,
    VehiclePosition
  }

  @ny_time_zone "America/New_York"

  def feed_entities(feed_entities) do
    feed_entities
    |> Enum.reduce(%{trips: [], vehicles: []}, fn fe, acc ->
      trip = parse_trip(fe)

      new_trips =
        if trip do
          acc.trips ++ [trip]
        else
          acc.trips
        end

      vehicle = parse_vehicle(fe)

      new_vehicles =
        if vehicle do
          acc.vehicles ++ [vehicle]
        else
          acc.vehicles
        end

      %{trips: new_trips, vehicles: new_vehicles}
    end)
  end

  defp parse_trip(%FeedEntity{
         trip_update: %TripUpdate{
           trip: %TripDescriptor{} = trip
         }
       }) do
    start_date = parse_date_string(trip.start_date)
    start_time = parse_start_time(trip.start_time, start_date)

    direction =
      case Map.from_struct(trip) do
        %{nyct_trip_descriptor: %NyctTripDescriptor{direction: direction}}
        when not is_nil(direction) ->
          parse_direction(direction)

        _ ->
          nil
      end

    %{
      trip_id: trip.trip_id,
      start_time: start_time,
      start_date: start_date,
      route_id: trip.route_id,
      direction: direction
    }
  end

  defp parse_trip(_), do: nil

  defp parse_vehicle(_), do: nil
  # defp parse_vehicle(%FeedEntity{
  #     vehicle: %TransitRealtime.VehiclePosition{})

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
        Logger.error("Trips.Parse unable to parse date string #{inspect(date_string)}")
        :parse_date_error
    end
  end

  defp parse_start_time(start_time, :parse_date_error) do
    {:ok, ny_today} = DateTime.now!(@ny_time_zone) |> DateTime.to_date()
    parse_start_time(start_time, ny_today)
  end

  defp parse_start_time(start_time, date) do
    case Time.from_iso8601(start_time) do
      {:ok, time} ->
        DateTime.new!(
          date,
          time,
          @ny_time_zone
        )
        |> DateTime.shift_zone!("UTC")
        |> DateTime.to_naive()

      _ ->
        Logger.error("Trips.Parse unable to parse start_time #{inspect(start_time)}")
        :parse_start_time_error
    end
  end

  defp parse_direction(:SOUTH), do: "south"
  defp parse_direction(:NORTH), do: "north"
  defp parse_direction(:EAST), do: "east"
  defp parse_direction(:WEST), do: "west"
end
