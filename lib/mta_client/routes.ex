defmodule MtaClient.Routes do
  @yellow_routes ["N", "Q", "R", "W"]
  @orange_routes ["B", "D", "M", "F"]
  @red_routes ["1", "2", "3"]
  @green_routes ["4", "5", "6"]
  @cyan_routes ["A", "C", "E"]
  @emerald_routes ["G"]
  @brown_routes ["J", "Z"]
  @purple_routes ["7"]
  @l_routes ["L"]
  @all_routes @yellow_routes ++
                @orange_routes ++
                @red_routes ++
                @green_routes ++
                @cyan_routes ++
                @purple_routes ++
                @l_routes ++ @emerald_routes

  def all_routes() do
    @all_routes
  end

  def routes_with_color() do
    @all_routes
    |> Enum.map(&{&1, route_color(&1)})
  end

  def route_color(route_id) when route_id in @yellow_routes, do: "yellow-400"
  def route_color(route_id) when route_id in @orange_routes, do: "orange-400"
  def route_color(route_id) when route_id in @red_routes, do: "red-400"
  def route_color(route_id) when route_id in @green_routes, do: "green-600"
  def route_color(route_id) when route_id in @cyan_routes, do: "cyan-400"
  def route_color(route_id) when route_id in @emerald_routes, do: "emerald-400"
  def route_color(route_id) when route_id in @brown_routes, do: "zinc-400"
  def route_color(route_id) when route_id in @purple_routes, do: "violet-400"
  def route_color(_), do: "slate-400"

  def route_destination(route, direction) when is_binary(direction) do
    route_destinations_map()
    |> Map.get(route, %{})
    |> Map.get(String.to_existing_atom(direction))
  end

  def route_destination(_route, _direction), do: ""

  def route_destinations_map() do
    %{
      "1" => %{north: "Van Cortlandt Park-242 St", south: "South Ferry"},
      "2" => %{north: "Wakefield-241 St", south: "Flatbush Av-Brooklyn College"},
      "3" => %{north: "Harlem-148 St", south: "Times Sq-42 St"},
      "4" => %{north: "Woodlawn", south: "New Lots Av"},
      "5" => %{north: "Eastchester-Dyre Av", south: "E 180 St"},
      "6" => %{north: "Pelham Bay Park", south: "Brooklyn Bridge-City Hall"},
      "7" => %{north: "Flushing-Main St", south: "34 St-Hudson Yards"},
      "A" => %{north: "Euclid Av", south: "Far Rockaway-Mott Av"},
      "B" => %{north: "Bedford Park Blvd", south: "Brighton Beach"},
      "C" => %{north: "168 St", south: "Euclid Av"},
      "D" => %{north: "Norwood-205 St", south: "Coney Island-Stillwell Av"},
      "E" => %{north: "Jamaica Center-Parsons/Archer", south: "World Trade Center"},
      "F" => %{north: "Jamaica-179 St", south: "Coney Island-Stillwell Av"},
      "G" => %{north: "Court Sq", south: "Church Av"},
      "H" => %{north: "Broad Channel", south: "Rockaway Park-Beach 116 St"},
      "I" => %{north: "St George", south: "Tottenville"},
      "J" => %{north: "Jamaica Center-Parsons/Archer", south: "Broad St"},
      "L" => %{north: "8 Av", south: "Canarsie-Rockaway Pkwy"},
      "M" => %{north: "Myrtle Av", south: "Middle Village-Metropolitan Av"},
      "N" => %{north: "Astoria-Ditmars Blvd", south: "Coney Island-Stillwell Av"},
      "Q" => %{north: "96 St", south: "Coney Island-Stillwell Av"},
      "R" => %{north: "Forest Hills-71 av", south: "Bay Ridge-95 St"},
      "S" => %{north: "Times Sq-42 St", south: "Grand Central-42 St"}
    }
  end

  def parse_route_destinations() do
    "static/routes.csv"
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.to_list()
    |> Enum.map(fn
      {:ok, route_map} -> route_map
    end)
    |> Enum.map(fn route_map ->
      {first_bit, second_bit} =
        route_map["trip_id"]
        |> String.split(".")
        |> then(fn split -> {List.first(split), List.last(split)} end)

      {route, direction} = {String.slice(first_bit, -1..-1), String.slice(second_bit, 0..0)}
      {route, direction, route_map["trip_headsign"]}
    end)
    |> Enum.uniq()
    |> Enum.group_by(fn {route, _, _} -> route end)
    |> Enum.map(fn {route, results} ->
      {_, _, south_destination} =
        Enum.find(results, fn {_route, d_letter, _destination} -> d_letter == "S" end)

      {_, _, north_destination} =
        Enum.find(results, fn {_route, d_letter, _destination} -> d_letter == "N" end)

      {route, %{south: south_destination, north: north_destination}}
    end)
    |> Enum.into(%{})
  end
end
