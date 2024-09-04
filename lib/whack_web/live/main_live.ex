defmodule WhackWeb.MainLive do
  use WhackWeb, :live_view

  alias Whack.GameServer
  alias Whack.GameSupervisor

  require Logger

  def mount(%{"code" => code} = params, _session, socket) do
    debug = Map.has_key?(params, "debug")

    socket = assign(socket, debug: debug)

    unless GameServer.game_exists?(code) do
      Logger.debug("Starting game #{code}")
      GameSupervisor.start_game(code)
    else
      Logger.debug("Game already exists #{code}")
    end

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Whack.PubSub, code)
    end

    {:ok, game} = GameServer.get_game(code)
    socket = assign(socket, game: game)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={WhackWeb.MainComponent} id="main" game={@game} debug={@debug} />
    """
  end

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    socket = assign(socket, game: game)
    {:noreply, socket}
  end
end
