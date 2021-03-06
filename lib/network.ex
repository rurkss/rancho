defmodule Network.Handler do
  @moduledoc """
  A simple TCP protocol handler that echoes all messages received.
  """

  use GenServer
  use Prometheus.Metric


  require Logger

  alias Rancho.Stable
  # Client

  @doc """
  Starts the handler with `:proc_lib.spawn_link/3`.
  """
  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  @doc """
  Initiates the handler, acknowledging the connection was accepted.
  Finally it makes the existing process into a `:gen_server` process and
  enters the `:gen_server` receive loop with `:gen_server.enter_loop/3`.
  """
  def init(ref, socket, transport) do
    peername = stringify_peername(socket)

    Gauge.inc([name: :connection_pool_checked_out])

    Logger.info(fn ->
      "Peer #{peername} connecting"
    end)

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])

    Stable.put(peername, socket, transport)

    start_time = :os.system_time(:seconds)

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      peername: peername,
      start_time: start_time
    })
  end

  # Server callbacks

  def handle_info(
        {:tcp, _, <<"factorial", ":", of::binary>>},
        %{socket: socket, transport: transport, peername: peername, start_time: start_time} = state
      ) do

    Logger.info(fn ->
      "Received new Factorial #{peername}: of #{of}. Start calculation"
    end)

    start_time = :os.system_time(:seconds)

    result =
    of
    |> :erlang.binary_to_integer
    |> Rancho.Factorial.iter

    Logger.info(fn ->
       "Calculation for #{of} is done"
    end)

    sec = :os.system_time(:seconds)-start_time

    transport.send(socket, "done in #{sec}\n")

    {:noreply, state}
  end

  def handle_info(
        {:tcp, _, message},
        %{socket: socket, transport: transport, peername: peername, start_time: start_time} = state
      ) do

    Logger.info(fn ->
      # [
      #   {Rancho.Router.HTTP, _data},
      #   {:network, [
      #     pid: pid,
      #     status: status,
      #     ip: ip,
      #     port: port,
      #     max_connections: m_c,
      #     active_connections: a_c,
      #     all_connections: al_c,
      #     transport: trs,
      #     transport_options: t_o,
      #     protocol: p,
      #     protocol_options: p_o
      #   ]}
      # ] = :ranch.info()
      "Received new message from peer #{peername}: #{inspect(message)}. Echoing it back"
    end)

    # Stable.spread(message)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, %{peername: peername} = state) do
    Logger.info(fn ->
      "Peer #{peername} disconnected"
    end)

    Gauge.dec([name: :connection_pool_checked_out])
    Stable.pop(peername)

    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _, reason}, %{peername: peername} = state) do
    Logger.info(fn ->
      "Error with peer #{peername}: #{inspect(reason)}"
    end)

    Gauge.dec([name: :connection_pool_checked_out])
    Stable.pop(peername)

    {:stop, :normal, state}
  end

  # Helpers

  defp stringify_peername(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    address =
      addr
      |> :inet_parse.ntoa()
      |> to_string()

    "#{address}:#{port}"
  end
end
