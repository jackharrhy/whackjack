defmodule Whack.GameServer do
  use GenServer
  alias Whack.Game
  require Logger

  def generate_code() do
    ?a..?z |> Enum.take_random(4) |> List.to_string() |> String.upcase()
  end

  def code_valid?(code) do
    code |> String.match?(~r/^[A-Z]{4}$/)
  end

  def start_link(code) do
    Logger.info("Game server starting #{code}")
    GenServer.start(__MODULE__, code, name: via_tuple(code))
  end

  def game_pid(code) do
    code
    |> via_tuple()
    |> GenServer.whereis()
  end

  def game_exists?(code), do: game_pid(code) != nil

  def get_game(code), do: call_by_code(code, :get_game)
  def get_player_by_id(code, player_id), do: call_by_code(code, {:get_player_by_id, player_id})

  def add_player(code, player_id, player_name, image_path),
    do: call_by_code(code, {:add_player, player_id, player_name, image_path})

  def start_game(code, player_id), do: call_by_code(code, {:start_game, player_id})
  def reset_game(code), do: call_by_code(code, :reset_game)

  def hit(code, player_id), do: call_by_code(code, {:hit, player_id})
  def stand(code, player_id), do: call_by_code(code, {:stand, player_id})

  def broadcast!(code, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Whack.PubSub, code, %{event: event, payload: payload})
  end

  @impl GenServer
  def init(code), do: {:ok, %{game: Game.new(code)}}

  @impl GenServer
  def handle_call(:get_game, _from, state), do: {:reply, {:ok, state.game}, state}

  @impl GenServer
  def handle_call({:add_player, player_id, player_name, image_path}, _from, state) do
    case Game.add_player(state.game, player_id, player_name, image_path) do
      {:ok, game, player} ->
        broadcast_game_updated!(game.code, game)
        {:reply, {:ok, game, player}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_player_by_id, player_id}, _from, state) do
    {:reply, Game.get_player_by_id(state.game, player_id), state}
  end

  @impl GenServer
  def handle_call({:start_game, player_id}, _from, state) do
    case Game.start_game(state.game, player_id) do
      {:ok, state_changes} ->
        handle_state_changes(state_changes)
        {:reply, {:ok, state.game}, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:reset_game, _from, state) do
    {:ok, game} = Game.reset_game(state.game)
    broadcast_game_updated!(game.code, game)
    {:reply, {:ok, game}, %{state | game: game}}
  end

  @impl GenServer
  def handle_call({:hit, player_id}, _from, state) do
    case Game.hit(state.game, player_id) do
      {:ok, state_changes} ->
        handle_state_changes(state_changes)
        {:reply, {:ok, state.game}, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:stand, player_id}, _from, state) do
    case Game.stand(state.game, player_id) do
      {:ok, state_changes} ->
        handle_state_changes(state_changes)
        {:reply, {:ok, state.game}, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_info({:update_game_state, game}, state) do
    broadcast_game_updated!(game.code, game)
    {:noreply, %{state | game: game}}
  end

  defp via_tuple(code), do: {:via, Registry, {Whack.GameRegistry, code}}

  defp call_by_code(code, command) do
    case game_pid(code) do
      game_pid when is_pid(game_pid) -> GenServer.call(game_pid, command)
      nil -> {:error, :game_not_found}
    end
  end

  defp handle_state_changes(state_changes) do
    Enum.reduce(state_changes, 0, fn {delay, game}, acc_delay ->
      total_delay = acc_delay + delay
      :timer.send_after(total_delay, self(), {:update_game_state, game})
      total_delay
    end)
  end

  defp broadcast_game_updated!(code, game) do
    broadcast!(code, :game_updated, %{game: game})
  end
end
