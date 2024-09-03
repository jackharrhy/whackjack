<script>
  import { Button } from "$lib/components/ui/button";
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

<div
  class="bg-felt backdrop-blur-2xl bg-contain h-full flex flex-col flex-wrap justify-center items-center p-4"
>
  {#if game.state === "setup"}
    {#if isPlayerHost}
      {#if game.players.length >= 4}
        <Button variant="outline" on:click={() => startGame()}
          >start game</Button
        >
      {:else}
        <p
          class="text-white drop-shadow-text italic font-semibold my-4 text-xl"
        >
          waiting for more players to join... ({game.players.length}/4)
        </p>
      {/if}
    {:else}
      <p class="text-white drop-shadow-text italic font-semibold my-4 text-xl">
        waiting for host to start the game...
      </p>
    {/if}
  {/if}
</div>
