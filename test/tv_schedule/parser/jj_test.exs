defmodule TvSchedule.Parser.JJTest do
  use ExUnit.Case
  import TvSchedule.Parser.JJ

  @channel1 File.read!("test/fixtures/5.html")
  @date1 ~D[2023-03-11]

  describe "get_channel" do
    test "invalid" do
      res = get_channel(nil, @date1)
      assert res == nil
    end

    test "ok" do
      res = get_channel(nil, Date.utc_today)
      assert String.length(res) > 50000
    end
  end

  describe "parse_channel" do
    test "empty" do
      res = parse_channel(nil, @date1)
      IO.inspect res
      assert res[:items] == []
    end

    test "ok" do
      res = parse_channel(@channel1, @date1)
      IO.inspect res
      assert length(res[:items]) == 21
    end
  end
end
