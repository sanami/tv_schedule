defmodule TvScheduleTest do
  use ExUnit.Case
  import TvSchedule

  @channel1 File.read! "test/fixtures/1644.json"

  setup do
    TvSchedule.Settings.start_link
    :ok
  end

  test "print_channel" do
    TvSchedule.Parser.MR.parse_channel(@channel1) |> print_channel
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
