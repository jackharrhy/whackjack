defmodule Whack.Game do
  alias Whack.Player
  require Logger

  @derive Jason.Encoder
  defstruct messages: [],
            code: nil,
            state: :setup,
            players: [],
            host: nil

  @max_players 8

  @type game_state :: :setup | :playing

  @type t :: %__MODULE__{
          messages: [String.t()],
          code: String.t() | nil,
          state: game_state,
          players: [Player.t()],
          host: String.t() | nil
        }

  @spec new(String.t()) :: t()
  def new(code) do
    struct!(
      __MODULE__,
      messages: [
        "game #{code} created"
      ],
      code: code
    )
  end

  @spec put_game_into_state(t(), game_state) :: t()
  def put_game_into_state(game, state) do
    Map.put(game, :state, state)
  end

  @spec new_message(t(), String.t()) :: t()
  def new_message(game, message) do
    game |> Map.put(:messages, [message | game.messages])
  end

  @spec add_player(t(), String.t(), String.t()) ::
          {:ok, t(), Player.t()} | {:error, atom()}
  def add_player(game, player_id, player_name) do
    if game.state == :setup do
      if length(game.players) >= @max_players do
        {:error, :game_full}
      else
        player = Player.new(player_id, player_name)

        game =
          if is_nil(game.host) do
            Map.put(game, :host, player_id)
          else
            game
          end

        Logger.debug("#{game.code}: Player #{player} joined")

        game =
          game
          |> Map.put(:players, game.players ++ [player])
          |> new_message("player #{player} joined")

        {:ok, game, player}
      end
    else
      {:error, :game_not_in_setup}
    end
  end

  @spec start_game(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def start_game(game, player_id) do
    with :ok <- is_player_host(game, player_id),
         :ok <- is_game_in_state(game, :setup),
         :ok <- max_players_reached(game),
         game <- put_game_into_state(game, :playing) do
      game = game |> new_message("game started")

      {:ok, game}
    end
  end

  @spec get_player_by_id(t(), String.t()) :: {:ok, Player.t()} | {:error, atom()}
  def get_player_by_id(game, player_id) do
    player = Enum.find(game.players, fn player -> player.id == player_id end)

    if player do
      {:ok, player}
    else
      {:error, :player_not_found}
    end
  end

  @spec is_game_in_state(t(), game_state) :: :ok | {:error, atom()}
  def is_game_in_state(game, state) do
    if game.state == state do
      :ok
    else
      {:error, :game_not_in_state}
    end
  end

  @spec get_player_index(t(), String.t()) :: non_neg_integer() | nil
  def get_player_index(game, player_id) do
    Enum.find_index(game.players, fn player -> player.id == player_id end)
  end

  @spec max_players_reached(t()) :: :ok | {:error, atom()}
  def max_players_reached(game) do
    if max_players_reached?(game) do
      :ok
    else
      {:error, :not_enough_players}
    end
  end

  @spec max_players_reached?(t()) :: boolean()
  def max_players_reached?(game) do
    length(game.players) == game.max_players
  end

  @spec is_player_host(t(), String.t()) :: :ok | {:error, atom()}
  def is_player_host(game, player_id) do
    if is_player_host?(game, player_id) do
      :ok
    else
      {:error, :not_host}
    end
  end

  @spec is_player_host?(t(), String.t()) :: boolean()
  def is_player_host?(game, player_id) do
    player_id == game.host
  end
end
