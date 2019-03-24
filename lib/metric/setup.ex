defmodule Rancho.Metric.Setup do
  use Prometheus.Metric

  def setup do
    Prometheus.Registry.register_collector(:prometheus_process_collector)

    config = Application.get_env(:rancho, :server)

    Gauge.declare([name: :connection_pool_size,
                     help: "Connection pool size."])
    Gauge.declare([name: :connection_pool_checked_out,
                   help: "Number of connection checked out from the pool"])

    Gauge.set([name: :connection_pool_size], config[:max_connections]+config[:num_acceptors])

    Gauge.set([name: :connection_pool_checked_out], 0)


  end
end
