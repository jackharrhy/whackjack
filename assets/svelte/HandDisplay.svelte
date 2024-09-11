<script>
  import { cn } from "./utils";

  export let character;
</script>

{#if character.hand.length > 0}
  <p
    class={cn("text-2xl font-bold text-white/50 text-center", {
      "drop-shadow-text": character.hand_value < 21,
      "text-glow drop-shadow-glow jello": character.hand_value === 21,
      "text-red-500 wobble": character.hand_value > 21,
    })}
  >
    {character.hand_value} / 21
  </p>
{/if}
