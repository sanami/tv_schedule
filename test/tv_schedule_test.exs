defmodule TvScheduleTest do
  use ExUnit.Case
  import TvSchedule

  @channel1 File.read! "test/fixtures/1644.json"
  @event1 File.read! "test/fixtures/203043290.json"
  @event2 File.read! "test/fixtures/203059401.json"

  setup do
    TvSchedule.Options.start_link
    :ok
  end

  test "cache" do
    assert String.ends_with?(cache_file_path("1"), ".json")

    save_cache("1", "12")
    assert load_cache("0", true) == nil
    assert load_cache("1", false) == "12"
    assert load_cache("1", true) == nil
  end

  test "get_channel" do
    res = String.length(get_channel(1644, Date.utc_today, true))
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

    # shift
    res = process_time("18:30", date1, "717")
    assert res.hour == 15
    assert res.minute == 30
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

    assert TvSchedule.Options.get(:ignore_names) == res
  end

  test "load_channel" do
    res = parse_channel(@channel1) |> load_channel
    IO.inspect res
    assert length(res.items) == 3
  end

  test "print_channel" do
    parse_channel(@channel1) |> print_channel
  end

  test "get_date" do
    assert get_date(:today) == Date.utc_today
    assert get_date("2023-03-02") == Date.new!(2023, 3, 2)
    assert get_date(2) == Date.add(Date.utc_today, 2)
    assert get_date("2") == Date.add(Date.utc_today, 2)
  end

  test "logger" do
    IO.inspect Logger.level
    assert Logger.level == :debug

    Logger.configure(level: :info)
    IO.inspect Logger.level
    assert Logger.level == :info
  end

  test "run", do: TvSchedule.run(:today, [1644, 1502])
end
