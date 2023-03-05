defmodule TvSchedule do
  require Logger

  @host URI.parse("https://tv.mail.ru")
  @region_id 378

  def load_ignore_names do
    case File.read "config/tv_ignore.txt" do
      {:ok, text} ->
        text |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.filter(&(String.length(&1) > 0))
      _ -> []
    end
  end

  def get_channel(channel_id, date, dump_data \\ false) do
    url = URI.merge(@host, "/ajax/channel/?channel_id=#{channel_id}&date=#{date}&region_id=#{@region_id}")
    Logger.debug "get_channel #{url}"

    %{status_code: 200, body: body} = HTTPoison.get! url

    if dump_data do
      File.mkdir_p("tmp")
      File.write("tmp/#{channel_id}.json", body)
    end

    body
  end

  def get_item_details(item_id, dump_data \\ false) do
    url = URI.merge(@host, "/ajax/event/?id=#{item_id}&region_id=#{@region_id}")
    Logger.debug "get_item_details #{url}"

    %{status_code: 200, body: body} = HTTPoison.get! url

    if dump_data do
      File.mkdir_p("tmp")
      File.write("tmp/#{item_id}.json", body)
    end

    body
  end

  def replace_html_entities(nil), do: ""

  def replace_html_entities(str) do
    str
    |> String.replace(~r/\<[^\>]+\>/, "") # <tag>
    |> HtmlEntities.decode
  end

  def parse_item_details(json_str) do
    json = Jason.decode!(json_str, keys: :atoms)

    info = %{
      #participants: json.tv_event.participants,
      country: (json.tv_event[:country] || []) |> Enum.map(&(&1.title)),
      name: json.tv_event.name,
      descr: json.tv_event.descr |> replace_html_entities,
      genre: (json.tv_event[:genre] || []) |> Enum.map(&(&1.title)),
      imdb_rating: json.tv_event |> get_in([:afisha_event, :imdb_rating]),
      name_eng: json.tv_event |> get_in([:afisha_event, :name_eng]),
      year: json.tv_event |> get_in([:year, :title])
    }

    info
  end

  def process_time(time_str, date) do
    [hour, minute] = String.split(time_str, ":")
    {hour, _} = Integer.parse(hour)
    {minute, _} = Integer.parse(minute)

    time = Time.new!(hour, minute, 0)
    date_time = NaiveDateTime.new!(date, time)

    if hour <= 4 do
      NaiveDateTime.add(date_time, 60*60*24, :second) #TODO :day
    else
      date_time
    end
  end

  def parse_channel(json_str) do
    json = Jason.decode!(json_str, keys: :atoms)

    date = Date.from_iso8601! json.form.date.value

    # %{time: date_time, name: name, id: item_id, duration: duration}
    items = get_in(json, [:schedule, Access.at(0), :event])
    items = (items[:past] ++ items[:current])
    |> Enum.map(fn item ->
      item
      |> Map.take([:id, :name, :category_id])
      |> Map.merge(%{
          time: process_time(item.start, date),
          country: [],
          descr: nil,
          genre: [],
          imdb_rating: nil,
          name_eng: nil,
          year: nil
        })
    end)
    |> Enum.chunk_every(2,1)
    |> Enum.map(fn
        [item] -> Map.put(item, :duration, 0)
        [item, next_item]->
          duration = NaiveDateTime.diff(next_item.time, item.time, :second) |> div(60) #TODO :minute
          Map.put(item, :duration, duration)
      end)

    %{
      id: get_in(json, [:schedule, Access.at(0), :channel, :id]),
      name: get_in(json, [:schedule, Access.at(0), :channel, :name]),
      date: date,
      items: items
    }
  end

  def load_item(item) do
    item_details =
      try do
        item.id |> get_item_details() |> parse_item_details()
      rescue
        ex ->
          Logger.error ex
          %{}
      end

    Map.merge(item, item_details)
  end

  def load_channel(channel) do
    ignore_names = TvSchedule.Options.get(:ignore_names)

    items =
      channel.items
      |> filter_items(ignore_names: ignore_names, by_time: true, min_duration: 45)
      # |> Enum.map(fn item -> load_item(item) end)
      |> Enum.map(&Task.async(fn -> load_item(&1) end))
      |> Enum.map(&Task.await/1)

    %{channel | items: items}
  end

  def filter_items(items, options \\ []) do
   ignore_names = Keyword.get(options, :ignore_names) || []
   by_time = Keyword.get(options, :by_time)
   min_duration = Keyword.get(options, :min_duration) || 0

    Enum.filter(items, fn item ->
      (!by_time || ((item.time.hour in 15..23) || (item.time.hour in 0..2))) &&
      item.duration >= min_duration && !(item.name in ignore_names)
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
        [secondary_name, Enum.join(item.genre, ", "), item.year, Enum.join(item.country, ", "), item.imdb_rating]
        |> Enum.reject(&(is_nil(&1) || (is_bitstring(&1) && String.length(&1) == 0)))
        |> Enum.join(" ")

      IO.puts "#{time} #{dur_hour}:#{dur_min} #{primary_name} [#{item.id}] #{details}"
    end

    :ok
  end

  def print_item(item_id) do
    item_id
    |> get_item_details
    |> parse_item_details
    |> IO.inspect

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

  def run(date_str \\ :today, channel_list \\ [717, 1455, 1606, 1644, 1502]) do
    TvSchedule.Options.start_link

    date = get_date(date_str)
    IO.puts "#{date}"

    for channel <- channel_list do
      channel
      |> get_channel(date)
      |> parse_channel
      |> load_channel
      |> print_channel
    end

    :ok
  end
end
