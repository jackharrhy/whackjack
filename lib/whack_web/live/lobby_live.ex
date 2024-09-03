defmodule WhackWeb.LobbyLive do
  use WhackWeb, :live_view

  require Logger

  alias Whack.GameServer

  def render(assigns) do
    ~H"""
    <.svelte
      name="Lobby"
      socket={@socket}
      props={%{name: @name, code: @code, image_path: @image_path}}
    />
    """
  end

  def handle_event("create-game", _fields, socket) do
    code = GameServer.generate_code()
    {:noreply, push_navigate(socket, to: ~p"/game/#{code}/main")}
  end

  def handle_event("create-single-pane-game", _fields, socket) do
    code = GameServer.generate_code()
    Logger.info("Creating single pane game #{code}")
    {:noreply, push_navigate(socket, to: ~p"/game/#{code}/single-pane")}
  end

  def handle_event("update", fields, socket) do
    %{"code" => code} = fields
    {:noreply, assign(socket, code: code)}
  end

  def handle_event("join-game", fields, socket) do
    %{"code" => code, "name" => name} = fields

    return_to = ~p"/game/#{code}/player"
    setup_to = ~p"/setup?return_to=#{return_to}&name=#{name}"

    if GameServer.game_exists?(code) do
      {:noreply, push_navigate(socket, to: setup_to)}
    else
      {:noreply, assign(socket, error: "#{code}: game not found")}
    end
  end

  def mount(_params, session, socket) do
    image_path = Map.get(session, "image_path")

    socket =
      assign(socket,
        code: "",
        name: "",
        image_path: image_path,
        error: nil,
        dev: Application.fetch_env!(:whack, :dev)
      )

    {:ok, socket}
  end
end
