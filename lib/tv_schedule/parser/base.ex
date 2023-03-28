defmodule TvSchedule.Parser.Base do
  @callback get_channel(String.t | integer, %Date{}, boolean) :: String.t
  @callback parse_channel(String.t | nil, %Date{} | nil) :: %{}
  @callback load_channel(%{}) :: %{}
end
