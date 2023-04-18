<script lang="ts">
    import { ClickOutside } from "$lib/scripts/utils";
    import { GetCollections, GetCollectionsPositionals } from "$lib/scripts/db";
    import { GetUserThemeList } from "$lib/scripts/settings";
    import { exportOptions, ExportType, ExportToJottlr, ExportToTxt } from "$lib/scripts/fs";

    export let showDialog: boolean;

    let collections: CollectionSelection[];
    let selectedCollection: CollectionSelection;
    let positionals: Positional[];
    let selectedPositional: Positional | undefined;
    let themes: Theme[];
    let selectedTheme: Theme | undefined;

    let showCollectionSelect: boolean = false;
    let showPositionalSelect: boolean = false;
    let showThemeSelect: boolean = false;
    let showExportOptSelect: boolean = false;

    let selectedExportOption: ExportOption = exportOptions[0];

    loadCollections();
    loadThemes();

    function loadCollections() {
        GetCollections()
            .then((value) => {
                collections = value;
                if (collections.length > 0) {
                    selectedCollection = collections[0];
                    loadPositionals();
                }
            });
    }

    function loadPositionals() {
        GetCollectionsPositionals(selectedCollection.id)
            .then((value) => {
                positionals = value;
                if (positionals.length > 0) {
                    selectedPositional = positionals[0];
                }
            });
    }

    function loadThemes() {
        GetUserThemeList()
            .then((value) => {
                let userThemes = value;
                if (userThemes) {
                    themes = userThemes;
                }
            });
    }

    async function exportHandler() {
        switch (selectedExportOption.type) {
            case ExportType.Jottlr:
                await ExportToJottlr(selectedCollection as Collection, selectedTheme)
                    .catch((reason) => {
                        console.log(reason);
                    })
                    .then(() => showDialog = false);
                break;
            case ExportType.Text:
                await ExportToTxt(selectedCollection as Collection, selectedPositional)
                    .catch((reason) => {
                        console.log(reason);
                    })
                    .then(() => showDialog = false);
                break;
        }
    }
</script>

<div class="promptBox" 
        use:ClickOutside 
        on:outclick={() => showDialog = !showDialog}>
    <div class="closeBtn"
            on:click={() => showDialog = !showDialog}
            on:keypress={() => showDialog = !showDialog}>
        <i class="bi bi-x"></i></div>

    <h1 class="mB">Export As...</h1>

    <h2>Collection to Export:</h2>
    {#if selectedCollection}
        <div class="selectHolder mB">
            <div class="selector exSel" class:selectorSelected={showCollectionSelect}
                    on:click={() => showCollectionSelect = !showCollectionSelect}
                    on:keypress={() => showCollectionSelect = !showCollectionSelect}>
                <div class="selectedOpt">{selectedCollection.name}</div>
                <div class="tIco mL"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showCollectionSelect}
                <div class="selectorMenu exMen"
                        use:ClickOutside 
                        on:outclick={() => showCollectionSelect = !showCollectionSelect}>
                    {#each collections as opt}
                        <div class="opt"
                                on:click={() => {
                                    selectedCollection = opt;
                                    loadPositionals();
                                    showCollectionSelect = false;
                                }}
                                on:keypress={() => {
                                    selectedCollection = opt;
                                    loadPositionals();
                                    showCollectionSelect = false;
                                }}>
                            <div class="optName">{opt.name}</div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    {/if}
    
    {#if selectedExportOption.type !== ExportType.Jottlr}
        <h2>Positional to Export:</h2>
        <div class="selectHolder mB">
            <div class="selector exSel" class:selectorSelected={showPositionalSelect}
                    on:click={() => showPositionalSelect = !showPositionalSelect}
                    on:keypress={() => showPositionalSelect = !showPositionalSelect}>
                <div class="selectedOpt">{selectedPositional ? selectedPositional.name : "- Entire Collection -"}</div>
                <div class="tIco mL"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showPositionalSelect}
                <div class="selectorMenu exMen"
                        use:ClickOutside 
                        on:outclick={() => showPositionalSelect = !showPositionalSelect}>
                    <div class="opt"
                            on:click={() => {
                                selectedPositional = undefined;
                                showPositionalSelect = false;
                            }}
                            on:keypress={() => {
                                selectedPositional = undefined;
                                showPositionalSelect = false;
                            }}>
                        <div class="optName">- Entire Collection -</div>
                    </div>
                    {#if positionals}
                        {#each positionals as opt}
                            <div class="opt"
                                    on:click={() => {
                                        selectedPositional = opt;
                                        showPositionalSelect = false;
                                    }}
                                    on:keypress={() => {
                                        selectedPositional = opt;
                                        showPositionalSelect = false;
                                    }}>
                                <div class="optName">{opt.name}</div>
                            </div>
                        {/each}
                    {/if}
                </div>
            {/if}
        </div>
    {/if}

    {#if themes && selectedExportOption.type === ExportType.Jottlr}
        <h2>Include Theme?</h2>
        <div class="selectHolder mB">
            <div class="selector exSel" class:selectorSelected={showThemeSelect}
                    on:click={() => showThemeSelect = !showThemeSelect}
                    on:keypress={() => showThemeSelect = !showThemeSelect}>
                {#if selectedTheme}
                    <div class="selectedOpt">{selectedTheme.name}</div>
                {:else}
                    <div class="selectedOpt center">-</div>
                {/if}
                <div class="tIco mL"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showThemeSelect}
                <div class="selectorMenu exMen"
                        use:ClickOutside 
                        on:outclick={() => showThemeSelect = !showThemeSelect}>
                    <div class="opt"
                            on:click={() => {
                                selectedTheme = undefined;
                                showThemeSelect = false;
                            }}
                            on:keypress={() => {
                                selectedTheme = undefined;
                                showThemeSelect = false;
                            }}>
                        <div class="optName center">-</div>
                    </div>
                    {#each themes as opt}
                        <div class="opt"
                                on:click={() => {
                                    selectedTheme = opt;
                                    showThemeSelect = false;
                                }}
                                on:keypress={() => {
                                    selectedTheme = opt;
                                    showThemeSelect = false;
                                }}>
                            <div class="optName">{opt.name}</div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    {/if}

    <h2>File Type:</h2>
    <div class="selectHolder">
        <div class="selector exSel" class:selectorSelected={showExportOptSelect}
                on:click={() => showExportOptSelect = !showExportOptSelect}
                on:keypress={() => showExportOptSelect = !showExportOptSelect}>
            <div class="selectedOpt">{selectedExportOption.name}</div>
            <div class="tIco mL"><i class="bi bi-chevron-down"></i></div>
        </div>
        {#if showExportOptSelect}
            <div class="selectorMenu exMen"
                    use:ClickOutside 
                    on:outclick={() => showExportOptSelect = !showExportOptSelect}>
                {#each exportOptions as opt}
                    <div class="opt"
                            on:click={() => {
                                selectedExportOption = opt;
                                showExportOptSelect = false;
                            }}
                            on:keypress={() => {
                                selectedExportOption = opt;
                                showExportOptSelect = false;
                            }}>
                        <div class="optName">{opt.name}</div>
                    </div>
                {/each}
            </div>
        {/if}
    </div>
    <div class="exportBtn"
            on:click={exportHandler}
            on:keypress={exportHandler}>
        Export
    </div>
</div>

<style>
    .promptBox {
        margin: 0;
        position: absolute;
        z-index: 3;
        top: 45%;
        left: 50%;
        transform: translate(-50%, -50%);
        background-color: var(--backgroundColor);
        border: 1px solid var(--hoverBtnColor);
        width: max-content;
        padding: 1.0rem 1.5rem;
    }

    .closeBtn {
        position: fixed;
        top: 0.5rem;
        right: 0.5rem;
        color: var(--fontColor);
        font-size: 1.25rem;
        cursor: pointer;
    }

    .closeBtn:hover {
        color: red;
    }

    h1 {
        color: var(--fontColor);
        font-weight: 600;
        font-size: 1.05rem;
    }

    h2 {
        color: var(--fontColor);
        font-weight: 400;
        font-size: 1.00rem;
        margin-bottom: 0.5rem;
    }

    .exSel {
        width: 240px;
        padding: 0.5rem;
    }

    .exMen {
        width: 240px;
    }

    .mB {
        margin-bottom: 1.0rem;
    }

    .mL {
        margin-left: auto;
    }

    .center {
        width: 100%;
        text-align: center;
    }

    .exportBtn {
        border: 1px solid;
        border-radius: 4px;
        color: #be349c;
        padding: 0.2rem 1.5rem;
        width: fit-content;
        font-weight: 500;
        margin-top: 1.0rem;
        cursor: pointer;
	    user-select: none;
        margin-left: auto;
    }
</style>
