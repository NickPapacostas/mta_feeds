defmodule MtaClient.Trains.Train do
  use Ecto.Schema
  import Ecto.Changeset
  alias MtaClient.Trains.Train

  @required_fields [
    :train_id
  ]

  schema "trains" do
    field :train_id, :string
    # should be separate table
    field :current_status, Ecto.Enum, values: [:incoming_at, :in_transit_to, :stopped_at, nil]

    timestamps()
  end

  def changeset(%Train{} = train, attrs) do
    train
    |> cast(
      attrs,
      @required_fields
    )
    |> validate_required(@required_fields)
  end
end
