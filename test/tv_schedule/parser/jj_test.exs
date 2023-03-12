defmodule TvSchedule.Parser.JJ.Test do
  use ExUnit.Case
  import TvSchedule.Parser.JJ

  @channel1 File.read!("test/fixtures/5.html")
  @date1 ~D[2023-03-11]

  test "get_channel" do
    res = get_channel(nil, @date1)
    assert String.length(res) > 80000
  end

  test "parse_channel" do
    res = parse_channel(@channel1, @date1)
    IO.inspect res
  end
end
