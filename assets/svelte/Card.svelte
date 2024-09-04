<script lang="ts">
  export let card = null;

  const cardBase = "/images/Cards/";
  const cardBack = `${cardBase}cardBack_red4.png`;
</script>

<div class="w-24 h-32 relative">
  <img
    src={card ? card.art_url : cardBack}
    alt={card ? `${card.value} of ${card.suit}` : "Card back"}
    class="w-full h-full object-contain"
  />
</div>
