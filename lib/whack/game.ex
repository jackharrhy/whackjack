defmodule Whack.Game do
  require Logger

  alias Whack.Player
  alias Whack.Enemy
  alias Whack.Deck
  alias Whack.Hand

  @derive Jason.Encoder
  defstruct messages: [],
            code: nil,
            state: :setup,
            turn_state: nil,
            players: [],
            enemies: [],
            turn: nil,
            host: nil

  @max_players 4
  @max_enemies 4

  @type game_state :: :setup | :playing | :busy
  @type turn_state :: :hit | :stand | :busted

  @type t :: %__MODULE__{
          messages: [String.t()],
          code: String.t() | nil,
          state: game_state,
          turn_state: turn_state,
          players: [Player.t()],
          enemies: [Enemy.t()],
          host: String.t() | nil,
          turn: String.t() | nil
        }

  @spec new(String.t()) :: t()
  def new(code) do
    struct!(
      __MODULE__,
      messages: ["game #{code} created"],
      code: code
    )
  end

  @spec reset_game(t()) :: {:ok, t()}
  def reset_game(game) do
    {:ok, new(game.code)}
  end

  @spec new_message(t(), String.t()) :: t()
  def new_message(game, message) do
    game |> Map.put(:messages, [message | game.messages])
  end

  @spec add_player(t(), String.t(), String.t(), String.t() | nil) ::
          {:ok, t(), Player.t()} | {:error, atom()}
  def add_player(game, player_id, player_name, image_path) do
    if game.state == :setup do
      if length(game.players) >= @max_players do
        {:error, :game_full}
      else
        player = Player.new(player_id, player_name, image_path)

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

  @spec add_enemy(t(), Enemy.t()) :: {:ok, t(), Enemy.t()} | {:error, atom()}
  def add_enemy(game, enemy) do
    if length(game.enemies) >= @max_enemies do
      {:error, :max_enemies_reached}
    else
      Logger.debug("#{game.code}: Enemy #{enemy} appeared")

      game =
        game
        |> Map.put(:enemies, game.enemies ++ [enemy])
        |> new_message("enemy #{enemy} appeared")

      {:ok, game, enemy}
    end
  end

  @spec start_game(t(), String.t()) :: {:ok, [{integer(), t()}]} | {:error, atom()}
  def start_game(game, player_id) do
    with :ok <- is_player_host(game, player_id),
         :ok <- is_game_in_state(game, :setup),
         :ok <- max_players_reached(game) do
      suits =
        Deck.fresh_deck()
        |> Deck.shuffle()
        |> Deck.split_by_suits()
        |> Tuple.to_list()
        |> Enum.shuffle()

      game = Map.put(game, :state, :busy)

      game_states =
        Enum.reduce(Enum.zip([game.players, suits]), [game], fn {player, suit}, [game | games] ->
          player = Map.put(player, :draw_pile, suit)
          next_game = game |> update_player(player)
          [next_game | [game | games]]
        end)

      enemy_names = ["evil", "monster", "creepy", "spooky"]

      suits = suits |> Enum.shuffle()

      game_states =
        Enum.reduce(Enum.zip([1..4, suits]), [hd(game_states) | game_states], fn {i, suit},
                                                                                 [game | games] ->
          enemy_id = "enemy_#{i}"
          enemy_name = Enum.at(enemy_names, i - 1)

          enemy =
            Enemy.new(enemy_id, enemy_name, 10)
            |> Map.put(:draw_pile, suit)

          {:ok, updated_game, _enemy} = add_enemy(game, enemy)
          [updated_game | [game | games]]
        end)

      [game | _] = game_states

      game =
        game
        |> Map.put(:state, :playing)
        |> Map.put(:turn, game.host)
        |> Map.put(:turn_state, :hit)

      game_states = [game | game_states]

      state_changes =
        game_states
        |> Enum.map(&{250, &1})
        |> Enum.reverse()

      {:ok, state_changes}
    end
  end

  @spec hit(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def hit(game, player_id) do
    {:ok, player} = get_player_by_id(game, player_id)

    with :ok <- is_game_in_state(game, :playing),
         :ok <- is_players_turn(game, player_id),
         :ok <- is_turn_in_state(game, :hit),
         :ok <- can_draw_from_draw_pile(player),
         :ok <- Hand.hand_not_busted(player.hand) do
      [top_card | draw_pile] = player.draw_pile
      hand = [top_card | player.hand || []]
      hand_value = Hand.calculate_value_of_hand(hand)
      busted_this_turn = !Hand.hand_not_busted?(hand)

      player =
        player
        |> Map.put(:draw_pile, draw_pile)
        |> Map.put(:hand, hand)
        |> Map.put(:hand_value, hand_value)

      game = game |> update_player(player) |> new_message("#{player.name} drew #{top_card}")

      game =
        if busted_this_turn do
          game |> new_message("#{player.name} busted!") |> Map.put(:turn_state, :busted)
        else
          game
        end

      {:ok, game}
    end
  end

  @spec stand(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def stand(game, player_id) do
    with :ok <- is_game_in_state(game, :playing),
         :ok <- is_players_turn(game, player_id) do
      game = game |> new_message("player #{player_id} stood")

      {:ok, game}
    end
  end

  @spec get_player_by_id(t(), String.t()) :: Player.t() | nil
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

  @spec is_turn_in_state(t(), turn_state) :: :ok | {:error, atom()}
  def is_turn_in_state(game, state) do
    if game.turn_state == state do
      :ok
    else
      {:error, :turn_not_in_state}
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
    length(game.players) == @max_players
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

  @spec is_players_turn(t(), String.t()) :: :ok | {:error, atom()}
  def is_players_turn(game, player_id) do
    if is_players_turn?(game, player_id) do
      :ok
    else
      {:error, :not_players_turn}
    end
  end

  @spec is_players_turn?(t(), String.t()) :: boolean()
  def is_players_turn?(game, player_id) do
    player_id == game.turn
  end

  @spec can_draw_from_draw_pile(Player.t()) :: :ok | {:error, atom()}
  def can_draw_from_draw_pile(player) do
    if can_draw_from_draw_pile?(player) do
      :ok
    else
      {:error, :cannot_draw_from_draw_pile}
    end
  end

  @spec can_draw_from_draw_pile?(Player.t()) :: boolean()
  def can_draw_from_draw_pile?(player) do
    length(player.draw_pile) > 0
  end

  @spec update_player(t(), Player.t()) :: t()
  def update_player(game, player) do
    update_in(game.players, fn players ->
      Enum.map(players, fn p ->
        if p.id == player.id, do: player, else: p
      end)
    end)
  end
end
