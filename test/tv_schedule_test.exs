defmodule TvScheduleTest do
  use ExUnit.Case

  test "get_channel" do
    html = String.length(TvSchedule.get_channel(1644))
    res = String.length(html)
    IO.inspect res
    assert res > 10_000
  end

  test "parse_channel" do
    html1 = File.read! "test/fixtures/1644.html"

    res = TvSchedule.parse_channel(html1)
    IO.inspect res
    assert length(res) == 15
  end

#  test "run", do: TvSchedule.run
end
