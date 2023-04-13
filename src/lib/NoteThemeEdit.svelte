<script lang="ts">
    import { Labels } from "$lib/scripts/settings";
    import { ClickOutside } from "$lib/scripts/utils";
    import ColorSelector from "$lib/ColorSelector.svelte";

    export let indentLevel: number;
    export let themePapa: Theme;
    export let save: () => void;

    let theme: NoteTheme;
    let showIndentSelect: boolean = false;
    let showFontSizeSelect: boolean = false;
    let showFontWeightSelect: boolean = false;
    let showLabelSelect: boolean = false;
    let showLabelFontSizeSelect: boolean = false;
    let showLabelFontWeightSelect: boolean = false;

    const MaxMargin: number = 72;
    const MaxFontSize: number = 72;
    const marginOpts: number[] = [4,8,16,32,64,72];
    const fontOpts: number[] = [8,9,10,11,12,14,16,18,24,30,36,48,60,72];
    const fontWeightOpts: FontWeight[] = [{name:"Light",value:"300"},{name:"Normal",value:"400"},
        {name:"Semi-Bold",value:"600"},{name:"Bold",value:"700"}];

    $: themePapa, indentLevel, load();
    $: theme.marginLeft, theme.fontSize, theme.fontWeight, theme.fontColor, theme.bubbleColor, theme.label, save();
    $: theme.labelTheme, theme.labelTheme?.fontSize, theme.labelTheme?.fontWeight, theme.labelTheme?.fontColor, save();

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
    <div class="row mB">
        {#if indentLevel === -1}
            <div class="headerIco"
                    title="Settings applied here will apply to all indent levels unless overridden.">
                <i class="bi bi-easel"></i></div>
            <h2>Theme-Wide:</h2>
        {:else}
            <div class="headerIco"><i class="bi bi-list-nested"></i></div>
            <h2>{indentLevel}-Indents:</h2>
        {/if}
    </div>
    
    <h3>Indent-Level:</h3>
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
            }}
            on:keypress={() => {
                if (theme.marginLeft) {
                    if (theme.marginLeft > 1) {
                        theme.marginLeft--;
                    } else {
                        theme.marginLeft = undefined;
                    }
                }
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
                                showIndentSelect = !showIndentSelect;
                            }}
                            on:keypress={() => {
                                theme.marginLeft = undefined;
                                showIndentSelect = !showIndentSelect;
                            }}>
                        -
                    </div>
                    {#each marginOpts as opt}
                        <div class="opt indentOpt"
                                on:click={() => {
                                    theme.marginLeft = opt;
                                    showIndentSelect = !showIndentSelect;
                                }}
                                on:keypress={() => {
                                    theme.marginLeft = opt;
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
                if (theme.marginLeft) {
                    if (theme.marginLeft < MaxMargin) {
                        theme.marginLeft++;
                    }
                } else {
                    theme.marginLeft = 1;
                }
            }}><i class="bi bi-plus"></i></div>
    </div>

    <h3>Font Size:</h3>
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
            }}
            on:keypress={() => {
                if (theme.fontSize) {
                    if (theme.fontSize > 1) {
                        theme.fontSize--;
                    } else {
                        theme.fontSize = undefined;
                    }
                }
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
                                showFontSizeSelect = !showFontSizeSelect;
                            }}
                            on:keypress={() => {
                                theme.fontSize = undefined;
                                showFontSizeSelect = !showFontSizeSelect;
                            }}>
                        -
                    </div>
                    {#each fontOpts as opt}
                        <div class="opt indentOpt"
                                on:click={() => {
                                    theme.fontSize = opt;
                                    showFontSizeSelect = !showFontSizeSelect;
                                }}
                                on:keypress={() => {
                                    theme.fontSize = opt;
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
                if (theme.fontSize) {
                    if (theme.fontSize < MaxFontSize) {
                        theme.fontSize++;
                    }
                } else {
                    theme.fontSize = 1;
                }
            }}><i class="bi bi-plus"></i></div>
    </div>

    <h3>Font Weight:</h3>
    <div class="row">
        <div class="selectHolder">
            <div class="selector selWeights" class:selectorSelected={showFontWeightSelect}
                    on:click={() => showFontWeightSelect = true}
                    on:keypress={() => showFontWeightSelect = !showFontWeightSelect}>
                {theme.fontWeight ? theme.fontWeight.name : "-"}
                <i class="bi bi-chevron-down rI"></i>
            </div>
            {#if showFontWeightSelect}
                <div class="selectorMenu indentsMenu weightsMenu"
                        use:ClickOutside 
                        on:outclick={() => {
                                showFontWeightSelect = false;
                            }}>
                    <div class="opt weightOpt"
                            on:click={() => {
                                theme.fontWeight = undefined;
                                showFontWeightSelect = !showFontWeightSelect;
                            }}
                            on:keypress={() => {
                                theme.fontWeight = undefined;
                                showFontWeightSelect = !showFontWeightSelect;
                            }}>
                        -
                    </div>
                    {#each fontWeightOpts as opt}
                        <div class="opt weightOpt"
                                on:click={() => {
                                    theme.fontWeight = opt;
                                    showFontWeightSelect = !showFontWeightSelect;
                                }}
                                on:keypress={() => {
                                    theme.fontWeight = opt;
                                    showFontWeightSelect = !showFontWeightSelect;
                                }}>
                            {opt.name}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    </div>

    <h3>Font Color:</h3>
    <ColorSelector bind:value={theme.fontColor} />

    <h3>Background Color:</h3>
    <ColorSelector bind:value={theme.bubbleColor} />

    <h3>Label:</h3>
    <div class="selectHolder">
        <div class="selector selLabel" class:selectorSelected={showLabelSelect}
                on:click={() => showLabelSelect = true}
                on:keypress={() => showLabelSelect = !showLabelSelect}>
            {theme.label ? theme.label.name : "-"}
            <div class="labelIco"><i class="bi bi-chevron-down"></i></div>
        </div>
        {#if showLabelSelect}
            <div class="selectorMenu labelMenu"
                    use:ClickOutside 
                    on:outclick={() => {
                            showLabelSelect = false;
                        }}>
                    <div class="opt"
                            on:click={() => {
                                theme.label = undefined;
                                theme.labelTheme = undefined;
                                showLabelSelect = !showLabelSelect;
                            }}
                            on:keypress={() => {
                                theme.label = undefined;
                                theme.labelTheme = undefined;
                                showLabelSelect = !showLabelSelect;
                            }}>
                        -
                    </div>
                {#each Labels as label}
                    <div class="opt"
                            on:click={() => {
                                theme.label = label;
                                if (!theme.labelTheme) theme.labelTheme = {};
                                showLabelSelect = !showLabelSelect;
                            }}
                            on:keypress={() => {
                                theme.label = label;
                                if (!theme.labelTheme) theme.labelTheme = {};
                                showLabelSelect = !showLabelSelect;
                            }}>
                        {label.name}
                        <div class="labelIco" bind:innerHTML={label.demo} contenteditable="false" />
                    </div>
                {/each}
            </div>
        {/if}
    </div>

    {#if theme.labelTheme !== undefined}
        <div class="row bufferedRow">
            <div class="headerIco"><i class="bi bi-list-ol"></i></div>
            <h2>Label Settings:</h2>
        </div>
        <h3>Label Font Size:</h3>
        <div class="row">
            <div class="lilBtn"
                on:click={() => {
                    if (theme.labelTheme?.fontSize) {
                        if (theme.labelTheme.fontSize > 1) {
                            theme.labelTheme.fontSize--;
                        } else {
                            theme.labelTheme.fontSize = undefined;
                        }
                    }
                }}
                on:keypress={() => {
                    if (theme.labelTheme?.fontSize) {
                        if (theme.labelTheme.fontSize > 1) {
                            theme.labelTheme.fontSize--;
                        } else {
                            theme.labelTheme.fontSize = undefined;
                        }
                    }
                }}><i class="bi bi-dash"></i></div>
            <div class="selectHolder">
                <div class="selector selIndents" class:selectorSelected={showLabelFontSizeSelect}
                        on:click={() => showLabelFontSizeSelect = true}
                        on:keypress={() => showLabelFontSizeSelect = !showLabelFontSizeSelect}>
                    <div class="selected">{theme.labelTheme.fontSize ? theme.labelTheme.fontSize : "-"}</div>
                </div>
                {#if showLabelFontSizeSelect}
                    <div class="selectorMenu indentsMenu"
                            use:ClickOutside 
                            on:outclick={() => {
                                    showLabelFontSizeSelect = false;
                                }}>
                        <div class="opt indentOpt"
                                on:click={() => {
                                    if (theme.labelTheme) theme.labelTheme.fontSize = undefined;
                                    showLabelFontSizeSelect = !showLabelFontSizeSelect;
                                }}
                                on:keypress={() => {
                                    if (theme.labelTheme) theme.labelTheme.fontSize = undefined;
                                    showLabelFontSizeSelect = !showLabelFontSizeSelect;
                                }}>
                            -
                        </div>
                        {#each fontOpts as opt}
                            <div class="opt indentOpt"
                                    on:click={() => {
                                        if (theme.labelTheme) theme.labelTheme.fontSize = opt;
                                        showLabelFontSizeSelect = !showLabelFontSizeSelect;
                                    }}
                                    on:keypress={() => {
                                        if (theme.labelTheme) theme.labelTheme.fontSize = opt;
                                        showLabelFontSizeSelect = !showLabelFontSizeSelect;
                                    }}>
                                {opt}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>
            <div class="lilBtn"
                on:click={() => {
                    if (theme.labelTheme?.fontSize) {
                        if (theme.labelTheme.fontSize < MaxFontSize) {
                            theme.labelTheme.fontSize++;
                        }
                    } else {
                        if (theme.labelTheme) theme.labelTheme.fontSize = undefined;
                    }
                }}
                on:keypress={() => {
                    if (theme.labelTheme?.fontSize) {
                        if (theme.labelTheme.fontSize < MaxFontSize) {
                            theme.labelTheme.fontSize++;
                        }
                    } else {
                        if (theme.labelTheme) theme.labelTheme.fontSize = 1;
                    }
                }}><i class="bi bi-plus"></i></div>
        </div>
    
        <h3>Label Font Weight:</h3>
        <div class="row">
            <div class="selectHolder">
                <div class="selector selWeights" class:selectorSelected={showLabelFontWeightSelect}
                        on:click={() => showLabelFontWeightSelect = true}
                        on:keypress={() => showLabelFontWeightSelect = !showLabelFontWeightSelect}>
                    {theme.labelTheme.fontWeight ? theme.labelTheme.fontWeight.name : "-"}
                    <i class="bi bi-chevron-down rI"></i>
                </div>
                {#if showLabelFontWeightSelect}
                    <div class="selectorMenu indentsMenu weightsMenu"
                            use:ClickOutside 
                            on:outclick={() => {
                                    showLabelFontWeightSelect = false;
                                }}>
                        <div class="opt weightOpt"
                                on:click={() => {
                                    if (theme.labelTheme) theme.labelTheme.fontWeight = undefined;
                                    showLabelFontWeightSelect = !showLabelFontWeightSelect;
                                }}
                                on:keypress={() => {
                                    if (theme.labelTheme) theme.labelTheme.fontWeight = undefined;
                                    showLabelFontWeightSelect = !showLabelFontWeightSelect;
                                }}>
                            -
                        </div>
                        {#each fontWeightOpts as opt}
                            <div class="opt weightOpt"
                                    on:click={() => {
                                        if (theme.labelTheme) theme.labelTheme.fontWeight = opt;
                                        showLabelFontWeightSelect = !showLabelFontWeightSelect;
                                    }}
                                    on:keypress={() => {
                                        if (theme.labelTheme) theme.labelTheme.fontWeight = opt;
                                        showLabelFontWeightSelect = !showLabelFontWeightSelect;
                                    }}>
                                {opt.name}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>
        </div>
    
        <h3>Label Font Color:</h3>
        <ColorSelector bind:value={theme.labelTheme.fontColor} />
    {/if}
{/if}

<style>
    h2 {
        font-size: 1.1rem;
        font-weight: 400;
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

    .mB {
        margin-bottom: 1.5rem;
    }

    .bufferedRow {
        margin: 1.5rem 0;
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
        padding: 0.3rem 0.5rem 0.3rem 0.5rem;
        justify-content: center;
    }

    .selWeights {
        padding: 0.3rem 0.3rem 0.25rem 0.3rem;
        width: 120px;
    }

    .weightsMenu {
        width: 120px;
    }

    .weightOpt {
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
    }

    .lilBtn {
        font-size: 1.2rem;
        margin: 0.25rem;
        cursor: pointer;
	    user-select: none;
    }

    .selLabel {
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
        width: 270px;
    }

    .labelMenu {
        width: 270px;
    }

    .labelIco {
        margin-left: auto;
    }

    .headerIco {
        margin-right: 1.0rem;
        color: #d7b474;
    }

    .rI {
        margin-left: auto;
    }
</style>
