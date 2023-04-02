<script lang="ts">
    import { appWindow } from '@tauri-apps/api/window';
    import { exit } from '@tauri-apps/api/process';
    import { goto } from '$app/navigation';
    import { ColorModeIsDark, WindowTitle } from '$lib/scripts/stores';
    import { ClickOutside } from "$lib/scripts/utils";
    import CreateCollection from '$lib/CreateCollection.svelte';

    let isDarkMode: boolean;
    let darkPath = "dark_";
    let lightPath = "light_";
    let currentPath = "";
    let showFileMenu = false;
    let showCreateCollection = false;
    let windowTitle: string = "";
    
    WindowTitle.subscribe(value => windowTitle = value);
    ColorModeIsDark.subscribe(value => isDarkMode = value);

    $: isDarkMode ? currentPath = darkPath : currentPath = lightPath;
</script>

<div data-tauri-drag-region class="titlebar">
    <a href="/">
        <div class="icon">
            <img
                src="../logo.png"
                alt="Logo"
            />
        </div>
    </a>
    <div class="menuSelection"
            on:click={() => showFileMenu = !showFileMenu}
            on:keypress={() => showFileMenu = !showFileMenu}>File</div>
        {#if showFileMenu}
            <div class="dropdown"
                    use:ClickOutside 
                    on:outclick={() => showFileMenu = !showFileMenu}>
                <div class="dropdownItm"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                goto("/quicknote");
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                goto("/quicknote");
                            }}>
                    Quick Note...</div>
                <div class="dropdownItm"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                showCreateCollection = !showCreateCollection;
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                showCreateCollection = !showCreateCollection;
                            }}>
                    New Collection...</div>
                    <div class="dropdownItm"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                goto("/settings");
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                goto("/settings");
                            }}>
                    Settings...</div>
                <div class="dropdownItm"
                        on:click={async () => {await exit(1)}}
                        on:keypress={async () => {await exit(1);}}>
                    Exit</div>
            </div>
        {/if}
    <div class="title">{windowTitle}</div>
    <div class="titlebar-button" id="titlebar-minimize"
            on:click={() => {appWindow.minimize()}}
            on:keypress={() => {appWindow.minimize()}}>
        <img
            src="../img/{currentPath}window_btns/mdi_window-minimize.svg"
            alt="minimize"
        />
    </div>
    <div class="titlebar-button" id="titlebar-maximize"
            on:click={() => {appWindow.toggleMaximize()}}
            on:keypress={() => {appWindow.toggleMaximize()}}>
        <img
            src="../img/{currentPath}window_btns/mdi_window-maximize.svg"
            alt="maximize"
        />
    </div>
    <div class="titlebar-button" id="titlebar-close"
            on:click={() => {appWindow.close()}}
            on:keypress={() => {appWindow.close()}}>
        <img
            src="../img/{currentPath}window_btns/mdi_close.svg"
            alt="close"
        />
    </div>
</div>

{#if showCreateCollection}
    <CreateCollection bind:showCreateCollection={showCreateCollection} />
{/if}

<style>
    .titlebar {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        height: var(--titlebarHeight);
        background-color: var(--titlebarColor);
        user-select: none;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .menuSelection {
        font-size: 0.9rem;
        color: var(--fontColor);
        padding: 0.4rem;
    }

    .menuSelection:hover {
        background-color: var(--hoverBtnColor);
    }

    .title {
        margin: 0 auto;
        color: var(--fontColor);
        font-style: italic;
        font-size: 0.9rem;
    }

    .icon {
        display: inline-flex;
        justify-content: center;
        align-items: center;
        width: 30px;
        height: 30px;
        margin: 0 0.6rem;
    }

    .icon img {
        height: 60%;
    }

    .dropdown {
        position: fixed;
        z-index: 4;
        top: 30px;
        left: 2.5rem;
        background-color: var(--backgroundColor);
        border: 1px solid var(--borderColor);
        font-size: 0.9rem;
        padding: 0.3rem;
    }

    .dropdownItm {
        color: var(--fontColor);
        padding: 0.3rem;
    }

    .dropdownItm:hover {
        background-color: var(--highlightColor);
    }

    .titlebar-button {
        display: inline-flex;
        justify-content: center;
        align-items: center;
        width: 30px;
        height: 30px;
    }

    .titlebar-button:hover {
        background: var(--hoverBtnColor);
    }

    #titlebar-close:hover {
        background: red;
    }
</style>
