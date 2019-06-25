defmodule Rancho.Metric.Stata do
  def generate_info do
    Jiffex.encode!(
      %{
        keys: Rancho.Stable.read(),
        tbl_info: Rancho.Stable.info()
      }

    )
  end

  def check_keys do

    {d, z} = :calendar.local_time()
    {y, mo, d} = d
    {h, m, s} = z

    key = "cache_#{y}#{mo}#{d}#{h}#{m}#{s}"
    value = "value_#{y}#{mo}#{d}#{h}#{m}#{s}"

    Rancho.Stable.spread(key, value)



    # Rancho.Stable.scan_connections()

    [
      ["94.130.20.168:36790", "2019-6-25 9:10:1", 2.3]
    ]
    |> Enum.map(&ping_key(&1, key, value))
  end

  defp ping_key([ip, _dt, _range], key, value) do
    [ip, port] = String.split(ip, ":")

    port = case ip do
      "127.0.0.1" -> 3000
      _ -> 80
    end

    url = "http://#{ip}:#{port}/avia_json/ping_tcp?key=700bc150-cf6c-45cf-bcc1-a0f709704f14&cache_key=#{key}"

    tasks = Enum.reduce(0..25, [], fn(x, acc) ->
      r = Task.async(fn -> request(url) end)
      [r | acc]
    end)

    acc = Enum.reduce(tasks, [],
      fn(task, acc) ->
      body = Task.await(task, 145000)
      [Map.put(Map.put(body, "ip", ip), "value", value) | acc]
    end)

    Jiffex.encode!(acc)
  end

  defp request(url) do
    %HTTPotion.Response{
      body: body,
      headers: _headers,
      status_code: _status
    } = HTTPotion.get(url)

    Jiffex.decode!(body)
  end

end