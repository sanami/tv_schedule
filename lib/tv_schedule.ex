defmodule TvSchedule do
  @host URI.parse("https://tv.mail.ru")

  def load_ignore_names do
    case File.read "config/tv_ignore.txt" do
      {:ok, text} -> text |> String.split("\n") |> Enum.filter(&(String.length(&1) > 0))
      _ -> []
    end
  end

  def get_channel(channel) do
    url = URI.merge(@host, "/astana/channel/#{channel}/")
    %{status_code: 200, body: body} = HTTPoison.get! url

    File.mkdir_p("tmp")
    File.write("tmp/#{channel}.html", body)

    {channel, body}
  end

  def get_item_details(item_id) do
    url = URI.merge(@host, "/ajax/event/?id=#{item_id}&region_id=378")
    %{status_code: 200, body: body} = HTTPoison.get! url

    body
  end

  def replace_html_entities(str) do
    str
    |> String.replace(~r/\<[^\>]+\>/, "") # <tag>
    |> HtmlEntities.decode
  end

  def parse_item_details(json_str) do
    json = Jason.decode!(json_str, keys: :atoms)

    info = %{
      #participants: json.tv_event.participants,
      country: json.tv_event.country |> Enum.map(&(&1.title)),
      name: json.tv_event.name,
      descr: json.tv_event.descr |> replace_html_entities,
      genre: json.tv_event.genre |> Enum.map(&(&1.title)),
      imdb_rating: json.tv_event |> get_in([:afisha_event, :imdb_rating]),
      name_eng: json.tv_event |> get_in([:afisha_event, :name_eng]),
      year: json.tv_event |> get_in([:year, :title])
    }

    info
  end

  def process_item(time, name, today, channel \\ 0) do
    [hour, minute] = String.split(time, ":")
    {hour, _} = Integer.parse(hour)
    {minute, _} = Integer.parse(minute)

    date_time = Map.merge(today, %{hour: hour, minute: minute, second: 0, microsecond: {0, 0}})

    date_time = if hour < 5 do
      DateTime.add(date_time, 60*60*24, :second) #TODO :day
    else
      date_time
    end

    shift_min = if channel == 717, do: -120, else: 0
    date_time = DateTime.add(date_time, shift_min*60, :second) #TODO :minute

    %{time: date_time, name: name}
  end

  def parse_channel({channel, html}, today \\ DateTime.utc_now) do
    {:ok, doc} = Floki.parse_document(html)

    name = doc |> Floki.find(".p-channels__item__info__title") |> Floki.text

    items = Floki.find(doc, ".p-programms__item")
    |> Enum.map(fn (item_el) ->
        time = Floki.find(item_el, ".p-programms__item__time-value") |> Floki.text
        name = Floki.find(item_el, ".p-programms__item__name-link") |> Floki.text
        item_id = Floki.attribute(item_el, "data-id") |> hd

        if String.length(time) > 0 do
          item = process_item(time, name, today, channel)
          Map.merge(item, %{name: name, item_id: item_id})
        end
      end)
    |> Enum.filter(&is_map/1)
    |> Enum.chunk_every(2,1)
    |> Enum.map(fn
        [item] -> Map.put(item, :duration, 0)
        [item, next_item]->
          duration = DateTime.diff(next_item.time, item.time, :second) |> div(60) #TODO :minute
          Map.put(item, :duration, duration)
      end)

    %{channel: channel, name: name, items: items}
  end

  def filter_items(items, ignore_names: ignore_names, by_time: by_time, min_duration: min_duration) do
    Enum.filter(items, fn item ->
      (!by_time || ((item.time.hour in 18..23) || (item.time.hour in 0..2))) &&
      item.duration >= min_duration && !(item.name in ignore_names)
    end)
  end

  def print_schedule(schedule, show_details \\ false) do
    IO.puts "\n#{schedule.name} #{schedule.channel}"

    items = filter_items(schedule.items, ignore_names: load_ignore_names(), by_time: true, min_duration: 45)

    Enum.each items, fn item ->
      time = item.time |> DateTime.to_time |> Time.to_string |> String.slice(0..4)
      dur_hour = item.duration |> div(60) |> to_string |> String.pad_leading(2)
      dur_min = item.duration |> Integer.mod(60)|> to_string |> String.pad_leading(2, "0")

      details = try do
        if show_details do
          data = item.item_id |> get_item_details |> parse_item_details
          "#{data.year} #{Enum.join(data.country, ", ")} #{data.imdb_rating}"
        end
      rescue _ -> nil
      end

      IO.puts "#{time} #{dur_hour}:#{dur_min} #{item.name} #{details} [#{item.item_id}]"
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

  def run do
    for channel <- [1644, 1606, 1502, 717, 1455] do
      channel
      |> get_channel
      |> parse_channel
      |> print_schedule(true)
    end

    :ok
  end
end
