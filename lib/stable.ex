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

    {d, z} = :calendar.local_time()
    {y, mo, d} = d
    {h, m, s} = z

    :ets.insert(@stable, {peername, data, "#{y}-#{mo}-#{d} #{h}:#{m}:#{s}"})

    case :ets.lookup(@stable, peername) do
      [{^peername, {socket, transport, dt}}] -> populate_peer(socket, transport, cache_ref)
      [{^peername, {socket, transport}}] -> populate_peer(socket, transport, cache_ref)
      _ -> :ok
    end

    {:noreply, cache_ref}
  end

  def handle_call({:spread, key, message}, _from, cache_table) do

    {d, z} = :calendar.local_time()
    {y, mo, d} = d
    {h, m, s} = z

    :dets.insert(cache_table, {key, message, "#{y}-#{mo}-#{d} #{h}:#{m}:#{s}"})

    spreads_to = :ets.foldl(fn({peername, {socket, transport}}, acc) ->

      case transport.send(socket, key <> "start" <> message <> "end") do
        {:error, :closed} -> __MODULE__.pop(peername)
        _-> [peername | acc]
      end

    end, [], @stable)

    {:reply, spreads_to, cache_table}
  end

  def handle_call(:scan_connections, _from, state) do

    keys = :ets.foldl(fn(datas, acc) ->

      case datas do
        {key, obj} -> [[key, "", ""] | acc]
        {key, obj, dt} -> [[key, dt, get_idle(dt)] | acc]
      end

    end, [], @stable)

    {:reply, keys, state}
  end

  def handle_call(:info, _from, cache_table) do
    data = :dets.info(cache_table)
    {:reply, data, cache_table}
  end

  def handle_call(:read, _from, cache_table) do

    keys = :dets.foldl(fn(datas, acc) ->

      case datas do
        {key, obj} -> acc
        {key, obj, dt} -> [[key, dt] | acc]
      end

    end, [], cache_table)

    # peername = "_development__interline_validate_classes_3_0"

    # data = case :dets.lookup(cache_table, peername) do
    #   [{^peername, data}] -> data
    #   _ -> :ok
    # end

    {:reply, keys, cache_table}
  end

  def populate_peer(socket, transport, cache_ref) do

    data = :dets.foldl(fn(data, acc) ->

      case data do
        {key, message} -> key <> "start" <> message <> "end" <> acc
        {key, message, dt} -> key <> "start" <> message <> "end" <> acc
      end


    end, "", cache_ref)

    transport.send(socket, data)
  end

  ######################## API ##############################

  def get_idle(started) do

    [dt, tm] = String.split(started, " ")
    [y, mo, d] = String.split(dt, "-")
    [h, m, s] = String.split(tm, ":")

    data = {
      {
        String.to_integer(y),
        String.to_integer(mo),
        String.to_integer(d)
      },
      {
        String.to_integer(h),
        String.to_integer(m),
        String.to_integer(s)
      }
    }

    t_now = NaiveDateTime.from_erl!(:calendar.local_time())
    t_start = NaiveDateTime.from_erl!(data)

    mins = NaiveDateTime.diff(t_now, t_start) / 60
    mins
  end

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

  def info() do

    [type: tp, keypos: kp, size: sz, file_size: fs, filename: fname] = Rancho.Stable
      |> GenServer.call(:info)

    %{
      keys: sz,
      file_size: fs/1000000,
      connections: Rancho.Stable.scan_connections()
    }
  end
end