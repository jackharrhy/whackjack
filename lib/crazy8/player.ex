defmodule Crazy8.Player do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :index,
    :art
  ]

  @art [
    {:text, "🧑‍🌾"},
    {:text, "🐸"},
    {:text, "🐵"},
    {:text, "🐀"},
    {:text, "🪿"},
    {:text, "🐢"},
    {:text, "🐌"},
    {:text, "🐞"},
    {:text, "🐱"},
    {:text, "🐶"}
  ]

  def new(id, name) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art
    })
  end
end

defimpl String.Chars, for: Crazy8.Player do
  def to_string(player) do
    "#{player.name} #{player.art |> elem(1)}"
  end
end
