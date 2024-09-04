<script>
  import { cn } from "$lib/utils";

  export let player;
  export let isPlayersTurn;
</script>

<div>
  {#if player.image_path}
    <img
      src={player.image_path}
      alt={player.name}
      class={cn(
        "w-20 h-20 rounded-lg object-cover border-2",
        isPlayersTurn ? "border-red-500" : "border-white"
      )}
    />
  {:else}
    <span class="text-4xl">{player.art}</span>
  {/if}
  <p class="text-white drop-shadow-text text-center">
    {player.name}
  </p>
</div>
