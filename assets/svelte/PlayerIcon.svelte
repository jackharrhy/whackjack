<script>
  import { cn } from "$lib/utils";

  export let player;
  export let isPlayersTurn;
</script>

<div
  class={cn("flex flex-col items-center gap-1 w-24 pt-3", $$restProps.class)}
>
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
    <span class="text-6xl">{player.art}</span>
  {/if}
  <p class="text-white drop-shadow-text text-center">
    {player.name}
  </p>
  <p class="text-white drop-shadow-text text-center text-sm">
    {player.health} ❤️
  </p>
</div>
