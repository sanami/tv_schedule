defmodule TvSchedule.Helper do
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

  def get_date(date_str) do
    cond do
      is_number(date_str) -> Date.add(Date.utc_today, date_str)
      is_bitstring(date_str) && date_str =~ ~r/\A\d+\z/ -> Date.add(Date.utc_today, String.to_integer(date_str))
      is_bitstring(date_str) && date_str =~ ~r/\A[\d-]+\z/ -> Date.from_iso8601!(date_str)
      true -> Date.utc_today
    end
  end

  def filter_items(items, options \\ []) do
   by_time = Keyword.get(options, :by_time)
   min_duration = Keyword.get(options, :min_duration) || 0

    Enum.filter(items, fn item ->
      (!by_time || ((item.time.hour in 18..23) || (item.time.hour in 0..2))) &&
      item.duration >= min_duration && !TvSchedule.Settings.ignore?(item.name)
    end)
  end
end
