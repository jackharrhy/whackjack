defmodule WhackWeb.PlayerComponent do
  require IEx

  use WhackWeb, :live_component

  require Logger

  alias Whack.GameServer

  def render(assigns) do
    ~H"""
    <div class="h-full">
      <.svelte
        ssr={false}
        name="Player"
        socket={@socket}
        props={%{game: @game, player: @player, myself: @myself.cid}}
        class="h-full"
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

  def handle_event("hit", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.hit(game.code, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "Hit failed: #{reason}")}
    end
  end

  def handle_event("stand", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.stand(game.code, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "Stand failed: #{reason}")}
    end
  end

  defp put_temporary_flash(socket, level, message) do
    push_event(socket, "flash", %{level: level, message: message})
  end
end
