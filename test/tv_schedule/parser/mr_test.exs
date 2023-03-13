defmodule TvSchedule.Parser.MR.Test do
  use ExUnit.Case
  import TvSchedule.Parser.MR

  @channel1 File.read! "test/fixtures/1644.json"
  @event1 File.read! "test/fixtures/203043290.json"
  @event2 File.read! "test/fixtures/203059401.json"

  setup do
    TvSchedule.Settings.start_link
    :ok
  end

  test "get_channel" do
    res = String.length(get_channel(1644, Date.utc_today, false))
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
    res = parse_channel(@channel1)
    IO.inspect res

    assert %{id: "1644", name: "НТК"} = res
    assert length(res.items) == 21
  end

  test "load_channel" do
    res = get_channel(1644, Date.utc_today) |> parse_channel |> load_channel
    IO.inspect res
    assert length(res.items) > 1 and length(res.items) < 10
  end
end
