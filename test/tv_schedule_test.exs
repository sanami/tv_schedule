defmodule TvSchedule.Test do
  use ExUnit.Case
  import TvSchedule

  @channel1 File.read! "test/fixtures/1644.json"

  setup do
    TvSchedule.Settings.start_link
    :ok
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
    res = process_time("03:30", date1, nil, true)
    IO.inspect NaiveDateTime.to_date(res) == Date.add(date1, 1)

    res = process_time("03:30", date1, nil, false)
    IO.inspect NaiveDateTime.to_date(res) == date1

    # shift
    res = process_time("18:30", date1, "717")
    assert res.hour == 16
    assert res.minute == 30
  end

  test "filter_items" do
    channel = TvSchedule.Parser.MR.parse_channel(@channel1)

    res = filter_items(channel.items, by_time: true, min_duration: 90)
    IO.inspect res
    assert length(res) == 3

    res = filter_items(channel.items, by_time: false)
    IO.inspect res
    assert length(res) > 3
  end

  test "print_channel" do
    TvSchedule.Parser.MR.parse_channel(@channel1) |> print_channel
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

  describe "run" do
    test "mr", do: TvSchedule.run(:today, [1644, 1502])
    test "jj", do: TvSchedule.run(:today, ["jj"])
  end
end
