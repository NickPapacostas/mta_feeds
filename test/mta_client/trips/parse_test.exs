defmodule MtaClient.Trips.ParseTest do
  use ExUnit.Case, async: true

  alias MtaClient.Trips.Parse

  setup do
    feed_entities = [
      %TransitRealtime.FeedEntity{
        id: "000001N",
        trip_update: %TransitRealtime.TripUpdate{
          trip: %TransitRealtime.TripDescriptor{
            trip_id: "120000_N..S",
            start_time: "20:00:00",
            start_date: "20230115",
            schedule_relationship: nil,
            route_id: "N",
            direction_id: nil,
            nyct_trip_descriptor: %NyctTripDescriptor{
              train_id: "1N 2000 DIT/KHY",
              is_assigned: true,
              direction: :SOUTH
            }
          },
          stop_time_update: [
            %TransitRealtime.TripUpdate.StopTimeUpdate{
              stop_sequence: nil,
              arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
                delay: nil,
                time: 1_673_834_364,
                uncertainty: nil
              },
              departure: %TransitRealtime.TripUpdate.StopTimeEvent{
                delay: nil,
                time: 1_673_834_364,
                uncertainty: nil
              },
              stop_id: "N03S",
              schedule_relationship: nil,
              nyct_stop_time_update: %NyctStopTimeUpdate{
                scheduled_track: "E1",
                actual_track: "E1"
              }
            }
          ],
          vehicle: nil,
          timestamp: nil,
          delay: nil
        }
      }
    ]

    {:ok, %{feed_entities: feed_entities}}
  end

  describe "feed_entities/1" do
    test "parses a feed entities into trips", %{feed_entities: feed_entities} do
      assert %{
               trips: [
                 %{
                   direction: :SOUTH,
                   route_id: "N",
                   start_date: "20230115",
                   start_time: "20:00:00",
                   trip_id: "120000_N..S"
                 }
               ]
             } = Parse.feed_entities(feed_entities)
    end
  end
end
