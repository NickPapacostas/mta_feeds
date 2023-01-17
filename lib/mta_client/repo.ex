defmodule MtaClient.Repo do
  use Ecto.Repo,
    otp_app: :mta_client,
    adapter: Ecto.Adapters.Postgres
end
