defmodule Crazy8.Player do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :hand
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          hand: list()
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

  @spec new(String.t(), String.t(), list()) :: t()
  def new(id, name, hand) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art,
      hand: hand
    })
  end
end

defimpl String.Chars, for: Crazy8.Player do
  def to_string(player) do
    "#{player.name} #{player.art}"
  end
end
