defmodule Whack.Player do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :image_path,
    :draw_pile,
    :hand,
    :hand_value,
    :discard_pile,
    :health
  ]

  alias Whack.Card

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          image_path: String.t() | nil,
          draw_pile: [Card.t()],
          hand: [Card.t()],
          hand_value: integer(),
          discard_pile: [Card.t()],
          health: integer()
        }

  @art [
    "🐸",
    "🐵",
    "🐀",
    "🐢",
    "🐌",
    "🐞",
    "🐱",
    "🐶"
  ]

  @spec new(String.t(), String.t(), String.t() | nil) :: t()
  def new(id, name, image_path) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art,
      image_path: image_path,
      draw_pile: [],
      hand: [],
      hand_value: 0,
      discard_pile: [],
      health: 100
    })
  end
end

defimpl String.Chars, for: Whack.Player do
  def to_string(player) do
    "#{player.name} #{player.art}"
  end
end
