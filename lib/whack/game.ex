defmodule Whack.Game do
  require Logger

  alias Whack.Character
  alias Whack.Player
  alias Whack.Enemy
  alias Whack.Deck
  alias Whack.Hand
  alias Whack.Card

  @derive Jason.Encoder
  defstruct messages: [],
            code: nil,
            state: :setup,
            draw_piles: [],
            players: [],
            enemies: [],
            turn: nil,
            host: nil

  @max_players 4
  @max_enemies 4

  @short_delay 300
  @long_delay 800

  @type game_state :: :setup | :playing | :busy

  @type t :: %__MODULE__{
          messages: [String.t()],
          code: String.t() | nil,
          state: game_state,
          draw_piles: [[Card.t()]],
          players: [Player.t()],
          enemies: [Enemy.t()],
          host: String.t() | nil,
          turn: String.t() | nil
        }

  @spec new(String.t()) :: t()
  def new(code) do
    if not (is_binary(code) and String.length(code) == 4 and code == String.upcase(code)) do
      raise ArgumentError, "Code must be a 4-character string of capital letters"
    end

    draw_piles = Deck.fresh_deck() |> Deck.shuffle() |> List.duplicate(2)

    struct!(
      __MODULE__,
      messages: ["game #{code} created"],
      draw_piles: draw_piles,
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

  @spec add_enemy(t(), Enemy.t(), [Card.t()]) :: {:ok, t(), Enemy.t()} | {:error, atom()}
  def add_enemy(game, enemy, draw_pile) do
    if length(game.enemies) >= @max_enemies do
      {:error, :max_enemies_reached}
    else
      Logger.debug("#{game.code}: Enemy #{enemy} appeared")

      game =
        game
        |> Map.put(:enemies, game.enemies ++ [enemy])
        |> new_message("enemy #{enemy} appeared")

      enemy = enemy |> Map.put(:draw_pile, draw_pile)

      next_game = game |> update_enemy(enemy)

      {:ok, {game, next_game}, enemy}
    end
  end

  @spec start_game(t(), String.t()) :: {:ok, [{integer(), t()}]} | {:error, atom()}
  def start_game(game, player_id) do
    with :ok <- is_player_host(game, player_id),
         :ok <- is_game_in_state(game, :setup),
         :ok <- max_players_reached(game) do
      [player_deck, enemy_deck] = game.draw_piles
      player_suits = player_deck |> Deck.split_by_suits() |> Tuple.to_list()
      enemy_suits = enemy_deck |> Deck.split_by_suits() |> Tuple.to_list()

      game = Map.put(game, :state, :busy)

      game_states =
        Enum.reduce(Enum.zip([game.players, player_suits]), [game], fn {player, suit},
                                                                       [game | games] ->
          player = Map.put(player, :draw_pile, suit)

          [player_deck, enemy_deck] = game.draw_piles

          player_deck =
            Enum.reject(player_deck, fn card ->
              Enum.any?(suit, fn suit_card -> suit_card.id == card.id end)
            end)

          draw_piles = [player_deck, enemy_deck]

          next_game =
            game
            |> update_player(player)
            |> Map.put(:draw_piles, draw_piles)

          [next_game | [game | games]]
        end)

      enemy_names = ["evil", "monster", "creepy", "spooky"]

      game_states =
        Enum.reduce(Enum.zip([1..4, enemy_suits]), [hd(game_states) | game_states], fn {i, suit},
                                                                                       [
                                                                                         game
                                                                                         | games
                                                                                       ] ->
          enemy_id = "enemy_#{i}"
          enemy_name = Enum.at(enemy_names, i - 1)

          suit = suit |> Enum.shuffle()

          enemy =
            Enemy.new(enemy_id, enemy_name, 10, 14)

          {:ok, {game_with_enemy, game_with_enemy_and_draw_pile}, _enemy} =
            add_enemy(game, enemy, suit)

          [player_deck, enemy_deck] = game_with_enemy_and_draw_pile.draw_piles

          enemy_deck =
            Enum.reject(enemy_deck, fn card ->
              Enum.any?(suit, fn suit_card -> suit_card.id == card.id end)
            end)

          draw_piles = [player_deck, enemy_deck]

          game_with_enemy_and_draw_pile =
            game_with_enemy_and_draw_pile |> Map.put(:draw_piles, draw_piles)

          [game_with_enemy_and_draw_pile | [game_with_enemy | [game | games]]]
        end)

      [game | _] = game_states

      game =
        game
        |> Map.put(:state, :playing)
        |> Map.put(:turn, game.host)

      game_states = [game | game_states]

      state_changes =
        game_states
        |> Enum.reverse()
        |> Enum.with_index()
        |> Enum.map(fn {game, index} ->
          if index == 0 do
            {0, game}
          else
            {@long_delay, game}
          end
        end)

      Logger.debug("Starting game, #{length(state_changes)} state changes to apply")

      {:ok, state_changes}
    end
  end

  @spec hit(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def hit(game, player_id) do
    with {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_game_in_state(game, :playing),
         :ok <- is_players_turn(game, player_id),
         :ok <- Character.is_turn_in_state(player, :hit),
         :ok <- Character.can_draw_from_draw_pile(player),
         :ok <- Hand.hand_not_busted(player.hand) do
      [top_card | _] = player.draw_pile
      {:ok, player} = player |> Player.perform_hit()
      busted_this_turn = !Hand.hand_not_busted?(player.hand)

      game =
        game
        |> update_player(player)
        |> new_message("#{player.name} drew #{top_card}")

      games =
        if busted_this_turn do
          game =
            game
            |> new_message("#{player.name} busted!")

          perform_enemy_turns(game, player, player_can_make_move: false)
        else
          perform_enemy_turns(game, player, player_can_make_move: true)
        end

      games = games ++ [game]

      state_changes = finalize_move(games, player_id)

      Logger.debug("Hit complete, #{length(state_changes)} state changes to apply")

      {:ok, state_changes}
    end
  end

  @spec stand(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def stand(game, player_id) do
    with :ok <- is_game_in_state(game, :playing),
         {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_players_turn(game, player_id),
         :ok <- Character.is_turn_in_state(player, :hit) do
      {:ok, player} = Character.perform_stand(player)

      game = game |> update_player(player) |> new_message("player #{player_id} stood")

      games = perform_enemy_turns(game, player, player_can_make_move: false) ++ [game]

      state_changes = finalize_move(games, player_id)

      Logger.debug("Stand complete, #{length(state_changes)} state changes to apply")

      {:ok, state_changes}
    end
  end

  def finalize_move(games, player_id) do
    [first_game | games] = games

    {:ok, player} = get_player_by_id(first_game, player_id)
    {:ok, enemy} = get_players_enemy(first_game, player_id)

    games =
      if !Character.can_continue_making_moves?(player, enemy) do
        first_game = first_game |> new_message("#{player.name} vs #{enemy.name} is over")
        [first_game | games]
      else
        [first_game | games]
      end

    state_changes =
      games
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn {game, index} ->
        if index == 0 do
          {0, game}
        else
          {@short_delay, game}
        end
      end)

    state_changes
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

  @spec get_player_index(t(), String.t()) :: non_neg_integer() | nil
  def get_player_index(game, player_id) do
    Enum.find_index(game.players, fn player -> player.id == player_id end)
  end

  @spec get_players_enemy(t(), String.t()) :: {:ok, Enemy.t()} | {:error, atom()}
  def get_players_enemy(game, player_id) do
    case get_player_index(game, player_id) do
      nil ->
        {:error, :player_not_found}

      player_index ->
        case Enum.at(game.enemies, player_index) do
          nil -> {:error, :enemy_not_found}
          enemy -> {:ok, enemy}
        end
    end
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

  @spec update_player(t(), Player.t()) :: t()
  def update_player(game, player) do
    update_in(game.players, fn players ->
      Enum.map(players, fn p ->
        if p.id == player.id, do: player, else: p
      end)
    end)
  end

  @spec update_enemy(t(), Enemy.t()) :: t()
  def update_enemy(game, enemy) do
    update_in(game.enemies, fn enemies ->
      Enum.map(enemies, fn e ->
        if e.id == enemy.id, do: enemy, else: e
      end)
    end)
  end

  defp perform_enemy_turns(game, player, opts) do
    player_can_make_move = Keyword.fetch!(opts, :player_can_make_move)
    perform_enemy_turns(game, player, player_can_make_move, [])
  end

  defp perform_enemy_turns(game, player, player_can_make_move, acc) do
    {:ok, enemy} = get_players_enemy(game, player.id)

    case enemy.turn_state do
      state when state in [:busted, :stand] ->
        [game | acc]

      _ ->
        game = perform_enemy_turn(game, player)

        if player_can_make_move do
          [game | acc]
        else
          perform_enemy_turns(game, player, player_can_make_move, acc)
        end
    end
  end

  defp perform_enemy_turn(game, player) do
    {:ok, enemy} = get_players_enemy(game, player.id)
    {:ok, updated_enemy} = Enemy.perform_turn(enemy)
    game = game |> update_enemy(updated_enemy)

    case updated_enemy.turn_state do
      :hit ->
        [top_card | _] = updated_enemy.hand
        game |> new_message("#{updated_enemy.name} drew #{top_card}")

      :stand ->
        if enemy.turn_state != :stand do
          game |> new_message("#{updated_enemy.name} stood")
        else
          game
        end

      :busted ->
        if enemy.turn_state != :busted do
          game |> new_message("#{updated_enemy.name} busted!")
        else
          game
        end
    end
  end
end
