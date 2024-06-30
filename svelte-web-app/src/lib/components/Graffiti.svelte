<script>
    export let index = 0;

  import { base } from '$app/paths';
    import { defaultEvmStores as evm, contracts } from "svelte-ethers-store";
    import { writable } from 'svelte/store';
    import rgeConf from "$lib/rge.conf.json";
    import rgeAbi from "$lib/rge.abi.json";
    import { ethers } from "ethers";
    evm.attachContract("rge", rgeConf["address"], rgeAbi);

    import { onMount } from "svelte";
    import Loading from "$lib/components/shared/Loading.svelte";

    // For adding a color changer
    let showRgb = false;
    let isLoading = true;
    let minFloorPrice = 0;
    const NFT = writable(null);
    let graffiti;

    function rgbToHex(NFT) {
        const red = NFT.attributes[0].Red;
        const green = NFT.attributes[1].Green;
        const blue = NFT.attributes[2].Blue;
        const toHex = (c) => c.toString(16).padStart(2, '0');
        return `#${toHex(red)}${toHex(green)}${toHex(blue)}`;
    }

    function getRgbString(NFT) {
        const red = NFT.attributes[0].Red;
        const green = NFT.attributes[1].Green;
        const blue = NFT.attributes[2].Blue;
        return `rgb(${red}, ${green}, ${blue})`;
    }

    function b64DecodeUnicode(str) {
        // Going backwards: from bytestream, to percent-encoding, to original string.
        return decodeURIComponent(
            atob(str)
                .split("")
                .map(function (c) {
                    return (
                        "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2)
                    );
                })
                .join(""),
        );
    }
    async function obtainGraffiti() {
        // Call the smart contract function
        try {
            await $contracts.rge["obtainNFT(uint256)"](index, {
                value: FloorPrice,
            }).then((e) => {
                console.log("Message sent using Provider: ", e);
                goto(base);
            });
        } catch (error) {
            console.error("An error occurred when calling obtainNFT:", error);
        }
    }

    onMount(async () => {
        // Check if the contract is available and if the data is loaded
        if ($contracts.rge) {
            // Get the floor price
            const FloorPrice = await $contracts.rge.getMinFloorPrice();
            minFloorPrice = ethers.utils.formatUnits(FloorPrice, "ether");
            graffiti = await $contracts.rge.getGraffitiBase(index);
            const tokenURI = await $contracts.rge.tokenURI(index);
            const stripb64h = b64DecodeUnicode(tokenURI.replace(/^data:\w+\/\w+;base64,/, ""));
            const parsedNFT = JSON.parse(stripb64h);
            console.log(parsedNFT);
            NFT.set(parsedNFT);
            isLoading = false;
        }
    });
</script>

<div>
    {#if isLoading}
        <Loading />
    {:else}
        {#if $NFT != null}
            <div class="text-white p-10">
                <h2>
                    Graffiti {index}ª
                </h2>
            <br/>
                <h2 class="my-3">Details</h2>
                <!--
            Items to display nicely:
             - Color
             - Owner
             - Description
             - External URL
             
         -->
                <div class="flex items-center justify-start gap-y-3">
                    <p class="w-[28rem]">
                        Color:<a href style="color:{rgbToHex($NFT)}" on:click={() => (showRgb = !showRgb)}>
                        {#if showRgb}
                            {rgbToHex($NFT)}
                        {:else}
                            {getRgbString($NFT)}
                        {/if}
                    </a>
                    </p>
                </div>
                <p>&nbsp;</p>
                <p>Creator: <a href="https://basescan.io/address/{graffiti["creator"]}">{graffiti["creator"]}</a></p>
                <p>&nbsp;</p>
                <p>Owner: <a href="https://basescan.io/address/{graffiti["owner"]}">{graffiti["owner"]}</a></p>
                <p>&nbsp;</p>
                <p><a href="{$NFT.external_url}">External Link &#x2794;</a></p>
                <p>&nbsp;</p>
                <p>
                    Obtain: <button id="obtainBtn" class="neon-btn" on:click={obtainGraffiti}
                        >{minFloorPrice}</button
                    >
                </p>
            </div>
            <img
                class="pxl justify-center items-center mx-auto my-4 px-4"
                alt="NFT {index}"
                src={$NFT.image}
            />
        {/if}
    {/if}
</div>

<style>
    .okayText {
        color: #00ff00;
    }
    .dangerText {
        color: #ff0000;
    }

    .technoText {
        color: #4cc9f0;
    }

    p {
        font-size: 12px;
        font-weight: 400;
    }
</style>
