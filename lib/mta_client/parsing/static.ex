defmodule MtaClient.Parsing.Static do
  alias MtaClient.Stations

  @files [
    {:stations, "stations.csv"}
  ]

  def parse_static_files() do
    @files
    |> Enum.map(fn {:stations, path} ->
      Stations.parse_and_insert_from_csv(Path.join(["static", path]))
    end)
  end
end
