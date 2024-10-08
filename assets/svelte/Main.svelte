<script>
  import { flip } from "svelte/animate";
  import { crossfade } from "svelte/transition";
  import { quintOut } from "svelte/easing";

  import { cn } from "$lib/utils";
  import * as Dialog from "$lib/components/ui/dialog";
  import Button from "./components/ui/button/button.svelte";

  import PlayerIcon from "./PlayerIcon.svelte";
  import Card from "./Card.svelte";
  import EnemyIcon from "./EnemyIcon.svelte";
  import HandDisplay from "./HandDisplay.svelte";

  export let game;
  export let debug;

  export let live;
  export let myself;

  const defaultDuration = 600;

  const [send, receive] = crossfade({
    duration: defaultDuration,
    easing: quintOut,
  });

  function resetGame() {
    live.pushEventTo(myself, "reset-game", {});
    window.location.reload();
  }

  function toggleZeroDelay() {
    live.pushEventTo(myself, "toggle-zero-delay", {});
  }

  function isPlayerHost(player) {
    return game.host === player.id;
  }

  function isPlayersTurn(player) {
    return player.id === game.turn;
  }
</script>

{#if game.draw_piles && game.draw_piles.length > 0}
  <div
    class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 flex flex-col gap-12"
  >
    {#each game.draw_piles as draw_pile, pileIndex}
      <div class="relative w-40 h-32">
        {#each draw_pile.slice().reverse() as card, index (card.id)}
          <div
            class="absolute"
            style="left: {index * 0.5}px; top: {index *
              0.5}px; z-index: {index}; animation-delay: {index * 0.1}s;"
            animate:flip={{ duration: defaultDuration }}
            in:receive={{ key: card.id }}
            out:send={{ key: card.id }}
          >
            <Card evil={pileIndex !== 0} />
          </div>
        {/each}
      </div>
    {/each}
  </div>
{/if}

<div class="bg-felt bg-contain flex h-full p-2">
  <div class="flex-1 flex gap-8 py-6 px-12">
    <div class="grid grid-rows-4 gap-4 w-full">
      {#each Array(4) as _, i}
        <div class="flex gap-4 items-center justify-between">
          <div class="flex items-center gap-8">
            {#if game.players[i]}
              <div class="relative w-16 h-20">
                {#each game.players[i].discard_pile as card, index (card.id)}
                  <div
                    class="absolute"
                    style="left: {index *
                      6}px; z-index: {index}; animation-delay: {index * 0.1}s;"
                    animate:flip={{ duration: defaultDuration }}
                    in:receive={{ key: card.id }}
                    out:send={{ key: card.id }}
                  >
                    <Card variant="small" />
                  </div>
                {/each}
              </div>
              <PlayerIcon
                player={game.players[i]}
                isPlayersTurn={isPlayersTurn(game.players[i])}
                class="fade-in-left"
              />
              <div class="relative w-40 h-32">
                {#each game.players[i].draw_pile
                  .slice()
                  .reverse() as card, index (card.id)}
                  <div
                    class="absolute"
                    style="left: {index *
                      6}px; z-index: {index}; animation-delay: {index * 0.1}s;"
                    animate:flip={{ duration: defaultDuration }}
                    in:receive={{ key: card.id }}
                    out:send={{ key: card.id }}
                  >
                    <Card />
                  </div>
                {/each}
              </div>
              <div class="flex gap-2 transition-all duration-300 ease-in-out">
                {#each game.players[i].hand.slice().reverse() as card (card.id)}
                  <div
                    animate:flip={{ duration: defaultDuration }}
                    in:receive={{ key: card.id }}
                    out:send={{ key: card.id }}
                  >
                    <Card {card} />
                  </div>
                {/each}
              </div>

              <HandDisplay character={game.players[i]} />
            {:else if game.state === "setup"}
              <p class="text-white/50 drop-shadow-text text-center">
                waiting...
              </p>
            {/if}
          </div>

          <div class="flex items-center gap-8">
            {#if game.enemies[i]}
              <HandDisplay character={game.enemies[i]} />
              <div class="flex gap-2 transition-all duration-300 ease-in-out">
                {#each game.enemies[i].hand as card (card.id)}
                  <div
                    animate:flip={{ duration: defaultDuration }}
                    in:receive={{ key: card.id }}
                    out:send={{ key: card.id }}
                  >
                    <Card {card} evil />
                  </div>
                {/each}
              </div>
              <div class="relative w-40 h-32">
                {#each game.enemies[i].draw_pile as card, index (card.id)}
                  <div
                    class="absolute"
                    style="right: {index *
                      6}px; z-index: {index}; animation-delay: {index * 0.1}s;"
                    animate:flip={{ duration: defaultDuration }}
                    in:receive={{ key: card.id }}
                    out:send={{ key: card.id }}
                  >
                    <Card evil />
                  </div>
                {/each}
              </div>
              <EnemyIcon enemy={game.enemies[i]} class="fade-in-right" />
              <div class="relative w-16 h-20">
                {#each game.enemies[i].discard_pile as card, index (card.id)}
                  <div
                    class="absolute"
                    style="left: {index *
                      6}px; z-index: {index}; animation-delay: {index * 0.1}s;"
                    animate:flip={{ duration: defaultDuration }}
                    in:receive={{ key: card.id }}
                    out:send={{ key: card.id }}
                  >
                    <Card evil variant="small" />
                  </div>
                {/each}
              </div>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  </div>

  <div class="flex flex-col p-3 h-full w-[20rem]">
    <div
      class="flex flex-col bg-stone-900/40 text-white p-3 h-full overflow-y-auto scrollbar scrollbar-thumb-stone-700 scrollbar-track-stone-900"
    >
      {#if debug}
        <Button variant="outline" class="w-full" on:click={resetGame}
          ><span class="text-xs text-black">reset game</span></Button
        >
        <Button variant="outline" class="w-full" on:click={toggleZeroDelay}
          ><span class="text-xs text-black">toggle zero delay</span></Button
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

<style>
  :global(.fade-in-top) {
    opacity: 0;
    transform: translateY(-30px);
    animation: fadeInTop 0.6s ease-out forwards;
  }

  @keyframes fadeInTop {
    0% {
      opacity: 0;
      transform: translateY(-15px);
    }
    10% {
      opacity: 1;
      transform: translateY(-10px);
    }
    100% {
      opacity: 1;
      transform: translateY(0);
    }
  }

  :global(.fade-in-right) {
    opacity: 0;
    transform: translateX(30px);
    animation: fadeInRight 0.6s ease-out forwards;
  }

  @keyframes fadeInRight {
    0% {
      opacity: 0;
      transform: translateX(15px);
    }
    10% {
      opacity: 1;
      transform: translateX(10px);
    }
    100% {
      opacity: 1;
      transform: translateX(0);
    }
  }

  :global(.wobble) {
    animation: wobble 0.8s both;
  }

  @keyframes wobble {
    0%,
    100% {
      transform: translateX(0%);
      transform-origin: 50% 50%;
    }
    15% {
      transform: translateX(-15px) rotate(-6deg);
    }
    30% {
      transform: translateX(7px) rotate(6deg);
    }
    45% {
      transform: translateX(-7px) rotate(-3.6deg);
    }
    60% {
      transform: translateX(4px) rotate(2.4deg);
    }
    75% {
      transform: translateX(-3px) rotate(-1.2deg);
    }
  }

  :global(.fade-in-left) {
    opacity: 0;
    transform: translateX(-30px);
    animation: fadeInLeft 0.6s ease-out forwards;
  }

  @keyframes fadeInLeft {
    0% {
      opacity: 0;
      transform: translateX(-15px);
    }
    10% {
      opacity: 1;
      transform: translateX(-10px);
    }
    100% {
      opacity: 1;
      transform: translateX(0);
    }
  }

  :global(.jello) {
    animation: jello 0.9s both;
  }

  @keyframes jello {
    0% {
      transform: scale3d(1, 1, 1);
    }
    30% {
      transform: scale3d(1.25, 0.75, 1);
    }
    40% {
      transform: scale3d(0.75, 1.25, 1);
    }
    50% {
      transform: scale3d(1.15, 0.85, 1);
    }
    65% {
      transform: scale3d(0.95, 1.05, 1);
    }
    75% {
      transform: scale3d(1.05, 0.95, 1);
    }
    100% {
      transform: scale3d(1, 1, 1);
    }
  }
</style>
