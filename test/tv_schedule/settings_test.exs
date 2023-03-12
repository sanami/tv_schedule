defmodule TvSchedule.Settings.Test do
  use ExUnit.Case
  import TvSchedule.Settings

  setup do
    TvSchedule.Settings.start_link
    :ok
  end

  test "get" do
    assert MapSet.size(get(:ignore_names)) > 10
    assert length(get(:ignore_rx)) > 0
  end

  test "ignore?" do
    assert ignore?("31 Әзіл") == true
    assert ignore?("xxx") == false
    assert ignore?("Түрік телехикаясы") == true
    assert ignore?("Телехикаясы") == true
    assert ignore?("теле хикаясы") == false
  end
end
