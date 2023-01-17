defmodule MtaClient.Parsing.Protobuf do
  use Protox,
    files: [
      "lib/mta_client/parsing/gtfs-realtime.proto",
      "lib/mta_client/parsing/nyct-subway.proto"
    ]
end
