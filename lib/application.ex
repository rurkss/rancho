defmodule Rancho.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Get configuration
    config = Application.get_env(:rancho, :server)
    metrica = Application.get_env(:rancho, :metrica)

    children = [
      # Add it to supervison tree
      {Rancho.Server, config},
      Plug.Adapters.Cowboy.child_spec(scheme: :http, plug: Rancho.Router, options: [port: 5556])
    ]

    Rancho.Metric.Setup.setup()

    opts = [strategy: :one_for_one, name: Rancho.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
