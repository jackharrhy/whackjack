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
            host: nil,
            zero_delay: false

  @max_players 4
  @max_enemies 4

  @long_delay 800

  @type game_state :: :setup | :playing | :busy

  @type t :: %__MODULE__{
          messages: [String.t()],
          code: String.t() | nil,
          state: game_state,
          draw_piles: [[Card.t()]],
          players: [Player.t() | nil],
          enemies: [Enemy.t() | nil],
          host: String.t() | nil,
          turn: String.t() | nil,
          zero_delay: boolean()
        }

  @spec new(String.t()) :: t()
  def new(code) do
    if not (is_binary(code) and String.length(code) == 4 and code == String.upcase(code)) do
      raise ArgumentError, "Code must be a 4-character string of capital letters"
    end

    draw_piles = [
      Deck.fresh_deck() |> Deck.shuffle(),
      Deck.fresh_deck() |> Deck.shuffle()
    ]

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

  @spec toggle_zero_delay(t()) :: {:ok, t()}
  def toggle_zero_delay(game) do
    {:ok, game |> Map.put(:zero_delay, !game.zero_delay)}
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
        |> set_turn(Enum.at(game.players, 0))

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
         :ok <- Hand.hand_not_busted(player.hand) do
      {:ok, player} = player |> Player.perform_hit()
      [top_card | _] = player.hand
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

          [game | _] = games = perform_enemy_turns(game, player, player_can_make_move: false)

          progress_to_next_state_after_turn_over(game, player) ++ games
        else
          [game | _] =
            games =
            perform_enemy_turns(game, player, player_can_make_move: player.turn_state == :hit)

          {:ok, player} = get_player_by_id(game, player.id)
          {:ok, enemy} = get_players_enemy(game, player.id)

          if player.turn_state != :hit && enemy.turn_state != :hit do
            progress_to_next_state_after_turn_over(game, player) ++ games
          else
            games
          end
        end

      games = games ++ [game]

      state_changes =
        games
        |> Enum.reverse()
        |> Enum.with_index()
        |> Enum.map(fn {game, index} ->
          if index == 0 do
            {0, game}
          else
            {@long_delay, game}
          end
        end)

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

      [game | _] =
        games = perform_enemy_turns(game, player, player_can_make_move: false) ++ [game]

      games = progress_to_next_state_after_turn_over(game, player) ++ games

      state_changes =
        games
        |> Enum.reverse()
        |> Enum.with_index()
        |> Enum.map(fn {game, index} ->
          if index == 0 do
            {0, game}
          else
            {@long_delay, game}
          end
        end)

      Logger.debug("Stand complete, #{length(state_changes)} state changes to apply")

      {:ok, state_changes}
    end
  end

  @spec progress_to_next_state_after_turn_over(t(), Player.t()) :: [t()]
  def progress_to_next_state_after_turn_over(game, player) do
    current_player_index = Enum.find_index(game.players, &(&1.id == player.id))
    next_player_index = current_player_index + 1

    case find_next_non_nil_player(game.players, next_player_index) do
      {:ok, next_player} ->
        game = game |> set_turn(next_player) |> recalculate_incoming_damage_for_everyone()
        [game]

      :error ->
        game =
          game
          |> new_message("Game over")
          |> Map.put(:state, :finished)
          |> recalculate_incoming_damage_for_everyone()

        [game]
    end
  end

  defp find_next_non_nil_player(players, start_index) do
    players
    |> Enum.drop(start_index)
    |> Enum.find(&(&1 != nil))
    |> case do
      nil -> :error
      player -> {:ok, player}
    end
  end

  @spec finalize_round(t()) :: [t()]
  def finalize_round(game) do
    game = game |> set_turn(nil) |> recalculate_incoming_damage_for_everyone()
    games = [game]

    game = apply_any_pending_damage(game)
    games = [game | games]

    game = kill_any_dead_characters(game)
    games = [game | games]

    cond do
      length(game.enemies) == 0 ->
        raise "No enemies left, start new round"

      length(game.players) == 0 ->
        raise "No players left, end game"

      true ->
        game = clear_hands_and_reset_states(game)

        games = [game | games]

        first_player = Enum.at(game.players, 0)

        game = game |> set_turn(first_player)

        [game | games]
    end
  end

  @spec kill_any_dead_characters(t()) :: t()
  def kill_any_dead_characters(game) do
    players = Enum.filter(game.players, fn player -> player.health > 0 end)
    enemies = Enum.filter(game.enemies, fn enemy -> enemy.health > 0 end)

    game = %{game | players: players, enemies: enemies}

    dead_characters =
      Enum.filter(game.players, fn player -> player.health <= 0 end) ++
        Enum.filter(game.enemies, fn enemy -> enemy.health <= 0 end)

    messages =
      dead_characters |> Enum.map(fn character -> "#{character.name} has been defeated!" end)

    %{game | messages: messages ++ game.messages}
  end

  def clear_hands_and_reset_states(game) do
    players = Enum.map(game.players, &Character.clear_hand_and_reset_state/1)
    enemies = Enum.map(game.enemies, &Character.clear_hand_and_reset_state/1)
    %{game | players: players, enemies: enemies}
  end

  @spec calculate_damage(integer(), integer()) :: {integer(), integer()}
  def calculate_damage(player_hand_value, enemy_hand_value) do
    player_hand_value = if player_hand_value > 21, do: 0, else: player_hand_value
    enemy_hand_value = if enemy_hand_value > 21, do: 0, else: enemy_hand_value

    player_damage = max(enemy_hand_value - player_hand_value, 0)
    enemy_damage = max(player_hand_value - enemy_hand_value, 0)
    {player_damage, enemy_damage}
  end

  @spec recalculate_incoming_damage_for_everyone(t()) :: t()
  def recalculate_incoming_damage_for_everyone(game) do
    players_with_damage =
      Enum.with_index(game.players)
      |> Enum.map(fn {player, index} ->
        enemy = Enum.at(game.enemies, index)

        if player.turn_state != :hit && enemy.turn_state != :hit do
          {player_damage, enemy_damage} = calculate_damage(player.hand_value, enemy.hand_value)

          updated_player = %{player | incoming_damage: player_damage}
          updated_enemy = %{enemy | incoming_damage: enemy_damage}

          {updated_player, updated_enemy}
        else
          {player, enemy}
        end
      end)

    {updated_players, updated_enemies} = Enum.unzip(players_with_damage)

    %{game | players: updated_players, enemies: updated_enemies}
  end

  @spec apply_any_pending_damage(t()) :: t()
  def apply_any_pending_damage(game) do
    players =
      Enum.map(game.players, fn player ->
        if player.incoming_damage do
          new_health = max(player.health - player.incoming_damage, 0)
          %{player | health: new_health, incoming_damage: nil}
        else
          player
        end
      end)

    enemies =
      Enum.map(game.enemies, fn enemy ->
        if enemy.incoming_damage do
          new_health = max(enemy.health - enemy.incoming_damage, 0)
          %{enemy | health: new_health, incoming_damage: nil}
        else
          enemy
        end
      end)

    %{game | players: players, enemies: enemies}
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

  @spec set_turn(t(), Player.t() | nil) :: t()
  def set_turn(game, player) do
    game = %{game | turn: player && player.id}

    case player do
      nil -> game
      player -> new_message(game, "it's #{player.name}'s turn")
    end
  end

  @spec update_player(t(), Player.t()) :: t()
  def update_player(game, player) do
    update_in(game.players, fn players ->
      Enum.map(players, fn p ->
        cond do
          is_nil(p) -> p
          p.id == player.id -> player
          true -> p
        end
      end)
    end)
  end

  @spec update_enemy(t(), Enemy.t()) :: t()
  def update_enemy(game, enemy) do
    update_in(game.enemies, fn enemies ->
      Enum.map(enemies, fn e ->
        cond do
          is_nil(e) -> e
          e.id == enemy.id -> enemy
          true -> e
        end
      end)
    end)
  end

  @spec perform_enemy_turns(t(), Player.t(), keyword()) :: [t()]
  defp perform_enemy_turns(game, player, opts) do
    player_can_make_move = Keyword.fetch!(opts, :player_can_make_move)
    perform_enemy_turns(game, player, player_can_make_move, [])
  end

  @spec perform_enemy_turns(t(), Player.t(), boolean(), [t()]) :: [t()]
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

  @spec perform_enemy_turn(t(), Player.t()) :: t()
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
