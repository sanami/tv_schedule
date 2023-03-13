defmodule TvSchedule.Cache.Test do
  use ExUnit.Case

  import TvSchedule.Cache

  test "cache" do
    assert String.ends_with?(cache_file_path("test1"), "/test1")

    save_cache("test1", "12")
    assert load_cache("test0", true) == nil
    assert load_cache("test1", false) == "12"
    assert load_cache("test1", true) == nil
  end
end
