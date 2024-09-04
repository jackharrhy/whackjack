<script>
  import PlayerIcon from "./PlayerIcon.svelte";
  import * as Dialog from "$lib/components/ui/dialog";
  import { cn } from "$lib/utils";
  import Card from "./Card.svelte";
  import Button from "./components/ui/button/button.svelte";

  export let game;
  export let debug;

  export let live;
  export let myself;

  function resetGame() {
    live.pushEventTo(myself, "reset-game", {});
    window.location.reload();
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
        <div class="flex gap-4 justify-center items-center">
          {#if i < game.players.length}
            <PlayerIcon
              player={game.players[i]}
              isPlayersTurn={isPlayersTurn(game.players[i])}
            />
            {#if game.players[i].draw_pile && game.players[i].draw_pile.length > 0}
              <div class="relative w-24 h-32">
                {#each game.players[i].draw_pile as _card, index}
                  <div
                    class="absolute"
                    style="left: {index * 4}px; z-index: {index};"
                  >
                    <Card />
                  </div>
                {/each}
              </div>
            {/if}
          {:else}
            <p class="text-white/50 drop-shadow-text text-center">waiting...</p>
          {/if}
        </div>
      {/each}
    </div>
  </div>

  <div class="flex flex-col p-3 h-full overflow-y-auto">
    <div class="flex flex-col bg-stone-900/40 text-white p-3 h-full">
      {#if debug}
        <Button variant="outline" class="w-full" on:click={resetGame}
          ><span class="text-xs text-black">reset game</span></Button
        >
        <Dialog.Root>
          <Dialog.Trigger>
            <Button variant="outline" class="w-full"
              ><span class="text-xs text-black">debug</span></Button
            >
          </Dialog.Trigger>
          <Dialog.Content class="w-full h-full max-w-none">
            <pre class="w-full overflow-y-auto h-full"><code
                >{JSON.stringify(game, null, 2)}</code
              ></pre>
          </Dialog.Content>
        </Dialog.Root>
      {/if}
      <p class="font-semibold text-center text-3xl pb-2">{game.code}</p>
      <ul class="list-none">
        {#each game.messages as message}
          <li>{message}</li>
        {/each}
      </ul>
    </div>
  </div>
</div>
