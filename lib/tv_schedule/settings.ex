defmodule TvSchedule.Settings do
  use Agent

  def start_link do
    {ignore_names, ignore_rx} = load_ignore_names()
    Agent.start_link(fn -> %{ignore_names: ignore_names, ignore_rx: ignore_rx} end, name: __MODULE__)
  end

  def ignore?(key) do
    ignored_name?(key) or ignored_rx?(key)
  end

  def get(key) do
    Agent.get(__MODULE__, &(&1[key]))
  end

  defp load_ignore_names do
    File.read!("config/tv_ignore.txt")
    |> String.split("\n")
    |> Enum.reduce({MapSet.new, []}, fn str, {name_set, rx_list} ->
      str = String.trim(str)

      cond do
        rx_res = Regex.run(~r"\A/(.+)/(\w*)\z", str) ->
          [_, rx_str, rx_mod] = rx_res
          rx = Regex.compile!(rx_str, rx_mod)
          {name_set, [rx|rx_list]}
        str =~ ~r".+" ->
          {MapSet.put(name_set, str), rx_list}
        true ->
          {name_set, rx_list}
      end
    end)
  end

  defp ignored_name?(key) do
    get(:ignore_names) |> MapSet.member?(key)
  end

  defp ignored_rx?(key) do
    get(:ignore_rx) |> Enum.any?(&(key =~ &1))
  end
end
