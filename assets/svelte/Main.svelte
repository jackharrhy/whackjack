<script>
  export let game;

  export let live;
  export let myself;

  function resetGame() {
    live.pushEventTo(myself, "reset-game", {});
  }

  function isPlayerHost(player) {
    return game.host === player.id;
  }

  function isPlayersTurn(player) {
    return player.id === game.turn;
  }
</script>

<div class="bg-felt bg-contain flex h-full p-2">
  <div class="flex-1 flex gap-8 py-6 px-12">
    <div class="grid grid-rows-4 gap-4">
      {#each Array(4) as _, i}
        <div class="flex flex-col justify-center items-center">
          {#if i < game.players.length}
            <div>
              {#if game.players[i].image_path}
                <img
                  src={game.players[i].image_path}
                  alt={game.players[i].name}
                  class="w-20 h-20 rounded-lg object-cover border-2 border-white"
                />
              {:else}
                <span class="text-4xl">{game.players[i].art}</span>
              {/if}
              <p class="text-white drop-shadow-text text-center">
                {game.players[i].name}
              </p>
            </div>
          {:else}
            <p class="text-white/50 drop-shadow-text text-center">waiting...</p>
          {/if}
        </div>
      {/each}
    </div>
  </div>

  <div class="flex flex-col p-3 h-full overflow-y-auto">
    <div class="bg-stone-900/40 text-white p-3 h-full">
      <p class="font-semibold text-center text-3xl pb-2">{game.code}</p>
      <ul class="list-none">
        {#each game.messages as message}
          <li>{message}</li>
        {/each}
      </ul>
    </div>
  </div>
</div>
