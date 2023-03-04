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

# import_config "#{config_env()}.exs"
