<script>
  import {
    defaultEvmStores as evm,
    connected,
    chainId,
  } from "svelte-ethers-store";
  import { page } from "$app/stores";
  import Hero from "$lib/components/Hero.svelte";
  import Graffiti from "$lib/components/Graffiti.svelte";
  import { onMount } from "svelte";
  import { useConnectToWallet } from "$lib/utils/useConnectToWallet";
  import { address, chainid } from "$lib/rge.conf.json";
  import InvalidChain from "$lib/components/InvalidChain.svelte";
  import abi from "$lib/rge.abi.json";
  evm.attachContract("rge", address, abi);

  onMount(() => {
    useConnectToWallet();
  });

  function getIndex() {
    let i = $page.url.searchParams.get("i");
    if (i === undefined) return 0;
    return i;
  }

</script>

<div>
  {#if $connected}
    {#if $chainId !== chainid}
      <InvalidChain />
    {:else}
      <Graffiti index={getIndex()} />
    {/if}
  {:else}
    <Hero />
  {/if}
</div>
