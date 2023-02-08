IEx.configure(inspect: [limit: 500])
import Ecto.Query
alias MtaClient.Repo
alias MtaClient.Feed.Processor
alias MtaClient.Trips.{Trip, TripUpdate}
alias MtaClient.Stations
alias MtaClient.Stations.Station
alias MtaClient.Feed.Server
Server.stop()
