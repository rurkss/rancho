defmodule Rancho.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Get configuration
    config = Application.get_env(:rancho, :server)

    children = [
      # Add it to supervison tree
      {Rancho.Server, config}
    ]

    opts = [strategy: :one_for_one, name: Rancho.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
