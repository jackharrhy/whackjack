import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :crazy8, Crazy8Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vk0XVo9wiHE+vpk11SPF6sWznJfWiPSy9A12ydacuX26D7o035WeHtmvOH3fCXlA",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
