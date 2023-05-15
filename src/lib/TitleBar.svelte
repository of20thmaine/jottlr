<script lang="ts">
    import { appWindow } from '@tauri-apps/api/window';
    import { exit } from '@tauri-apps/api/process';
    import { goto } from '$app/navigation';
    import { ColorModeIsDark, ShowCreateCollection, WindowTitle } from '$lib/scripts/stores';
    import { ClickOutside } from "$lib/scripts/utils";
    import CreateCollection from '$lib/CreateCollection.svelte';
    import ExportDialog from '$lib/ExportDialog.svelte';
    import ImportDialog from '$lib/ImportDialog.svelte';

    let isDarkMode: boolean;
    let darkPath = "dark_";
    let lightPath = "light_";
    let currentPath = "";
    let showFileMenu = false;
    let showExportCollection = false;
    let showImportCollection = false;
    let windowTitle: string = "";
    
    WindowTitle.subscribe(value => windowTitle = value);
    ColorModeIsDark.subscribe(value => isDarkMode = value);

    $: isDarkMode ? currentPath = darkPath : currentPath = lightPath;

    function keyShortCutHandler(event: KeyboardEvent) {
        if (event.ctrlKey) {
            switch (event.key.toLowerCase()) {
                case "i":
                    showImportCollection = true;
                    break;
                case "e":
                    showExportCollection = true;
                    break;
                case "n":
                    goto("/quicknote");
                    break;
                case ",":
                    goto("/settings");
                    break;
            }
        }
    }
</script>

<svelte:window on:keydown={keyShortCutHandler}/>

<div data-tauri-drag-region class="titlebar">
    <a href="/">
        <div class="icon">
            <img src="../logo.png" alt="Logo" />
        </div>
    </a>
    <div class="selectHolder">
        <div class="selector menuSelector" class:menuSelectorSelected={showFileMenu}
                on:click={() => showFileMenu = true}
                on:keypress={() => showFileMenu = true}>
            <div class="selectedOpt">File</div>
        </div>
        {#if showFileMenu}
            <div class="selectorMenu fileSelectorMenu"
                    use:ClickOutside 
                    on:outclick={() => showFileMenu = false}>
                <div class="opt"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                goto("/quicknote");
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                goto("/quicknote");
                            }}>
                    <div class="optName">Quick Note</div>
                    <div class="optKey">Ctrl+N</div>
                </div>
                <div class="opt"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                showExportCollection = false;
                                $ShowCreateCollection = !$ShowCreateCollection;
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                showExportCollection = false;
                                $ShowCreateCollection = !$ShowCreateCollection;
                            }}>
                    <div class="optName">New Collection</div>
                </div>
                <div class="opt"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                $ShowCreateCollection = false;
                                showExportCollection = false;
                                showImportCollection = true;
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                $ShowCreateCollection = false;
                                showExportCollection = false;
                                showImportCollection = true;
                            }}>
                    <div class="optName">Import</div>
                    <div class="optKey">Ctrl+I</div>
                </div>
                <div class="opt"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                $ShowCreateCollection = false;
                                showImportCollection = false;
                                showExportCollection = true;
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                $ShowCreateCollection = false;
                                showImportCollection = false;
                                showExportCollection = true;
                            }}>
                    <div class="optName">Export As...</div>
                    <div class="optKey">Ctrl+E</div>
                </div>
                <div class="opt"
                        on:click={() => {
                                showFileMenu = !showFileMenu;
                                goto("/settings");
                            }}
                        on:keypress={() => {
                                showFileMenu = !showFileMenu;
                                goto("/settings");
                            }}>
                    <div class="optName">Settings</div>
                    <div class="optKey">Ctrl+,</div>
                </div>
                <div class="opt"
                        on:click={async () => {await exit(1)}}
                        on:keypress={async () => {await exit(1);}}>
                    <div class="optName">Exit</div>
                </div>
            </div>
        {/if}
    </div>
    <div class="center">
        <div class="title">{windowTitle}</div>
    </div>
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

{#if $ShowCreateCollection}
    <CreateCollection bind:showDialog={$ShowCreateCollection} />
{/if}

{#if showExportCollection}
    <ExportDialog bind:showDialog={showExportCollection} />
{/if}

{#if showImportCollection}
    <ImportDialog bind:showDialog={showImportCollection} />
{/if}

<style>
    .titlebar {
        position: relative;
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

    .center {
        margin: 0 auto;
        color: var(--fontColor);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .title {
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
        height: 65%;
    }

    .menuSelector {
        font-size: 0.9rem;
        padding: 0.25rem 0.5rem;
        background-color: var(--titlebarColor);
    }

    .menuSelector:hover {
        background-color: var(--fontColor);
        color: var(--titlebarColor);
    }

    .menuSelectorSelected {
        background-color: var(--fontColor);
        color: var(--titlebarColor);
        border-bottom-right-radius: 0;
        border-bottom-left-radius: 0;
    }

    .optKey {
        margin-left: auto;
    }

    .fileSelectorMenu {
        background-color: var(--backgroundColor);
        border: 1px solid var(--borderColor);
        font-size: 0.9rem;
        width: 200px;
    }

    .titlebar-button {
        display: inline-flex;
        justify-content: center;
        align-items: center;
        width: 30px;
        height: 30px;
        cursor: pointer;
        user-select: none;
    }

    .titlebar-button:hover {
        background: var(--hoverBtnColor);
    }

    #titlebar-close:hover {
        background: red;
    }
</style>
