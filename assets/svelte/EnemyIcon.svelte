<script>
  import { cn } from "$lib/utils";
  export let enemy;
</script>

<div class={cn("flex flex-col items-center gap-2 w-24", $$restProps.class)}>
  <span class="text-6xl">{enemy.art}</span>
  <div class="flex flex-col gap-1">
    <p class="text-red-300 drop-shadow-evil text-center">
      {enemy.name}
    </p>
    <p class="text-white drop-shadow-text text-center text-sm">
      {enemy.health}
      {#if enemy.incoming_damage}
        <span class="text-red-500 font-bold">
          - {enemy.incoming_damage}
        </span>
      {/if}
      ❤️
    </p>
    <p class="text-white drop-shadow-text text-center text-sm">
      stands on {enemy.stands_on}
    </p>
  </div>
</div>
