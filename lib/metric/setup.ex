defmodule Rancho.Metric.Setup do
  def setup do
    Prometheus.Registry.register_collector(:prometheus_process_collector)
  end
end
