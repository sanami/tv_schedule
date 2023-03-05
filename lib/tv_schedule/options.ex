defmodule TvSchedule.Options do
  use Agent

  def start_link do
    ignore_names = TvSchedule.load_ignore_names()
    Agent.start_link(fn -> %{ignore_names: ignore_names} end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, &(&1[key]))
  end
end
