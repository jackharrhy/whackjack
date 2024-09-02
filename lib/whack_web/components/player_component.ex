defmodule WhackWeb.PlayerComponent do
  require IEx

  use WhackWeb, :live_component

  require Logger

  alias Whack.GameServer

  def render(assigns) do
    ~H"""
    <div>
      <.svelte
        name="Player"
        socket={@socket}
        props={%{game: @game, player: @player, myself: @myself.cid}}
      />
    </div>
    """
  end

  def handle_event("start-game", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.start_game(game.code, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  defp put_temporary_flash(socket, level, message) do
    push_event(socket, "flash", %{level: level, message: message})
  end
end
