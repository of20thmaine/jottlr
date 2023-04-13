<script lang="ts">
    import { SetColorModeIsDark, GetPageWidth, SetPageWidth } from "$lib/scripts/settings";
    import { ClickOutside } from "$lib/scripts/utils";
    import { ColorModeIsDark, WindowTitle } from "$lib/scripts/stores";

    WindowTitle.set("Settings");

    let showColorThemeSelect: boolean = false;
    let colorThemePrompt: string = "";
    let pageWidth: number = 800;

    $: SetPageWidth(pageWidth);

    GetPageWidth().then((value) => {if (value) pageWidth = value});

    function setColorTheme(makeDarkMode: boolean) {
        SetColorModeIsDark(makeDarkMode);
        ColorModeIsDark.set(makeDarkMode);
    }

    ColorModeIsDark.subscribe((value) => {
        if (value) {
            colorThemePrompt = "Dark Mode";
        } else {
            colorThemePrompt = "Light Mode";
        }
    });
</script>

<div class="scroller">
    <div class="page">
        <h1>Settings</h1>
        <h3>Color Mode:</h3>
        <div class="selector" class:selectorSelected={showColorThemeSelect}
                on:click={() => {showColorThemeSelect = !showColorThemeSelect}}
                on:keypress={() => {showColorThemeSelect = !showColorThemeSelect}}>
            <div class="selected">{colorThemePrompt}</div>
            <i class="bi bi-chevron-down rI"></i>
        </div>
        {#if showColorThemeSelect}
            <div class="selectorMenu"
                    use:ClickOutside
                    on:outclick={() => showColorThemeSelect = !showColorThemeSelect}>
                <div class="opt"
                        on:click={() => {
                            setColorTheme(true);
                            showColorThemeSelect = !showColorThemeSelect;
                        }}
                        on:keypress={() => {
                            setColorTheme(true);
                            showColorThemeSelect = !showColorThemeSelect;
                        }}>
                    Dark Mode</div>
                <div class="opt"
                        on:click={() => {
                            setColorTheme(false);
                            showColorThemeSelect = !showColorThemeSelect;
                        }}
                        on:keypress={() => {
                            setColorTheme(false);
                            showColorThemeSelect = !showColorThemeSelect;
                        }}>
                    Light Mode</div>
            </div>
        {/if}
        <h3 class="bigMT">Page Width:</h3>
        <div class="sliderHolder">
            <input type="range" min="400" max="1600" class="slider" id="pageWidth" bind:value={pageWidth}>
        </div>
        <div class="pageWidth">{pageWidth}px {pageWidth === 800 ? "(default)" : ""}</div>
        <h3 class="bigMT">Themes:</h3>
        <a href="./themeeditor/0"><div class="themeEditor">Open Theme Editor</div></a>
    </div>
</div>

<style>
    .page {
        margin: 0 auto;
        max-width: 600px;
        padding: 1.0rem;
        overflow-y: auto;
        color: var(--fontColor);
    }

    h1 {
        font-size: 1.5rem;
        border-bottom: 1px solid;
        margin-bottom: 1.0rem;
        padding: 0.5rem;
    }

    h3 {
        font-size: 1.15rem;
        margin-bottom: 0.5rem;
    }

    a {
        text-decoration: none;
    }
    
    .bigMT {
        margin-top: 3.0rem;
    }

    .selector {
        display: flex;
        align-items: center;
        background-color: var(--textfieldColor);
        cursor: pointer;
        user-select: none;
        padding: 0.5rem 1.0rem 0.5rem 0.5rem;
        width: 220px;
        border: 1px solid transparent;
        border-radius: 4px;
    }

    .selectorSelected {
        border: 1px solid var(--fontColor);
        background-color: var(--fontColor);
        color: var(--textfieldColor);
    }

    .selectorMenu {
        position: fixed;
        margin-top: -4px;
        z-index: 3;
        color: var(--fontColor);
        width: 220px;
        border-right: 1px solid;
        border-bottom: 1px solid;
        border-left: 1px solid;
        background-color: var(--textfieldColor);
        cursor: pointer;
        user-select: none;
        border-bottom-left-radius: 4px;
        border-bottom-right-radius: 4px;
    }

    .opt {
        padding: 0.5rem 1.0rem 0.5rem 0.5rem;
    }

    .opt:hover {
        background-color: var(--highlightColor);
    }

    .rI {
        margin-left: auto;
    }

    .sliderHolder {
        max-width: 400px;
        margin: 1.0rem 0;
    }

    .slider {
        width: 100%;
    }

    .themeEditor {
        border: 1px solid;
        border-radius: 4px;
        color: #d7b474;
        font-size: 1.2rem;
        width: max-content;
        padding: 0.4rem 2.0rem;
        margin-top: 1.0rem;
    }

    .themeEditor:hover {
        background-color: #d7b474;
        color: var(--fontColor);
    }
</style>
