defmodule Whack.Character do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :draw_pile,
    :hand,
    :hand_value,
    :discard_pile,
    :health,
    :incoming_damage,
    :turn_state
  ]

  alias Whack.Card
  alias Whack.Hand

  @type turn_state :: :hit | :stand | :busted
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          draw_pile: [Card.t()],
          hand: [Card.t()],
          hand_value: integer(),
          discard_pile: [Card.t()],
          health: integer(),
          incoming_damage: integer() | nil,
          turn_state: turn_state()
        }

  def new(module, id, name, art, opts \\ []) do
    struct!(module, %{
      id: id,
      name: name,
      art: art,
      draw_pile: [],
      hand: [],
      hand_value: 0,
      discard_pile: [],
      health: Keyword.get(opts, :health, 100),
      incoming_damage: nil,
      turn_state: :hit
    })
  end

  def clear_hand_and_reset_state(character) do
    %{
      character
      | hand: [],
        discard_pile: character.hand ++ character.discard_pile,
        hand_value: 0,
        incoming_damage: nil,
        turn_state: :hit
    }
  end

  def perform_hit(%{turn_state: :hit, draw_pile: []} = character) do
    draw_pile = Enum.shuffle(character.discard_pile)

    character =
      character
      |> Map.put(:draw_pile, draw_pile)
      |> Map.put(:discard_pile, [])

    perform_hit(character)
  end

  def perform_hit(%{turn_state: :hit} = character) do
    [top_card | draw_pile] = character.draw_pile
    hand = [top_card | character.hand || []]
    hand_value = Hand.calculate_value_of_hand(hand)

    character =
      character
      |> Map.put(:draw_pile, draw_pile)
      |> Map.put(:hand, hand)
      |> Map.put(:hand_value, hand_value)

    character =
      if Enum.empty?(character.draw_pile) and Enum.empty?(character.discard_pile) do
        %{character | turn_state: :stand}
      else
        character
      end

    character =
      if hand_value > 21 do
        Map.put(character, :turn_state, :busted)
      else
        character
      end

    {:ok, character}
  end

  def perform_hit(_character), do: {:error, :invalid_turn_state}

  def perform_stand(character), do: {:ok, Map.put(character, :turn_state, :stand)}

  def is_turn_in_state(%{turn_state: state}, state), do: :ok
  def is_turn_in_state(_, _), do: {:error, :invalid_turn_state}

  @spec can_continue_making_moves?(t(), t()) :: boolean()
  def can_continue_making_moves?(character1, character2) do
    can_hit?(character1) || can_hit?(character2)
  end

  @spec can_hit?(t()) :: boolean()
  defp can_hit?(character) do
    character.turn_state == :hit
  end

  @spec apply_damage(t(), integer()) :: t()
  def apply_damage(character, damage) do
    character |> Map.put(:incoming_damage, damage)
  end
end
