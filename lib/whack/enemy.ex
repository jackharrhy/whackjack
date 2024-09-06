defmodule Whack.Enemy do
  @derive Jason.Encoder

  alias Whack.Character

  defstruct [:stands_on | Map.keys(%Character{})]

  @art [
    "👹",
    "👾",
    "🤖",
    "👻",
    "👽",
    "👿",
    "💀",
    "🧟‍♂️",
    "🧟‍♀️",
    "🧛‍♂️",
    "🧛‍♀️",
    "🧜‍♂️",
    "🧜‍♀️",
    "🧞‍♂️",
    "🧞‍♀️"
  ]

  @type t ::
          %__MODULE__{
            stands_on: integer()
          }
          | Character.t()

  def new(id, name, health, stands_on) do
    random_art = Enum.random(@art)
    character = Character.new(__MODULE__, id, name, random_art, health: health)
    Map.put(character, :stands_on, stands_on)
  end

  def perform_turn(%__MODULE__{turn_state: :hit} = enemy) do
    if enemy.hand_value >= enemy.stands_on do
      {:ok, Map.put(enemy, :turn_state, :stand)}
    else
      Character.perform_hit(enemy)
    end
  end

  def perform_turn(%__MODULE__{turn_state: :stand} = enemy), do: {:ok, enemy}
  def perform_turn(%__MODULE__{turn_state: :busted} = enemy), do: {:ok, enemy}
  def perform_turn(_enemy), do: {:error, :invalid_turn_state}
end

defimpl String.Chars, for: Whack.Enemy do
  def to_string(enemy), do: "#{enemy.name} #{enemy.art}"
end
