IEx.configure(inspect: [limit: 500])
import Ecto.Query
alias MtaClient.Repo
alias MtaClient.Feed.Processor
alias MtaClient.Trips.{Trip, TripDestination, TripUpdate}
alias MtaClient.Stations
alias MtaClient.Stations.Station
alias MtaClient.Feed.Server
alias MtaClient.Broadcast.Server
Server.stop()
MtaClient.Broadcast.Server.stop()
