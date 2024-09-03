defmodule WhackWeb.ImageUploadController do
  use WhackWeb, :controller

  alias WhackWeb.EnsureSessionController

  @tmp_dir_folder "whack-uploads"

  def create(conn, %{"image" => image}) do
    IO.inspect(image)

    conn =
      conn
      |> fetch_session()
      |> EnsureSessionController.setup_session_if_not_setup()

    session_id = get_session(conn, :session_id)

    {:ok, filename} = save_image(image, session_id)

    image_path = ~p"/api/image/#{filename}"

    conn
    |> put_session(:image_path, image_path)
    |> json(%{message: "Image saved successfully", path: image_path})
  end

  defp save_image(%Plug.Upload{path: temp_path}, session_id) do
    dest_dir = System.tmp_dir!()
    dest_dir = Path.join(dest_dir, @tmp_dir_folder)
    File.mkdir_p!(dest_dir)

    output_filename = "#{session_id}.webp"

    dest_path = Path.join(dest_dir, output_filename)

    temp_path
    |> Mogrify.open()
    |> Mogrify.format("webp")
    |> Mogrify.resize("400x400^")
    |> Mogrify.gravity("center")
    |> Mogrify.extent("400x400")
    |> Mogrify.auto_orient()
    |> Mogrify.save(path: dest_path)

    {:ok, output_filename}
  end
end
