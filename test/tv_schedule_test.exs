defmodule TvScheduleTest do
  use ExUnit.Case
  import TvSchedule

  @channel1 File.read! "test/fixtures/1644.json"
  @event1 File.read! "test/fixtures/203043290.json"
  @event2 File.read! "test/fixtures/203059401.json"

  test "get_channel" do
    res = String.length(get_channel(1644, :today, true))
    IO.inspect res
    assert res > 1000
  end

  test "get_item_details" do
    res = get_item_details("203043290", true)
    assert String.length(res) > 1000
  end

  describe "parse_item_details" do
    test "1" do
      res = parse_item_details(@event1)
      IO.inspect res
      assert is_map(res)
    end

    test "2" do
      res = parse_item_details(@event2)
      IO.inspect res
      assert is_map(res)
    end
  end

  test "parse_channel" do
    date1 = Date.new(2023, 3, 33)

    res = parse_channel(@channel1)
    IO.inspect res

    assert %{date: date1, id: "1644", name: "НТК"} = res
    assert length(res.items) == 21
  end

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
    res = process_time("03:30", date1)
    assert res.hour == 3
    IO.inspect NaiveDateTime.to_date(res) == Date.add(date1, 1)
  end

  test "filter_items" do
    channel = parse_channel(@channel1)

    res = filter_items(channel.items, by_time: true, min_duration: 90)
    IO.inspect res
    assert length(res) == 3

    res = filter_items(channel.items, by_time: false)
    IO.inspect res
    assert length(res) > 3
  end

  test "load_ignore_names" do
    res = load_ignore_names()
    IO.inspect res
    assert length(res) > 1
  end

  test "print_schedule" do
    parse_channel(@channel1) |> print_schedule(true)
  end

  test "get_date" do
    assert get_date(:today) == Date.utc_today
    assert get_date("2023-03-02") == Date.new!(2023, 3, 2)
    assert get_date(2) == Date.add(Date.utc_today, 2)
  end

#  test "run", do: TvSchedule.run
end
