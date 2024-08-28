defmodule Crazy8.GameServer do
  use GenServer

  alias Crazy8.Game

  require Logger

  def start_link(code) do
    Logger.info("Starting up game server #{code}")
    GenServer.start(__MODULE__, code, name: via_tuple(code))
  end

  defp via_tuple(code) do
    {:via, Registry, {Crazy8.GameRegistry, code}}
  end

  def game_pid(code) do
    code
    |> via_tuple()
    |> GenServer.whereis()
  end

  def game_exists?(code) do
    game_pid(code) != nil
  end

  defp call_by_code(code, command) do
    id = game_pid(code)
    IO.inspect(code |> via_tuple)

    case game_pid(code) do
      game_pid when is_pid(game_pid) ->
        GenServer.call(game_pid, command)

      nil ->
        {:error, :game_not_found}
    end
  end

  def get_game(code) do
    call_by_code(code, :get_game)
  end

  def get_player_by_id(code, player_id) do
    call_by_code(code, {:get_player_by_id, player_id})
  end

  def add_player(code, player_id, player_name) do
    call_by_code(code, {:add_player, player_id, player_name})
  end

  def broadcast!(code, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Crazy8.PubSub, code, %{event: event, payload: payload})
  end

  defp broadcast_game_updated!(code, game) do
    broadcast!(code, :game_updated, %{game: game})
  end

  @impl GenServer
  def init(code) do
    Logger.info("Creating game server with code #{code}")
    {:ok, %{game: Game.new(code)}}
  end

  @impl GenServer
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call({:add_player, player_id, player_name}, _from, state) do
    case Game.add_player(state.game, player_id, player_name) do
      {:ok, game, player} ->
        {:reply, {:ok, game, player}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_info({:put_game_into_state, game_state}, state) do
    Logger.info("Putting game state from #{inspect(state.game.state)} to #{inspect(game_state)}")
    game = Game.put_game_into_state(state.game, game_state)
    broadcast_game_updated!(game.slug, game)
    {:noreply, %{state | game: game}}
  end
end
