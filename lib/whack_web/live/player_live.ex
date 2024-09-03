defmodule WhackWeb.PlayerLive do
  use WhackWeb, :live_view

  alias Whack.Game
  alias Whack.GameServer

  require Logger

  def mount(
        %{"code" => code} = params,
        %{"session_id" => session_id, "name" => name} = session,
        socket
      ) do
    debug = Map.has_key?(params, "debug")

    socket =
      assign(socket,
        debug: debug,
        session_id: session_id,
        name: name
      )

    unless GameServer.game_exists?(code) do
      raise "Game #{code} not found"
    end

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Whack.PubSub, code)
    end

    {:ok, game} = GameServer.get_game(code)
    socket = assign(socket, game: game)

    socket =
      case GameServer.get_player_by_id(code, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          image_path = Map.get(session, "image_path")
          {:ok, game, player} = GameServer.add_player(game.code, session_id, name, image_path)
          socket |> assign(game: game, player: player)
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <%= if !is_nil(@player) do %>
      <.live_component
        module={WhackWeb.PlayerComponent}
        id={"player-#{@player.id}"}
        game={@game}
        player={@player}
      />
    <% end %>
    """
  end

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    socket = assign(socket, game: game)

    session_id = socket.assigns.session_id

    socket =
      case Game.get_player_by_id(game, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          assign(socket, player: nil)
      end

    {:noreply, socket}
  end
end
