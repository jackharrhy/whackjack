defmodule Crazy8Web.EnsureSessionController do
  use Crazy8Web, :controller

  def index(conn, params) do
    return_to = params["return_to"] || "/"

    conn
    |> put_session(:session_id, Nanoid.generate())
    |> redirect(to: return_to)
  end
end
