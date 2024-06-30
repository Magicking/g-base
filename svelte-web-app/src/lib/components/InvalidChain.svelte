<script>
  const addEthereumChain = async () => {
    if (window.ethereum) {
      try {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: "0x2105",
              blockExplorerUrls: ["https://basescan.io"],
              chainName: "Base Mainnet",
              nativeCurrency: { name: "Ethereum", symbol: "ETH", decimals: 18 },
              rpcUrls: ["https://base-mainnet.g.alchemy.com/v2/pWpu34JW_JL6Jpy2Bqep0HQAc3xIa4xN"],
            },
          ],
        });
      } catch (addError) {
        console.error(addError);
      }
    } else {
      console.log("Ethereum object does not exist!");
    }
  };
</script>

<div>
  <h1 class="red text-center">
    <button class="neon-btn blue" on:click={addEthereumChain}>Add Base Chain</button>
  </h1>
  <h1 class="red text-center">Warning /!\ not on Base chain /!\</h1>
</div>
