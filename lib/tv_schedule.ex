defmodule TvSchedule do
  require Logger

  def get_url(url, sleep \\ true) do
    if sleep do
      Process.sleep :rand.uniform(5000)
    end

    %{status_code: 200, body: body} = HTTPoison.get! url

    body
  end

  def replace_html_entities(nil), do: ""

  def replace_html_entities(str) do
    str
    |> String.replace(~r/\<[^\>]+\>/, "") # <tag>
    |> HtmlEntities.decode
  end

  def process_time(time_str, date, channel_id \\ nil, night_time \\ true) do
    [hour, minute] = String.split(time_str, ":")
    {hour, _} = Integer.parse(hour)
    {minute, _} = Integer.parse(minute)

    time = Time.new!(hour, minute, 0)
    date_time = NaiveDateTime.new!(date, time)

    date_time = if night_time && hour <= 4 do
      NaiveDateTime.add(date_time, 60*60*24, :second) #TODO :day
    else
      date_time
    end

    shift_min = if channel_id == "717", do: -120, else: 0
    NaiveDateTime.add(date_time, shift_min*60, :second) #TODO :minute
  end

  def filter_items(items, options \\ []) do
   by_time = Keyword.get(options, :by_time)
   min_duration = Keyword.get(options, :min_duration) || 0

    Enum.filter(items, fn item ->
      (!by_time || ((item.time.hour in 15..23) || (item.time.hour in 0..2))) &&
      item.duration >= min_duration && !TvSchedule.Settings.ignore?(item.name)
    end)
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

  def get_date(date_str) do
    cond do
      is_number(date_str) -> Date.add(Date.utc_today, date_str)
      is_bitstring(date_str) && date_str =~ ~r/\A\d+\z/ -> Date.add(Date.utc_today, String.to_integer(date_str))
      is_bitstring(date_str) && date_str =~ ~r/\A[\d-]+\z/ -> Date.from_iso8601!(date_str)
      true -> Date.utc_today
    end
  end

  def channel_worker(channel_id, date, parent_pid) do
    channel = case channel_id do
      "jj" ->
        channel_id |> TvSchedule.Parser.JJ.get_channel(date) |> TvSchedule.Parser.JJ.parse_channel(date) |> TvSchedule.Parser.JJ.load_channel
      _ ->
        channel_id |> TvSchedule.Parser.MR.get_channel(date) |> TvSchedule.Parser.MR.parse_channel |> TvSchedule.Parser.MR.load_channel
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

  def run(date_str \\ :today, channel_list \\ [717, 1455, 1606, 1494, "jj", 1644, 1502]) do
    TvSchedule.Settings.start_link

    date = get_date(date_str)
    IO.puts "#{date}"

    result = parent_worker(channel_list, date, %{}, true)

    Enum.each channel_list, fn channel_id ->
      print_channel(result[channel_id])
    end
  end
end
