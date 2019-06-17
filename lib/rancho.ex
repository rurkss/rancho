defmodule Rancho.Server do
  @moduledoc """
  A simple TCP server.
  """

  use GenServer

  alias Network.Handler

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
  def init(port: port, max_connections: max_connections, num_acceptors: num_acceptors) do

    opts = [{:port, port}]

    IO.puts "inspect opts"
    IO.inspect opts

    {:ok, pid} = :ranch.start_listener(:network, :ranch_tcp, opts, Handler, [])
    :ranch.set_max_connections(:network, max_connections)
    :ranch.set_protocol_options(:network, [{:num_acceptors, num_acceptors}])

    Logger.info(fn ->
      "Listening for connections on port #{port}"
    end)

    {:ok, pid}
  end
end
