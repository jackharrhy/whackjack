defmodule Crazy8Web.GameLive do
  use Crazy8Web, :live_view

  alias Crazy8.Game
  alias Crazy8.GameServer
  alias Crazy8.GameSupervisor
  alias Crazy8.Card

  require Logger

  def mount(%{"code" => code} = params, %{"session_id" => session_id}, socket) do
    debug = Map.has_key?(params, "debug")

    name = Map.get(params, "name")

    socket =
      assign(socket,
        debug: debug,
        session_id: session_id,
        name: name
      )

    unless GameServer.game_exists?(code) do
      Logger.debug("Starting game #{code}")
      GameSupervisor.start_game(code)
    else
      Logger.debug("Game already exists #{code}")
    end

    {:ok, game} = GameServer.get_game(code)

    auto_join = Map.has_key?(params, "join") || length(game.players) == 0

    socket = assign(socket, game: game)

    socket =
      case GameServer.get_player_by_id(code, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          assign(socket, player: nil)
      end

    socket =
      if connected?(socket) do
        :ok = Phoenix.PubSub.subscribe(Crazy8.PubSub, code)

        can_join = is_nil(socket.assigns.player) && !is_nil(name)

        if can_join && auto_join do
          Logger.debug("Adding self to game #{code}")
          add_self_to_game(socket)
        else
          Logger.debug("Not adding self to game #{code}")
          socket
        end
      else
        socket
      end

    {:ok, socket}
  end

  def mount(%{"code" => code}, _session, socket) do
    {:ok, redirect(socket, to: "/setup?return_to=/game/#{code}")}
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

  def handle_event("play-card", %{"card-index" => card_index}, socket) do
    %{player: player, game: game} = socket.assigns

    card_index = String.to_integer(card_index)

    case GameServer.play_card(game.code, player.id, card_index) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  def handle_event("draw-card", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.draw_card(game.code, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <div class="border-y p-2">
        <div class="flex flex-wrap justify-center items-center gap-4">
          <p>State: <%= @game.state %></p>

          <%= if !is_nil(@player) and @game.state == :setup and Game.is_player_host?(@game, @player.id) do %>
            <.button phx-click="start-game">Start Game</.button>
          <% end %>

          <div class="flex flex-wrap justify-center items-center gap-2">
            <%= for player <- @game.players do %>
              <div class={
                if !is_nil(@player) and player.id == @player.id,
                  do: "bg-red-100 text-red-900 px-3 py-1 rounded-sm border border-red-300",
                  else: "bg-blue-100 text-blue-900 px-3 py-1 rounded-sm border border-blue-300"
              }>
                <%= if @game.state == :setup and Game.is_player_host?(@game, player.id) do %>
                  👑
                <% end %>

                <%= if @game.state == :playing and Game.is_players_turn?(@game, player.id) do %>
                  🡒
                <% end %>
                <%= player.name %> <%= player.art %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%= if @game.state == :playing do %>
        <div class="border-y">
          <div class="flex flex-wrap justify-center items-center min-h-16">
            <div class="flex flex-col items-center">
              <img src={Card.art_url(hd(@game.pile))} class="p-4" />
            </div>
          </div>
        </div>
      <% end %>

      <div class="border-y">
        <%= if @player do %>
          <div class="flex flex-wrap justify-center items-center min-h-16">
            <%= for {card, index} <- Enum.with_index(@player.hand) do %>
              <button
                phx-click="play-card"
                phx-value-card-index={index}
                class="p-0 bg-transparent border-none"
              >
                <img
                  src={Card.art_url(card)}
                  class="p-4 hover:scale-105 transition-transform duration-150"
                />
              </button>
            <% end %>

            <%= if @game.state == :playing and @player && Game.is_players_turn?(@game, @player.id) do %>
              <button
                phx-click="draw-card"
                class="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded ml-4"
              >
                Draw Card
              </button>
            <% end %>

            <%= if Enum.empty?(@player.hand) do %>
              <p class="italic opacity-75">Empty hand</p>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="flex flex-col border-y p-2 h-32 overflow-y-auto">
        <ul class="list-none">
          <%= for message <- @game.messages do %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>

      <%= if @debug do %>
        <div class="bg-black text-white p-4 mb-2">
          <p>player</p>
          <code><pre><%= Jason.encode!(@player, pretty: true) %></pre></code>
          <p>game</p>
          <code><pre><%= Jason.encode!(@game, pretty: true) %></pre></code>
        </div>
      <% end %>
    </div>
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

  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def add_self_to_game(socket) do
    %{
      game: game,
      session_id: session_id,
      name: name
    } = socket.assigns

    case GameServer.add_player(game.code, session_id, name) do
      {:ok, game, player} ->
        socket
        |> assign(game: game, player: player)

      {:error, reason} ->
        socket
        |> put_temporary_flash(:error, "#{reason}")
    end
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
