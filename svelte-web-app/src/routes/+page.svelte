<script>
  import {
    defaultEvmStores as evm,
    connected,
    chainId,
  } from "svelte-ethers-store";
  import Hero from "$lib/components/Hero.svelte";
  import Graveyard from "$lib/components/Graveyard.svelte";
  import { onMount } from "svelte";
  import {chainid} from "$lib/rge.conf.json";
  import { useConnectToWallet } from "$lib/utils/useConnectToWallet";
  import InvalidChain from "$lib/components/InvalidChain.svelte";


  onMount(() => {
    useConnectToWallet();
  });
</script>

<svelte:head>
  <title>Graffiti</title>
  <meta name="description" content="Graffiti" />
</svelte:head>

<div>
  {#if $connected}
    {#if $chainId !== chainid }
    <InvalidChain/>
    {:else}
      <Graveyard />
    {/if}
  {:else}
    <Hero />
  {/if}
</div>
