defmodule Whack.Player do
  @derive Jason.Encoder

  alias Whack.Character

  defstruct [:image_path | Map.keys(%Character{})]

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

  @type t ::
          %__MODULE__{
            image_path: String.t() | nil
          }
          | Character.t()

  def new(id, name, image_path) do
    random_art = Enum.random(@art)
    character = Character.new(__MODULE__, id, name, random_art)
    Map.put(character, :image_path, image_path)
  end

  defdelegate perform_hit(player), to: Character
end

defimpl String.Chars, for: Whack.Player do
  def to_string(player), do: "#{player.name} #{player.art}"
end
