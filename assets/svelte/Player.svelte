<script>
  import { Toaster } from "$lib/components/ui/sonner";
  import { toast } from "svelte-sonner";

  export let player;
  export let game;

  export let live;
  export let myself;

  $: isPlayerHost = game.host === player.id;

  if (live) {
    live.handleEvent("flash", (event) => {
      toast[event.level](event.message, {
        duration: 5000,
      });
    });
  }

  function startGame() {
    live.pushEventTo(myself, "start-game", {});
  }
</script>

<Toaster />

<div class="flex flex-col flex-wrap justify-center items-center p-4">
  {#if game.state === "setup"}
    {#if isPlayerHost}
      {#if game.players.length >= 4}
        <button
          on:click={() => startGame()}
          class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded mb-4"
        >
          start game
        </button>
      {:else}
        <p class="text-yellow-600 font-semibold mb-4">
          waiting for more players to join...
        </p>
      {/if}
    {:else}
      <p class="text-gray-600 italic mb-4">
        waiting for host to start the game...
      </p>
    {/if}
  {/if}
</div>
