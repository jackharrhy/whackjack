<script lang="ts">
  import { cn } from "$lib/utils";

  export let card = null;
  export let evil = false;

  const cardBase = "/images/Cards/";
  const cardBackNice = `${cardBase}cardBack_blue4.png`;
  const cardBackEvil = `${cardBase}cardBack_red4.png`;

  $: cardBack = evil ? cardBackEvil : cardBackNice;
</script>

<div class={cn("w-24 h-32 relative", $$restProps.class)}>
  <img
    src={card ? card.art_url : cardBack}
    alt={card ? `${card.value} of ${card.suit}` : "Card back"}
    class="w-full h-full object-contain"
  />
</div>
