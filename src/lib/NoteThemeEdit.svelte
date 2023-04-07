<script lang="ts">
    import { ClickOutside } from "$lib/scripts/utils";
    import ColorSelector from "$lib/ColorSelector.svelte";

    export let indentLevel: number;
    export let themePapa: Theme;
    export let save: () => void;

    let theme: NoteTheme;
    let showIndentSelect: boolean = false;
    let showFontSizeSelect: boolean = false;

    const MaxMargin: number = 72;
    const MaxFontSize: number = 72;
    let marginOpts: number[] = [4, 8, 16, 32, 64, 72];
    let fontOpts: number[] = [8,9,10,11,12,14,16,18,24,30,36,48,60,72]

    $: if (themePapa) load();

    function load() {
        if (indentLevel === -1) {
            if (!themePapa.default) {
                themePapa.default = {};
            }
            theme = themePapa.default;
        } else {
            if (!themePapa.noteThemes) {
                themePapa.noteThemes = [];
            }
            if (!themePapa.noteThemes[indentLevel]) {
                themePapa.noteThemes[indentLevel] = {};
            }
            theme = themePapa.noteThemes[indentLevel];
        }
    }
</script>

{#if theme}
    {#if indentLevel === -1}
        <h2>Theme-Wide Settings</h2>
    {:else}
        <h2>{indentLevel}-Indents Theme Settings</h2>
    {/if}

    <h3>Indent-Level</h3>
    <div class="row">
        <div class="lilBtn"
            on:click={() => {
                if (theme.marginLeft) {
                    if (theme.marginLeft > 1) {
                        theme.marginLeft--;
                    } else {
                        theme.marginLeft = undefined;
                    }
                }
                save();
            }}
            on:keypress={() => {
                if (theme.marginLeft) {
                    if (theme.marginLeft > 1) {
                        theme.marginLeft--;
                    } else {
                        theme.marginLeft = undefined;
                    }
                }
                save();
            }}><i class="bi bi-dash"></i></div>
        <div class="selectHolder">
            <div class="selector selIndents" class:selectorSelected={showIndentSelect}
                    on:click={() => showIndentSelect = true}
                    on:keypress={() => showIndentSelect = !showIndentSelect}>
                <div class="selected">{theme.marginLeft ? theme.marginLeft : "-"}</div>
            </div>
            {#if showIndentSelect}
                <div class="selectorMenu indentsMenu"
                        use:ClickOutside 
                        on:outclick={() => {
                                showIndentSelect = false;
                            }}>
                    <div class="opt indentOpt"
                            on:click={() => {
                                theme.marginLeft = undefined;
                                save();
                                showIndentSelect = !showIndentSelect;
                            }}
                            on:keypress={() => {
                                theme.marginLeft = undefined;
                                save();
                                showIndentSelect = !showIndentSelect;
                            }}>
                        -
                    </div>
                    {#each marginOpts as opt}
                        <div class="opt indentOpt"
                                on:click={() => {
                                    theme.marginLeft = opt;
                                    save();
                                    showIndentSelect = !showIndentSelect;
                                }}
                                on:keypress={() => {
                                    theme.marginLeft = opt;
                                    save();
                                    showIndentSelect = !showIndentSelect;
                                }}>
                            {opt}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
        <div class="lilBtn"
            on:click={() => {
                if (theme.marginLeft) {
                    if (theme.marginLeft < MaxMargin) {
                        theme.marginLeft++;
                    }
                } else {
                    theme.marginLeft = 1;
                }
            }}
            on:keypress={() => {

            }}><i class="bi bi-plus"></i></div>
    </div>

    <h3>Font Size</h3>
    <div class="row">
        <div class="lilBtn"
            on:click={() => {
                if (theme.fontSize) {
                    if (theme.fontSize > 1) {
                        theme.fontSize--;
                    } else {
                        theme.fontSize = undefined;
                    }
                }
                save();
            }}
            on:keypress={() => {
                if (theme.fontSize) {
                    if (theme.fontSize > 1) {
                        theme.fontSize--;
                    } else {
                        theme.fontSize = undefined;
                    }
                }
                save();
            }}><i class="bi bi-dash"></i></div>
        <div class="selectHolder">
            <div class="selector selIndents" class:selectorSelected={showFontSizeSelect}
                    on:click={() => showFontSizeSelect = true}
                    on:keypress={() => showFontSizeSelect = !showFontSizeSelect}>
                <div class="selected">{theme.fontSize ? theme.fontSize : "-"}</div>
            </div>
            {#if showFontSizeSelect}
                <div class="selectorMenu indentsMenu"
                        use:ClickOutside 
                        on:outclick={() => {
                                showFontSizeSelect = false;
                            }}>
                    <div class="opt indentOpt"
                            on:click={() => {
                                theme.fontSize = undefined;
                                save();
                                showFontSizeSelect = !showFontSizeSelect;
                            }}
                            on:keypress={() => {
                                theme.fontSize = undefined;
                                save();
                                showFontSizeSelect = !showFontSizeSelect;
                            }}>
                        -
                    </div>
                    {#each fontOpts as opt}
                        <div class="opt indentOpt"
                                on:click={() => {
                                    theme.fontSize = opt;
                                    save();
                                    showFontSizeSelect = !showFontSizeSelect;
                                }}
                                on:keypress={() => {
                                    theme.fontSize = opt;
                                    save();
                                    showFontSizeSelect = !showFontSizeSelect;
                                }}>
                            {opt}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
        <div class="lilBtn"
            on:click={() => {
                if (theme.fontSize) {
                    if (theme.fontSize < MaxFontSize) {
                        theme.fontSize++;
                    }
                } else {
                    theme.fontSize = 1;
                }
            }}
            on:keypress={() => {

            }}><i class="bi bi-plus"></i></div>
    </div>




    
    <h3>Page Colors:</h3>
    <ColorSelector
        color={""}
        prompt={""}
    />


    <h3>More</h3>


    <h3>More</h3>

{/if}

<style>
    h2 {
        font-size: 1.15rem;
        margin: 1.0rem 0;
        font-weight: 400;
        padding: 0.5rem 0;
        border-bottom: 1px solid;
        width: max-content;
    }

    h3 {
        font-size: 1.0rem;
        margin: 1.0rem 0;
        font-weight: 400;
    }

    .row {
        display: flex;
        align-items: center;
    }

    .selIndents {
        width: 42px;
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
    }

    .selected {
        width: 100%;
        text-align: center;
    }

    .indentsMenu {
        width: 42px;
        min-height: 20px;
        max-height: 160px;
        overflow-y: auto;
        scroll-behavior: smooth;
        -ms-overflow-style: none;
        scrollbar-width: none;
    }

    .indentsMenu::-webkit-scrollbar {
        display: none;
    }

    .indentOpt {
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
        justify-content: center;
    }

    .lilBtn {
        font-size: 1.2rem;
        margin: 0.25rem;
        cursor: pointer;
	    user-select: none;
    }
</style>
