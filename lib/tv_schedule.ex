defmodule TvSchedule do
  import TvSchedule.Helper

  require Logger

  def get_url(url, sleep \\ true) do
    if sleep do
      Process.sleep :rand.uniform(5000)
    end

    try do
      %{status_code: 200, body: body} = HTTPoison.get! url, timeout: 60_000
      body
    rescue
      ex ->
        Logger.error "!get_url #{url}"
        Logger.error ex
        ""
    end
  end

  def print_channel(channel) do
    IO.puts "\n#{channel.name} [#{channel.id}]"

    Enum.each channel.items, fn item ->
      {primary_name, secondary_name} =
        if item.name_eng && String.length(item.name_eng) > 1 do
          {item.name_eng, item.name}
        else
          {item.name, nil}
        end

      time = item.time |> NaiveDateTime.to_time |> Time.to_string |> String.slice(0..4)
      dur_hour = item.duration |> div(60) |> to_string |> String.pad_leading(2)
      dur_min = item.duration |> Integer.mod(60)|> to_string |> String.pad_leading(2, "0")

      details =
        [secondary_name, "(#{Enum.join(item.genre, ", ")})", item.year, Enum.join(item.country, ", "), item.imdb_rating]
        |> Enum.reject(&(is_nil(&1) || (is_bitstring(&1) && (String.length(&1) == 0 || &1 == "()"))))
        |> Enum.join(" ")

      IO.puts "#{time} #{dur_hour}:#{dur_min} #{primary_name} [#{item.id}] #{details}"
    end

    :ok
  end

  def channel_worker(channel_id, date, parent_pid) do
    channel = case channel_id do
      "jj" ->
        channel_id |> TvSchedule.Parser.JJ.get_channel(date) |> TvSchedule.Parser.JJ.parse_channel(date) |> TvSchedule.Parser.JJ.load_channel
      _ ->
        channel_id |> TvSchedule.Parser.MR.get_channel(date) |> TvSchedule.Parser.MR.parse_channel(date) |> TvSchedule.Parser.MR.load_channel
    end

    send parent_pid, {:channel, channel_id, channel}
  end

  def parent_worker(channel_list, date, result, start_workers \\ false)

  def parent_worker([], _date, result, _start_workers), do: result

  def parent_worker(channel_list, date, result, start_workers) do
    if start_workers do
      Enum.each channel_list, fn (channel_id)->
        spawn_link(TvSchedule, :channel_worker, [channel_id, date, self()])
      end
    end

    receive do
      {:channel, channel_id, channel} ->
        IO.write "#{channel_id} "

        updated_result = Map.put(result, channel_id, channel)
        remaining_channel_list = List.delete(channel_list, channel_id)

        parent_worker(remaining_channel_list, date, updated_result)
    end
  end

  def run(date_str \\ :today, channel_list \\ [1644, 1502]) do
    TvSchedule.Settings.start_link

    date = get_date(date_str)
    IO.puts "#{date}"

    result = parent_worker(channel_list, date, %{}, true)

    Enum.each channel_list, fn channel_id ->
      print_channel(result[channel_id])
    end
  end
end
