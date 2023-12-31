defmodule TvCLI.ToolTest do
  use ExUnit.Case

  import TvCLI.Tool

  test "parse_args" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["--help", "anything"]) == :help

    assert parse_args([]) == {:run, :today}

    assert parse_args(["2023-03-2"]) == {:run, "2023-03-2"}
  end

  test "process help" do
    res = ExUnit.CaptureIO.capture_io fn ->
      process(:help)
    end

    IO.inspect res
    assert String.starts_with?(res, "usage: ")
  end
end
