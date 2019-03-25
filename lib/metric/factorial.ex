defmodule Rancho.Factorial do
  def iter(n) do
    Enum.reduce(1..n, 1, &*/2)
  end

  def recur(0), do: 1

  def recur(n) when n > 0 do
    n * recur(n - 1)
  end
end
