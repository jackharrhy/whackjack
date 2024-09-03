defmodule WhackWeb.ImageServeController do
  use WhackWeb, :controller

  def show(conn, %{"filename" => filename}) do
    image_path = Path.join([System.tmp_dir!(), "whack-uploads", filename])

    if File.exists?(image_path) do
      conn
      |> put_resp_content_type(get_content_type(filename))
      |> send_file(200, image_path)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Image not found"})
    end
  end

  defp get_content_type(filename) do
    case Path.extname(filename) do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      _ -> "application/octet-stream"
    end
  end
end
