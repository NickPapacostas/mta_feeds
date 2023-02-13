defmodule MtaClientWeb.Live.Stations do
  require Logger
  use Phoenix.LiveView

  alias Phoenix.LiveView.JS
  alias MtaClient.{Routes, Stations}

  @upcoming_trips_topic "upcoming_trips_update"
  @minutes_ahead 20

  def render(assigns) do
    if assigns.upcoming_trips do
      ~H"""
      <div class="p-4">
        <.header route_filter={assigns.params.route_filter} route_counts={assigns.route_counts} station_name_filter={assigns.params.station_name_filter}/>
        <div class="grid place-content-center md:grid-cols-4 gap-4 ">
          <% filtered_trips = if assigns.params.route_filter || assigns.params.station_name_filter do
            assigns.filtered_trips
          else
            # if no filters show 30 random stations
            assigns.filtered_trips
            |> Enum.shuffle
            |> Enum.take(30)
          end %>
          <%= for {_station_id, trips} <- filtered_trips do %>
            <.upcoming_trips_for_station station={List.first(trips).station} trips={trips} />
          <% end %>
        </div>
      </div>
      """
    else
      ~H"""
      oops
      """
    end
  end

  defp header(assigns) do
    ~H"""
    <div class="flex py-4 justify-between">
        <div></div>
        <div> <a href="/" class="pl-12 font-bold"> NYC TRAIN TIMES </a></div>
        <div>(<a href="https://github.com/NickPapacostas/mta_feeds/blob/main/README.md" class="text-sm underline decoration-sky-500" target="_blank">about</a>)</div>
    </div>

      <div class="pb-4 justify-center ">
        <div class="relative cursor-pointer gap-4 flex justify-center flex-wrap">
        <form phx-change="station_name_filter" phx-submit="save" class="flex justify-center">
          <input value={@station_name_filter} name="station_name_filter" phx-debounce="500" type="text" class=" rounded border text-sm w-32 bg-orange-100" placeholder="Search stations...">
        </form>

        <%= for {route, color} <- Routes.routes_with_color() do %>
          <div class="flex flex-col ">
            <% count_for_rount = Map.get(@route_counts, route, 0) %>
            <% text_color = if count_for_rount == 0 do
              "text-black"
            else
              "text-white"
            end %>
            <div phx-click={route_click_fn(route, @route_filter).()} class={route_circle_class(route, color, @route_filter)} >
              <div class={"#{text_color} text-2xl"}><%= route %></div>
            </div>
          </div>
        <% end %>
      </div>
    </div>

    """
  end

  defp upcoming_trips_for_station(assigns) do
    ~H"""
    <div class="p-2 flex flex-col border-black border-4 ">
      <div class =" text-center rounded-lg "> 
        <div class="text-black-100 underline font-bold"> <%= @station %> </div>
      </div>
      <div>
        <ul class="divide-black divide-y">
          <%= for trip <- Enum.take(@trips, 5) do %>
            <% color = Routes.route_color(trip.route) %>
            <% route_class = "bg-#{color} w-8 h-8 text-white rounded-full shadow-2xl  flex justify-center items-center " %>

            <li class="p-3 hover:bg-sky-200 sm:py-4 flex justify-between overflow-hidden">
               <div class="flex gap-5">
                   <div class="">
                       <div class={route_class}>
                         <%= trip.route %>
                       </div>
                   </div>
                   <div>
                       <div>
                          <% destination = trip.destination || Routes.route_destination(trip.route, trip.direction) %>
                          <%= destination %> 
                       </div>
                   </div>
              </div>
               <div class="pl-2 flex">
                   <div class="">
                      <% arrival_time = time_until_arrival(trip.arrival_time) %>
                      <%= if arrival_time == 0, do: "arriving", else: "#{arrival_time} min" %> 
                   </div>
               </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  ####  View Helpers 

  defp route_click_fn(route, route_filter) do
    value =
      if route == route_filter do
        nil
      else
        route
      end

    fn ->
      JS.push("route_filter", value: %{route: value})
    end
  end

  defp route_circle_class(route, color, route_filter) do
    route_class =
      "flex place-content-center w-8 h-8 bg-#{color} transition-all rounded-full ring-offset-2 mb-2 "

    if route == route_filter do
      route_class <> "ring-#{color} ring-4 ring-offset-1"
    else
      route_class
    end
  end

  ### Callbacks

  def mount(_params, _session, socket) do
    if connected?(socket) do
      MtaClientWeb.Endpoint.subscribe(@upcoming_trips_topic)
    end

    upcoming_trips = Stations.upcoming_trips_by_station(@minutes_ahead)
    route_counts_for_trips = Routes.route_counts_for_trips(upcoming_trips)

    socket =
      socket
      |> assign(:upcoming_trips, upcoming_trips)
      |> assign(:filtered_trips, upcoming_trips)
      |> assign(:route_counts, route_counts_for_trips)
      |> assign(:params, %{route_filter: nil, station_name_filter: nil})

    {:ok, socket}
  end

  def handle_params(%{"route_filter" => "", "station_name_filter" => ""}, uri, socket) do
    handle_params(%{"route_filter" => nil, "station_name_filter" => nil}, uri, socket)
  end

  def handle_params(params, _uri, socket) do
    params = %{
      route_filter: Map.get(params, "route_filter"),
      station_name_filter: Map.get(params, "station_name_filter")
    }

    socket = assign(socket, :params, params)

    filtered_upcoming_trips = filter_trips(socket.assigns.upcoming_trips, params)
    {:noreply, assign(socket, :filtered_trips, filtered_upcoming_trips)}
  end

  defp query_params(params) do
    "?#{URI.encode_query(params)}"
  end

  def handle_info(
        {:upcoming_trips, upcoming_trips, route_counts_for_trips},
        %{assigns: %{params: params}} = socket
      ) do
    filtered_upcoming_trips = filter_trips(upcoming_trips, params)

    socket =
      socket
      |> assign(:upcoming_trips, upcoming_trips)
      |> assign(:filtered_trips, filtered_upcoming_trips)
      |> assign(:route_counts, route_counts_for_trips)

    {:noreply, socket}
  end

  def handle_event("route_filter", %{"route" => route}, socket) do
    params = Map.merge(socket.assigns.params, %{route_filter: route})

    {:noreply, push_patch(socket, to: "/#{query_params(params)}", replace: true)}
  end

  def handle_event("station_name_filter", %{"station_name_filter" => name_string}, socket) do
    params = Map.merge(socket.assigns.params, %{station_name_filter: name_string})

    {:noreply, push_patch(socket, to: "/#{query_params(params)}", replace: true)}
  end

  def handle_event(unhandled, unhandled_value, socket) do
    Logger.warning("Live.Stations unhandled event #{unhandled} #{inspect(unhandled_value)}")
    {:noreply, assign(socket, "route_filter", nil)}
  end

  defp filter_trips(trips_by_station, params) do
    trips_by_station
    |> filter_for_route(params)
    |> filter_for_station(params)
  end

  defp filter_for_route(trips_by_station, %{route_filter: nil}), do: trips_by_station
  defp filter_for_route(trips_by_station, %{route_filter: ""}), do: trips_by_station

  defp filter_for_route(trips_by_station, %{route_filter: route_filter}) do
    Enum.filter(trips_by_station, fn {_station, trips} ->
      Enum.any?(trips, &(&1.route == route_filter))
    end)
  end

  defp filter_for_route(trips_by_station, _), do: trips_by_station

  defp filter_for_station(trips_by_station, %{station_name_filter: nil}), do: trips_by_station
  defp filter_for_station(trips_by_station, %{station_name_filter: ""}), do: trips_by_station

  defp filter_for_station(trips_by_station, %{station_name_filter: station_name_filter}) do
    Enum.filter(trips_by_station, fn
      {_station, [t | _]} ->
        String.contains?(String.downcase(t.station), String.downcase(station_name_filter))

      _ ->
        false
    end)
  end

  defp filter_for_station(trips_by_station, _), do: trips_by_station

  defp time_until_arrival(nil), do: ""

  defp time_until_arrival(arrival_time) do
    NaiveDateTime.diff(arrival_time, NaiveDateTime.utc_now(), :minute)
  end
end
