defmodule Whack.Player do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :image_path,
    :draw_pile
  ]

  alias Whack.Card

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          image_path: String.t() | nil,
          draw_pile: [Card.t()]
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
      draw_pile: []
    })
  end
end

defimpl String.Chars, for: Whack.Player do
  def to_string(player) do
    "#{player.name} #{player.art}"
  end
end
