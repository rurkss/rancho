defmodule Rancho.Stable do
  use GenServer

  @stable :stable
  @last_ver_cache :stable_caches

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    :ets.new(@stable, [:set, :public, :named_table, {:read_concurrency, true}])
    :dets.open_file(@last_ver_cache, [type: :set])
  end

  def handle_cast({:pop, uid}, state) do
    :ets.delete(@stable, uid)
    {:noreply, state}
  end

  def handle_cast({:put, {peername, data}}, cache_ref) do

    :ets.insert(@stable, {peername, data})

    case :ets.lookup(@stable, peername) do
      [{^peername, {socket, transport}}] -> populate_peer(socket, transport, cache_ref)
      _ -> :ok
    end

    {:noreply, cache_ref}
  end

  def handle_call({:spread, key, message}, _from, cache_table) do

    :dets.insert(cache_table, {key, message})

    spreads_to = :ets.foldl(fn({peername, {socket, transport}}, acc) ->

      case transport.send(socket, message) do
        {:error, :closed} -> __MODULE__.pop(peername)
        _-> [peername | acc]
      end

    end, [], @stable)

    {:reply, spreads_to, cache_table}
  end

  def handle_call(:scan_connections, _from, state) do

    keys = :ets.foldl(fn({key, obj}, acc) ->
      [key | acc]
    end, [], @stable)

    {:reply, keys, state}
  end

  def handle_call(:read, _from, cache_table) do

    keys = :dets.foldl(fn({key, obj}, acc) ->
      [key | acc]
    end, [], cache_table)

    # peername = "_development__interline_validate_classes_3_0"

    # data = case :dets.lookup(cache_table, peername) do
    #   [{^peername, data}] -> data
    #   _ -> :ok
    # end

    {:reply, keys, cache_table}
  end

  def populate_peer(socket, transport, cache_ref) do

    data = :dets.foldl(fn({key, message}, acc) ->
      key <> "start" <> message <> "end" <> acc
    end, "", cache_ref)

    transport.send(socket, data)
  end

  ######################## API ##############################

  def spread(key, message) do
    __MODULE__
      |> GenServer.call({:spread, key, message})
  end

  def put(uid, socket, transport) do
    __MODULE__
      |> GenServer.cast({:put, {uid, {socket, transport}}})
  end

  def pop(peername) do
    __MODULE__
    |> GenServer.cast({:pop, peername})
  end

  def populate(peername) do
    __MODULE__
    |> GenServer.cast({:populate, peername})
  end

  def scan_connections() do
    Rancho.Stable
      |> GenServer.call(:scan_connections)
  end

  def read() do
    Rancho.Stable
      |> GenServer.call(:read)
  end
end