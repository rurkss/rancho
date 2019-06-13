defmodule Rancho.Redis do
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

  def init(state) do

    [host: host, port: port, keys: subscribes] = Application.get_env(:rancho, :redis)

    {:ok, pubsub} = Redix.PubSub.start_link(host: host, port: port)

    s = self()
    Enum.map(subscribes, fn x -> Redix.PubSub.subscribe(pubsub, x, s) end)

    {:ok, pubsub}
  end

  def handle_info({:redix_pubsub, _pid, _ref, :subscribed, _data}, state) do
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _pubsub, _ref, :message, %{channel: channel, payload: payload}}, state) do
    Rancho.Stable.spread(channel, payload)
    {:noreply, state}
  end
end
