<script>
  import { base } from '$app/paths';
  import { page } from "$app/stores";
  import { onDestroy, onMount } from "svelte";
  import { locale, translation } from "$lib/stores/i18n";

  $: t = $translation;
  $: lang = $locale;

  let menuOpen = false;
  let deviceWidth;
  let device;

  function updateDeviceWidth() {
    deviceWidth = window.innerWidth;
    device = deviceWidth > 768 ? "desktop" : "mobile";
  }

  onMount(() => {
    if (typeof window !== "undefined") {
      updateDeviceWidth();

      window.addEventListener("resize", updateDeviceWidth);
    }
  });

  // onDestroy(() => {
  //   window.removeEventListener("resize", updateDeviceWidth);
  // });

  function setLanguage(lang) {
    locale.set(lang);
  }

  function toggleMenu() {
    menuOpen = !menuOpen;
  }
</script>

<header class="bg-gray-800 text-white">
  <div class="px-10">
    <div class="flex w-full md:flex-row justify-between h-16">
      <div class="flex items-center">
        <h4 class="text-sm"><a href="{base}/">Graffiti NFT</a></h4>
      </div>
      <div class="hidden md:flex items-center">
        <div class="ml-10 flex items-center space-x-4">
          <p
            class="rainbowText"
            aria-current={$page.url.pathname === "/" ? "page" : undefined}
          >
            <a href="{base}/"> {t("Header.Graveyard")} </a>
          </p>
          <p
            class="rainbowText"
            aria-current={$page.url.pathname === "/mint" ? "page" : undefined}
          >
            <a href="{base}/mint">{t("Header.Souldraw")}</a>
          </p>
          <p
            class="rainbowText"
            aria-current={$page.url.pathname.startsWith("/connect")
              ? "page"
              : undefined}
          >
            <a href="{base}/connect">{t("Header.Wallet")}</a>
          </p>
        </div>
      </div>
    </div>
  </div>
  <!-- Mobile menu, show/hide based on menu state -->
  <div class="mr-2 flex md:hidden">
    <!-- Mobile menu button -->
    <button
      on:click={toggleMenu}
      class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none"
    >
      <span class="sr-only">Open main menu</span>
      <!-- Icon when menu is closed. -->
      <svg
        class="{menuOpen ? 'hidden' : 'block'} h-6 w-6"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M4 6h16M4 12h16m-7 6h7"
        />
      </svg>
      <div class="{menuOpen ? 'block' : 'hidden'} md:hidden bg-gray-800">
        <div class="px-2 pt-2 pb-3 space-y-1 sm:px-3">
          <!-- Duplicate Navigation links for mobile -->
          <a
            href="{base}/"
            class="block px-3 py-2 rounded-md text-sm text-white hover:bg-gray-700"
          >
            {t("Header.Graveyard")}
          </a>
          <a
            href="{base}/mint"
            class="block px-3 py-2 rounded-md text-sm text-white hover:bg-gray-700"
          >
            {t("Header.Souldraw")}
          </a>
          <a
            href="{base}/connect"
            class="block px-3 py-2 rounded-md text-sm text-white hover:bg-gray-700"
          >
            {t("Header.Wallet")}
          </a>
        </div>
      </div>
    </button>
  </div>
</header>

<style>
  /* Rainbow Text */
  .rainbowText {
    /* font-size: 70px; */
    color: white;
    -webkit-background-clip: text;
  }
  .rainbowText:hover {
    background-image: linear-gradient(
      to right,
      red,
      orange,
      yellow,
      green,
      rgb(255, 0, 43),
      rgb(252, 123, 252)
    );
    animation: move 140s linear infinite;
    -webkit-text-fill-color: transparent;
  }

  @keyframes move {
    to {
      background-position: 4500vh;
    }
  }
</style>
