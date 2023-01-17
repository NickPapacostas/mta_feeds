defmodule MtaClient.Stations.Parse do
  def csv(path) do
    path
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.to_list()
    |> Enum.map(fn
      {:ok, station_map} -> station_map
      {:error, error} -> IO.puts(error)
    end)
    |> Enum.map(&format_map/1)
  end

  defp format_map(map_from_csv) do
    map_from_csv
    |> Enum.map(fn key_value -> format(key_value) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  defp format({"Station ID", v}) do
    format({"mta_station_id", String.to_integer(v)})
  end

  defp format({"Daytime Routes", v}) do
    format({"daytime_routes", String.split(v, " ")})
  end

  defp format({"Stop Name", v}) do
    format({"name", v})
  end

  defp format({key, ""}) do
    nil
  end

  defp format({key, v}) do
    formatted =
      key
      |> String.downcase()
      |> String.replace(" ", "_")
      # to existing
      |> String.to_atom()

    {formatted, v}
  end
end
