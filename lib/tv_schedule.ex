defmodule TvSchedule do
  @host URI.parse("https://tv.mail.ru")
  @ignore_names ["Әзіл студио", "31 Әзіл", "Әйел дәрігері", "Екі езу", "Бір болайық", "Әулеттер тартысы", "Bizdin show", "What's Up?", "Taboo", "Jaidarman"]

  def get_channel(channel) do
    url = URI.merge(@host, "/astana/channel/#{channel}/")
    %{status_code: 200, body: body} = HTTPoison.get! url

    File.mkdir_p("tmp")
    File.write("tmp/#{channel}.html", body)

    {channel, body}
  end

  def process_item(time, name, today) do
    [hour, minute] = String.split(time, ":")
    {hour, _} = Integer.parse(hour)
    {minute, _} = Integer.parse(minute)

    date_time = Map.merge(today, %{hour: hour, minute: minute, second: 0, microsecond: {0, 0}})

    date_time = if hour < 5 do
      DateTime.add(date_time, 60*60*24, :second) #TODO :day
    else
      date_time
    end

    %{time: date_time, name: name}
  end

  def parse_channel({channel, html}, today \\ DateTime.utc_now) do
    {:ok, doc} = Floki.parse_document(html)

    name = Floki.find(doc, ".p-channels__item__info__title") |> Floki.text

    items = Floki.find(doc, ".p-programms__item > .p-programms__item__inner")
    |> Enum.map(fn (item_el) ->
        time = Floki.find(item_el, ".p-programms__item__time-value") |> Floki.text
        name = Floki.find(item_el, ".p-programms__item__name-link") |> Floki.text

        if String.length(time) > 0 do
          process_item(time, name, today)
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

  def filter_items(items, by_time: by_time, min_duration: min_duration) do
    Enum.filter(items, fn item ->
      (!by_time || ((item.time.hour in 19..23) || (item.time.hour in 0..2))) &&
      item.duration >= min_duration && !(item.name in @ignore_names)
    end)
  end

  def print_schedule(schedule) do
    IO.puts "\n#{schedule.name} #{schedule.channel}"

    items = filter_items(schedule.items, by_time: false, min_duration: 45)

    Enum.each items, fn item ->
      time = DateTime.to_time(item.time) |> Time.to_string |> String.slice(0..4)
      IO.puts "#{time} #{item.name}"
    end
  end

  def run do
    for channel <- [1644, 1606, 1502] do
      get_channel(channel)
      |> parse_channel
      |> print_schedule
    end

    :ok
  end
end
