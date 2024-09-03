<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";

  export let name = "";
  export let code = "";
  export let image_path = "";

  $: localImage = undefined;

  $: imagePath = localImage || image_path;

  $: console.log({ imagePath });

  let imageFile: HTMLInputElement;

  async function uploadImage() {
    if (!imageFile.files || imageFile.files.length === 0) {
      alert("Please select a file first");
      return;
    }

    const formData = new FormData();
    formData.append("image", imageFile.files[0]);

    const response = await fetch("/api/upload-image", {
      method: "POST",
      body: formData,
    });

    if (response.ok) {
      const data = await response.json();
      localImage = `${data.path}?${Date.now()}`;
    } else {
      console.error("Upload failed");
    }
  }
</script>

<header class="flex justify-center text-2xl py-4">whack</header>

<div class="flex items-center flex-col gap-6 w-64 mx-auto">
  <div class="flex flex-col gap-2 w-full">
    {#if image_path}
      <img src={imagePath} alt="upload of yourself" />
    {/if}
    <Input type="file" bind:inputRef={imageFile} />
    <Button variant="outline" on:click={uploadImage}>
      upload picture of yourself
    </Button>
  </div>

  <form
    phx-change="update"
    phx-submit="join-game"
    class="flex flex-col gap-2 w-full"
  >
    <Input
      name="code"
      placeholder="game code"
      type="text"
      bind:value={code}
      phx-debounce="500"
    />
    <Input
      name="name"
      placeholder="your username"
      type="text"
      bind:value={name}
      phx-debounce="500"
    />
    <Button variant="outline" type="submit">join game</Button>
  </form>

  <div class="flex items-center w-full my-4">
    <div class="flex-grow border-t border-gray-300"></div>
    <span class="px-4 py-2 text-gray-500 text-sm uppercase">or</span>
    <div class="flex-grow border-t border-gray-300"></div>
  </div>

  <form phx-submit="create-game" class="flex flex-col gap-2 w-full">
    <Button variant="outline" type="submit">create game</Button>
    <p class="text-sm text-gray-500">
      do this on a screen all players can see, like the person in discord screen
      sharing, or a television
    </p>
  </form>

  <div class="flex items-center w-full my-4">
    <div class="flex-grow border-t border-gray-300"></div>
    <span class="px-4 py-2 text-gray-500 text-sm uppercase">or</span>
    <div class="flex-grow border-t border-gray-300"></div>
  </div>

  <form phx-submit="create-single-pane-game" class="flex flex-col gap-2 w-full">
    <Button variant="outline" type="submit">create single pane game</Button>
    <p class="text-sm text-gray-500">
      do this if you want to the entire play on a single screen, mostly built
      for testing purposes
    </p>
  </form>
</div>
