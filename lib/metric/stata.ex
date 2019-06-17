defmodule Rancho.Metric.Stata do
  def generate_info do
    Jiffex.encode!(
      %{
        keys: Rancho.Stable.read(),
        tbl_info: Rancho.Stable.info()
      }

    )
  end
end