# NYC Train Times

Live at: https://nyc-mta-realtime.fly.dev/

A small application for:
  - Parsing the [NYC Subway realtime feeds](https://api.mta.info/#/landing)
  - Storing trips and updates in postgres
  - Displaying upcoming train times for each station (with filtering by station name or route)

<img width="1400" alt="Screen Shot 2023-02-14 at 12 00 46 AM" src="https://user-images.githubusercontent.com/1441582/219898714-6833fd99-62af-4137-a7eb-91a2dc36e09f.png">

</br>

## Design

The application uses Phoenix, Elixir, and OTP to periodically retrieve and store data from the NYC subway system. It serves a single web endpoint ("/") which renders a Phoenix Liveview displaying subway stations with their upcoming train times, and updates the results based on the appropriate UI filters.

![Screen Shot 2023-02-10 at 11 56 36 PM](https://user-images.githubusercontent.com/1441582/218240943-816c2f42-e77a-4d0f-bb59-b4704683281e.png)



### Parsing and storing the data

In order to retrieve and store the necessary data the application:

1. Queries each of the NYC MTA Realtime feeds
2. Parses their values into structs (using protobuf)
3. Links those parsed records with statically-populated db records
    - Stations, TripDestinations
    - these come from CSVs provided by the MTA
4. Stores the new records in the database

This is done via a single GenServer named `MtaClient.Feed.Server` which queries the realtime feed every 60 seconds (the interval for updates according to the API). 

The Feed.Server calls the `Feed.Processor` which will update the appropriate tables with latest data. 

One note is that these route calls could easily be made parallel using Task.async or similar, but due to cloud resource constraints it's just serial for now. 

#### DB tables

<img width="300" alt="Screen Shot 2023-02-10 at 11 53 18 PM" src="https://user-images.githubusercontent.com/1441582/218241051-0c080d27-9410-408e-aa95-cfcb42ff301a.png">

### Rendering the view

The UI uses LiveView and Tailwind for to render the page. There is a GenServer (`MtaClient.Broadcast.Server`) started by the application which queries `Stations.upcoming_trips_by_station` which will return an aggregate list of stations and their trips. This is my first time using both tools and while it was generally pleasant the code is definitely a bit... rough. 

The UI filters for route and station name are wired to update the url parameters. These are then parsed into the socket's `assigns.params` map as well as applying any filters to the latest trip results, triggering a re-render.


## Known issues
 - [x] Fly.io free tier struggling to run things which causes some 500s
 - [x] On mobile browsers when de-selecting a route filter, the UI still shows the highlighted circle around the previous filter. I'm not sure why. 
 - [ ] Some trains show the wrong destinations. The example I know of is the "M" train to Forest Hills showing as Myrtle Av. However when I look at the MTA csvs that seems to be correct. On the MTA live map it the trains show as "Forest Hills" though so I'm missing something. 
 - [ ] I am not sure how to handle trips with  no start times, need to investigate if this means they're in the future or what. It leads to duplicate Trip records with nil start times. I need to upgrade my local postgres to use :nulls_distinct to at least stop the Trip bloat.
 - [ ] the width of cards changes with the longest stop name making things jerk around
 - [ ] Mahattan destinations should show uptown/downtown
