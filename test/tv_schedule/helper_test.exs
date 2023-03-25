defmodule TvSchedule.HelperTest do
  use ExUnit.Case

  import TvSchedule.Helper

  @channel1 File.read! "test/fixtures/1644.json"

  test "replace_html_entities" do
    assert replace_html_entities("<p>A&nbsp;B</p>") == <<?A, 194, 160, ?B>>
  end

  test "process_time" do
    date1 = Date.utc_today
    res = process_time("18:30", date1)
    IO.inspect res

    assert NaiveDateTime.to_date(res) == date1
    assert res.hour == 18
    assert res.minute == 30

    # night
    res = process_time("03:30", date1, nil, true)
    IO.inspect NaiveDateTime.to_date(res) == Date.add(date1, 1)

    res = process_time("03:30", date1, nil, false)
    IO.inspect NaiveDateTime.to_date(res) == date1

    # shift
    res = process_time("18:30", date1, "717")
    assert res.hour == 16
    assert res.minute == 30
  end

  test "get_date" do
    assert get_date(:today) == Date.utc_today
    assert get_date("2023-03-02") == Date.new!(2023, 3, 2)
    assert get_date(2) == Date.add(Date.utc_today, 2)
    assert get_date("2") == Date.add(Date.utc_today, 2)
  end

  test "filter_items" do
    TvSchedule.Settings.start_link
    channel = TvSchedule.Parser.MR.parse_channel(@channel1)

    res = filter_items(channel.items, by_time: true, min_duration: 90)
    IO.inspect res
    assert length(res) <= 3

    res = filter_items(channel.items, by_time: false)
    IO.inspect res
    assert length(res) > 3
  end
end
