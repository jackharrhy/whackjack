defmodule Whack.Player do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t()
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

  @spec new(String.t(), String.t()) :: t()
  def new(id, name) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art
    })
  end
end

defimpl String.Chars, for: Whack.Player do
  def to_string(player) do
    "#{player.name} #{player.art}"
  end
end
