<script>
  import { base } from '$app/paths';
  import { locale, translation } from "$lib/stores/i18n";
  import { onDestroy, onMount } from "svelte";
  import {
    defaultEvmStores as evm,
    connected,
    signer,
    chainId,
    chainData,
    contracts,
  } from "svelte-ethers-store";
  import ColorPicker from "svelte-awesome-color-picker";
  import rgeConf from "$lib/rge.conf.json";
  import { goto } from "$app/navigation";

  const maxX = 128;
  const maxY = 128;
  export let nymMode = false;

  let priceText = "";
  let destination = "";
  let squaresize = 1;
  let fUpdatePrice;
  let minBalance = 0;
  let balance = 0;

  let w;
  $: t = $translation;
  $: lang = $locale;

  let showTooltip = false;
  let canvasWidth;
  let updateCanvasColors = () => {};
  function updateCanvasWidth() {
    // 896px width for medium or larger screens
    canvasWidth = window.innerWidth >= 768 ? 896 : window.innerWidth;
    updateCanvasColors();
  }

  onMount(async () => {
    w = window;
    updateCanvasWidth();
    window.addEventListener("resize", updateCanvasWidth);
  });

  // Cleanup to remove the event listener when the component is destroyed
  onDestroy(async () => {
    if (w) w.removeEventListener("resize", updateCanvasWidth);
  });
  function getRandomColor() {
    // TODO Check color availability
    return {
      r: Math.floor(Math.random() * 255),
      g: Math.floor(Math.random() * 255),
      b: Math.floor(Math.random() * 255),
    };
  }

  let rgb = getRandomColor();
  function validate(e) {
    console.log("TODO CHECK destination is a valid address");
  }

  onMount(async () => {
    destination = "0x6120932248DaFbDDb7e97279e10F9348b0E0242c"; // RG DAO

    try {
      $signer.getAddress().then((address) => {
        destination = address;
        $signer.getBalance().then((bal) => {
          balance = bal.toNumber();
        });
      });
      priceText = rgbToHex(rgb.r, rgb.g, rgb.b);
    } catch (error) {}
    const canvas = document.getElementById("canvas");
    const saveBtn = document.getElementById("saveBtn");
    let drawing = false;
    let drawnPixels = new Array(maxX)
      .fill(null)
      .map(() => new Array(maxY).fill(false));
    const eraseBtn = document.getElementById("eraseBtn");
    let isEraserActive = false;
    let colorPrice = 0;
    fUpdatePrice = (rgb) => {
      // estimate gas to preview the price and assert execution using library as the mint function
      let sig = [];
      for (let x = 0; x < 64; x++) {
        sig.push(
          "0x0161fc4222080401f68c205e0e40000001311c4222180c01548860638e400000"
        );
      }
      priceText = rgbToHex(rgb.r, rgb.g, rgb.b);
      $contracts.rge.estimateGas[
        "mintGraffitiBaseOf(uint256[64],uint256,address)"
      ](sig, "0x" + priceText.substring(1), destination).then((e) => {
        console.log("Mint possible: ", e);
        minBalance = e;
        $signer.getBalance().then((bal) => {
          balance = bal;
        });
      });
      // set priceText to the color in HEX
      updateCanvasColors();
    };
    fUpdatePrice(rgb);
    eraseBtn.addEventListener("click", () => {
      drawing = false;
      isEraserActive = !isEraserActive;
      eraseBtn.classList.toggle("active", isEraserActive);
    });
    canvas.addEventListener("mousemove", (e) => {
      if (isEraserActive) {
        erasePixelEvent(e);
      } else if (drawing) {
        drawPixelEvent(e);
      }
    });
    canvas.addEventListener("mousedown", (e) => {
      drawing = true;
      if (isEraserActive) {
        erasePixelEvent(e);
      } else if (drawing) {
        drawPixelEvent(e);
      }
    });

    canvas.addEventListener("mousemove", (e) => {
      if (isEraserActive) {
        erasePixelEvent(e);
      } else if (drawing) {
        drawPixelEvent(e);
      }
    });

    canvas.addEventListener("mouseup", () => {
      drawing = false;
    });

    canvas.addEventListener("touchstart", (e) => {
      e.preventDefault();
      for (let i = 0; i < e.changedTouches.length; i++) {
        if (isEraserActive) {
          erasePixelEvent(e.changedTouches[i]);
        } else {
          drawPixelEvent(e.changedTouches[i]);
        }
      }
    });
    canvas.addEventListener("touchend", (e) => {
      e.preventDefault();
      for (let i = 0; i < e.changedTouches.length; i++) {
        if (isEraserActive) {
          erasePixelEvent(e.changedTouches[i]);
        } else {
          drawPixelEvent(e.changedTouches[i]);
        }
      }
    });
    canvas.addEventListener("touchmove", (e) => {
      e.preventDefault();
      for (let i = 0; i < e.changedTouches.length; i++) {
        if (isEraserActive) {
          erasePixelEvent(e.changedTouches[i]);
        } else {
          drawPixelEvent(e.changedTouches[i]);
        }
      }
    });

    saveBtn.addEventListener("click", async () => {
      // Convert the canvas to an array of uint256s
      updateCanvasColors();
      let sig = [];
      let uint256 = "";
      for (let y = 0; y < maxY; y++) {
        // We are using 1 uint256 per 2 row of pixels
        if (y != 0 && y % 2 == 0) {
          sig.push("0x" + uint256);
          uint256 = "";
        }
        // Each uint256 is 256 pixels (128x2 = 256)
        for (let x = 0; x < maxX; x += 32) {
          let n = 0;
          for (let i = 0; i < 32; i++)
            if (drawnPixels[x + i][y]) n += Math.pow(2, 32 - i - 1);
          uint256 += n.toString(16).padStart(8, "0");
        }
      }
      sig.push("0x" + uint256);

      // Get the color from the color picker
      let r = rgb.r;
      let g = rgb.g;
      let b = rgb.b;

      // Call the smart contract function
      try {
        // TODO put r g b in an uint256
        let rgb256 =
          "0x" +
          r.toString(16).padStart(2, "0") +
          g.toString(16).padStart(2, "0") +
          b.toString(16).padStart(2, "0");
        console.log([sig, rgb256, destination]);
        await $contracts.rge["mintGraffitiBaseOf(uint256[64],uint256,address)"](
          sig,
          rgb256,
          destination
        ).then((e) => {
          console.log("Message sent using Provider: ", e);
          goto(base);
        });
      } catch (error) {
        console.error(
          "An error occurred when calling mintGraffitiBaseOf:",
          error
        );
      }
    });

    function erasePixelEvent(e) {
      const rect = canvas.getBoundingClientRect();
      const x = Math.floor(((e.clientX - rect.left) / rect.width) * maxX);
      const y = Math.floor(((e.clientY - rect.top) / rect.height) * maxY);
      setPixel(x, y, false);
    }

    function drawPixelEvent(e) {
      const rect = canvas.getBoundingClientRect();
      const x = Math.floor(((e.clientX - rect.left) / rect.width) * maxX);
      const y = Math.floor(((e.clientY - rect.top) / rect.height) * maxY);
      setPixel(x, y, true);
    }

    function setPixel(x, y, set) {
      const ctx = canvas.getContext("2d");
      const pixX = ctx.canvas.width / maxX;
      const pixY = ctx.canvas.height / maxY;
      squaresize = parseInt(squaresize);
      ctx.fillStyle = rgbToHex(rgb.r, rgb.g, rgb.b);
      for (let i = x - squaresize + 1; i < x + squaresize; i++) {
        for (let j = y - squaresize + 1; j < y + squaresize; j++) {
          if (i >= 0 && i < maxX && j >= 0 && j < maxY) {
            if (set) {
              ctx.fillRect(i * pixX, j * pixY, pixX, pixY);
            } else {
              ctx.clearRect(i * pixX, j * pixY, pixX, pixY);
            }
            drawnPixels[i][j] = set;
          }
        }
      }
    }

    function fUupdateCanvasColors() {
      const ctx = canvas.getContext("2d");
      const pixX = ctx.canvas.width / maxX;
      const pixY = ctx.canvas.height / maxY;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = rgbToHex(rgb.r, rgb.g, rgb.b);
      for (let x = 0; x < maxX; x++) {
        for (let y = 0; y < maxY; y++) {
          if (drawnPixels[x][y]) {
            ctx.fillRect(x * pixX, y * pixY, pixX, pixY);
          }
        }
      }
    }
    updateCanvasColors = fUupdateCanvasColors;

    function rgbToHex(r, g, b) {
      return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
    }
  });
</script>

<div class="min-h-screen">
  <div class="flex flex-col">
    <div class="w-full flex items-center justify-evenly">
      <div
        class=" flex flex-col text-white mt-5 p-6 gap-y-4 w-[50rem] my-0 md:my-10"
      >
        <h1 class="text-green underline">Getting Started!</h1>
        <p class="info-box">
          {t("Mint.Banner")}
        </p>
      </div>
      <div class="flex flex-col items-stretch md:items-center relative p-6">
        <div>
          <label
            for="address"
            class="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300"
          >
            Base address (recipient):
          </label>
          <input
            type="text"
            bind:value={destination}
            id="address"
            class="bg-gray-50 blue border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white"
            placeholder="0xDE2..."
            required
          />
        </div>
      </div>
      <br />
    </div>
    <br />
    <div class="p-10">
      <div class="flex justify-between flex-col md:flex-row gap-y-6 md:gap-y-0">
        <div class="text-white">
          <button
            id="saveBtn"
            class="w-full mt-4 neon-btn blue px-2 py-1 text-sm text-white rounded-md shadow-md focus:outline-none"
            style="background-color: {balance < minBalance ? 'red' : 'blue'}"
          >
            {t("Mint.Save")}
          </button>
        </div>
        <div class="text-white">
          <div class="relative">
            Brush size<select
              class="block appearance-none w-full bg-white border border-gray-300 text-gray-700 py-2 px-3 pr-8 rounded leading-tight focus:outline-none focus:bg-white focus:border-gray-500"
              on:change={(event) => (squaresize = event.target.value)}
            >
              {#each Array.from({ length: 8 }, (_, i) => i + 1) as number}
                <option value={number}>{number}</option>
              {/each}
            </select>
            <div
              class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700"
            >
              <svg
                class="fill-current h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
              >
                <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
                <path
                  fill-rule="evenodd"
                  d="M10 3a7 7 0 110 14 7 7 0 010-14zm0 12a5 5 0 100-10 5 5 0 000 10z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
          </div>
        </div>
        <div class="flex justify-center text-white text-sm">
          <ColorPicker
            bind:rgb
            label={priceText}
            isPopup={true}
            isInput={true}
            isAlpha={false}
            isDark={true}
            on:input={(event) => {
              if (fUpdatePrice != null) {
                fUpdatePrice(event.detail.rgb);
              } else {
                console.log("fUpdatePrice is null");
              }
            }}
          />
        </div>
        <div>
          <button
            id="eraseBtn"
            class="block w-full mt-4 px-4 py-2 text-base font-medium text-white bg-red-500 rounded-md shadow-md hover:bg-red-900 focus:outline-none focus:ring-red-500 focus:ring-offset-2"
            >ERASE</button
          >
        </div>
      </div>
      <div
        class="flex items-center justify-center flex-col md:flex-row-reverse"
      >
        <div class="">
          <canvas
            id="canvas"
            class="block w-full border-2 my-4 justify-center items-center mx-auto"
            height={canvasWidth}
            width={canvasWidth}
          />
        </div>
      </div>
    </div>
    <div class="p-10 bg-black bottom-bar">
      <br />
      <div class="flex justify-between flex-col md:flex-row gap-y-6 md:gap-y-0">
        <div></div>
      </div>
    </div>
  </div>
</div>

<style>
  .info-box {
    font-size: 12px;
  }

  .tool-tip {
    font-size: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 200px;
    padding: 10px 20px;
  }

  .tooltip-svg {
    position: absolute;
    width: 20px;
    height: 10px;
    bottom: -5px;
    left: 50%;
    transform: translateX(-50%);
    overflow: visible;
  }

  .tooltip-svg path {
    fill: black;
  }

  .bottom-bar {
    /* border: 1px solid #4cc9ff; */
  }
</style>
