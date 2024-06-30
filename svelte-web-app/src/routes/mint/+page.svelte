<script>
  import {
    defaultEvmStores as evm,
    contracts,
    connected,
    chainId,
  } from "svelte-ethers-store";
  import Hero from "$lib/components/Hero.svelte";
  import Mint from "$lib/components/Mint.svelte";
  import { onMount } from "svelte";
  import { useConnectToWallet } from "$lib/utils/useConnectToWallet";
  import { address, chainid } from "$lib/rge.conf.json";
  import InvalidChain from "$lib/components/InvalidChain.svelte";
  import abi from "$lib/rge.abi.json";
  evm.attachContract("rge", address, abi);

  onMount(() => {
    useConnectToWallet();
  });
</script>

<div>
  {#if $connected}
    {#if $chainId !== chainid}
      <InvalidChain />
    {:else}
      <Mint />
    {/if}
  {:else}
    <Hero />
  {/if}
</div>
