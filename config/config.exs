import Config

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

config :ex_tools,
  key1: "value1",
  key2: "value2"

# Application.fetch_env!(:ex_tools, :key1)

env_file = "#{config_env()}.exs"
# IO.puts env_file
if File.exists?(env_file), do: import_config(env_file)
