defmodule WhackWeb.MainComponent do
  use WhackWeb, :live_component

  alias Whack.GameServer

  def render(assigns) do
    ~H"""
    <div class="h-full">
      <.svelte
        name="Main"
        socket={@socket}
        props={%{game: @game, myself: @myself.cid, debug: @debug}}
        class="h-full"
      />
    </div>
    """
  end

  def handle_event("reset-game", _, socket) do
    %{game: game} = socket.assigns

    case GameServer.reset_game(game.code) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}
    end
  end
end
