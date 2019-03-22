defmodule Rancho.Metric.Server do
  @moduledoc """
  A simple TCP server.
  """

  use GenServer


  require Logger

  @doc """
  Starts the server.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Initiates the listener (pool of acceptors).
  """
  def init(port: port) do
    opts = [{:port, port}]

    {:ok, pid} = :ranch.start_listener(:metrica, :ranch_tcp, opts, Rancho.Metric.NetworkHandler, [])

    Logger.info(fn ->
      "Listening for connections on port #{port}"
    end)

    {:ok, pid}
  end
end
