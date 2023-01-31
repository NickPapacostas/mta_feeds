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
      <.header />
      <div class="grid grid-cols-4 gap-2">
        <%= for {station, trips} <- assigns.upcoming_trips do %>
          <.upcoming_trips_for_station station={station} trips={trips} />
        <% end %>
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
    <div class="divide-y divide-gray-400/50">
      <div class="py-8 text-base flex justify-center">

          <div class="relative cursor-pointer gap-4 flex justify-center">
            <input type="text" class="rounded border border-gray-300 text-gray-900 text-sm w-32" placeholder="Filter stations...">
            <%= for {route, color} <- Routes.routes_with_color() do %>
              <div class="flex flex-col">
                <% route_class = "flex place-content-center w-8 h-8 bg-#{color}-400 transition-all rounded-full ring-#{color} hover:ring-2 ring-offset-1 " %>
                <% route_filter = fn -> JS.push("route_filter", value: %{route: route}) end %>
                <div phx-click={route_filter.()} class={route_class} >
                  <div class="text-white text-2xl"><%= route %></div>
                </div>
              </div>
            <% end %>
          </div>
      </div>
     <div class="divide-y divide-gray-400/50"></div>
    </div>

    """
  end

  defp upcoming_trips_for_station(assigns) do
    ~H"""
    <div class="flex flex-col border-black border-3 shadow-indigo-50 shadow-md">
      <div class ="flex p-4 justify-center rounded-lg bg-white "> 

        <div class="text-black-100"> <%= @station %> </div>
      </div>
      <div>
        <ul class="divide-y divide-gray-200 dark:divide-gray-700">
          <%= for trip <- Enum.take(@trips, 5) do %>
            <% color = Routes.route_color(trip.route) %>
            <% route_class = "bg-#{color}-400 w-8 h-8 text-white rounded-full shadow-2xl border-white border-2  flex justify-center items-center " %>

            <li class="py-3 sm:py-4">
               <div class="flex justify-center gap-5">
                   <div class="flex-shrink-0">
                       <div class={route_class}>
                         <%= trip.route %>
                       </div>
                   </div>
                   <div >
                       <div>
                          <% arrival_time = time_until_arrival(trip.arrival_time) %>
                          <%= if arrival_time == 0, do: "arriving", else: arrival_time %> 
                       </div>
                   </div>

               </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      MtaClientWeb.Endpoint.subscribe(@upcoming_trips_topic)
    end

    upcoming_trips = Stations.upcoming_trips_by_station(@minutes_ahead)

    {:ok, assign(socket, :upcoming_trips, upcoming_trips)}
  end

  def handle_info({:upcoming_trips, upcoming_trips}, socket) do
    upcoming_trips =
      if route = Map.get(socket.assigns, :route_filter) do
        filter_for_route(upcoming_trips, route)
      else
        upcoming_trips
      end

    Logger.info("new Upcoming route #{inspect(route)}")

    {:noreply, assign(socket, :upcoming_trips, upcoming_trips)}
  end

  def handle_event("route_filter", %{"route" => route}, socket) do
    upcoming_trips =
      Stations.upcoming_trips_by_station(@minutes_ahead)
      |> filter_for_route(route)

    socket =
      socket
      |> assign(:route_filter, route)
      |> assign(:upcoming_trips, upcoming_trips)

    {:noreply, socket}
  end

  defp filter_for_route(trips_by_station, route) do
    Enum.filter(trips_by_station, fn {s, trips} -> Enum.any?(trips, &(&1.route == route)) end)
  end

  defp trips_for_route(upcoming_trips, route) do
    # upcoming_trips
    # |> Enum.map(fn )
  end

  defp time_until_arrival(arrival_time) do
    NaiveDateTime.diff(arrival_time, NaiveDateTime.utc_now(), :minute)
  end
end
