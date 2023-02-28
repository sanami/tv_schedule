defmodule TvScheduleTest do
  use ExUnit.Case
  import TvSchedule

  @html1 File.read! "test/fixtures/1644.html"
  @json1 File.read! "test/fixtures/203043290.json"
  @json2 File.read! "test/fixtures/203059401.json"

#  test "get_channel" do
#    html = String.length(get_channel(1644))
#    {1644, res} = String.length(html)
#    IO.inspect res
#
#    assert res > 10_000
#  end

#  test "get_item_details" do
#    res = get_item_details("203043290")
#    assert String.length(res) > 10000
#  end

  test "parse_item_details 1" do
    res = parse_item_details(@json1)
    IO.inspect res
    assert is_map(res)
  end

  test "parse_item_details 2" do
    res = parse_item_details(@json2)
    IO.inspect res
    assert is_map(res)
  end

  test "parse_channel" do
    res = parse_channel({1644, @html1})
    IO.inspect res

    assert String.length(res.name) == 32
    assert length(res.items) == 15
  end

  test "replace_html_entities" do
    assert replace_html_entities("<p>A&nbsp;B</p>") == <<?A, 194, 160, ?B>>
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
    assert length(filter_items(channel.items, by_time: true, min_duration: 90)) == 2
    assert length(filter_items(channel.items, by_time: false)) > 2
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
