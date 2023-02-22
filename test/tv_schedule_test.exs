defmodule TvScheduleTest do
  use ExUnit.Case
  import TvSchedule

  test "get_channel" do
    html = String.length(get_channel(1644))
    res = String.length(html)
    IO.inspect res

    assert res > 10_000
  end

  test "parse_channel" do
    html1 = File.read! "test/fixtures/1644.html"

    res = parse_channel(html1)
    IO.inspect res

    assert length(res) == 15
  end

  test "process_item" do
    today = DateTime.utc_now
    res = process_item("18:30", "name1", today)
    IO.inspect res

    %{name: name, time: time} = res
    assert name == "name1"
  end

  test "filter_items" do
    html1 = File.read! "test/fixtures/1644.html"

    res = parse_channel(html1) |> filter_items
    IO.inspect res
  end

#  test "run", do: TvSchedule.run
end
