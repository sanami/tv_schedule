defmodule ExToolsTest do
  use ExUnit.Case
  doctest ExTools

  test "greets the world" do
    assert ExTools.hello(:run, 1) == :world
  end
end
