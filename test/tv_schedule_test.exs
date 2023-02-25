defmodule TvScheduleTest do
  use ExUnit.Case
  import TvSchedule

  @html1 File.read! "test/fixtures/1644.html"

#  test "get_channel" do
#    html = String.length(get_channel(1644))
#    {1644, res} = String.length(html)
#    IO.inspect res
#
#    assert res > 10_000
#  end

  test "parse_channel" do
    res = parse_channel({1644, @html1})
    IO.inspect res

    assert String.length(res.name) == 32
    assert length(res.items) == 15
  end

  test "process_item" do
    today = DateTime.utc_now
    res = process_item("18:30", "name1", today)
    IO.inspect res

    %{name: name, time: time} = res
    assert time.hour == 18
    assert time.minute == 30
    assert name == "name1"

    # shift
    %{time: time} = process_item("18:30", "name1", today, 717)
    assert time.hour == 16
  end

  test "filter_items" do
    channel = parse_channel({1644, @html1})
    assert length(filter_items(channel.items, ignore_names: [], by_time: true, min_duration: 90)) == 2
    assert length(filter_items(channel.items, ignore_names: [], by_time: false, min_duration: 45)) > 2
  end

  test "load_ignore_names" do
    res = load_ignore_names()
    IO.inspect res
    assert length(res) > 1
  end

  test "print_schedule" do
    parse_channel({1644, @html1}) |> print_schedule
  end

#  test "run", do: TvSchedule.run
end
