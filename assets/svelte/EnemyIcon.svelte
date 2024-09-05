<script>
  export let enemy;
</script>

<div class="flex flex-col items-center gap-2 w-24">
  <span class="text-6xl">{enemy.art}</span>
  <p class="text-red-300 drop-shadow-evil text-center">
    {enemy.name}
  </p>
</div>
