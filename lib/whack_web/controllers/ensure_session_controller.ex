defmodule WhackWeb.EnsureSessionController do
  use WhackWeb, :controller

  def setup_session_if_not_setup(conn) do
    if get_session(conn, :session_id) do
      conn
    else
      put_session(conn, :session_id, Nanoid.generate())
    end
  end

  def index(conn, %{"name" => name} = params) do
    return_to = Map.get(params, "return_to", "/")

    conn
    |> setup_session_if_not_setup()
    |> put_session(:name, name)
    |> redirect(to: return_to)
  end
end
