defmodule TvSchedule.CLI do
  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    parse =
      OptionParser.parse(argv,
        switches: [help: :boolean],
        aliases: [h: :help]
      )

    case parse do
      {[help: true], _, _} ->
        :help

      {_, [date_str], _} ->
        {:run, date_str}

      _ ->
        {:run, :today}
    end
  end

  def process(:help) do
    IO.puts("""
      usage: tv_schedule [ date | today ]
      """)
    # System.halt(0)
  end

  def process({:run, date_str}) do
    TvSchedule.run(date_str)
  end
end
