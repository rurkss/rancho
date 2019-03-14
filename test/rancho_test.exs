defmodule RanchoTest do
  use ExUnit.Case
  doctest Rancho

  test "greets the world" do
    assert Rancho.hello() == :world
  end
end
