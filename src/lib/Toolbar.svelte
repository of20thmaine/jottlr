<script lang="ts">
    import { goto } from '$app/navigation';
    import { EditModes, ChangeOption } from "$lib/scripts/settings";
    import { ClickOutside } from "$lib/scripts/utils";
    import CreatePositional from "$lib/CreatePositional.svelte";
    import RenameDialog from '$lib/RenameDialog.svelte';
    import DeleteDialog from '$lib/DeleteDialog.svelte';

    export let editMode: EditMode;
    export let viewMode: ViewMode;
    export let viewModes: ViewModeCategory[];
    export let theme: Theme;
    export let themes: Theme[];
    export let collection: Collection;
    export let pageWidth: Number;
    export let changeEditMode: (modeSelection: number) => void;
    export let changeViewMode: (categoryId: number, optionId: number) => void;
    export let loadPositionals: () => Promise<void>;

    let showEditModeSelect: boolean = false;
    let showViewModeSelect: boolean = false;
    let showThemeSelect: boolean = false;
    let showOtherOptsSelect: boolean = false;
    let showDeletePositional: boolean = false;
    let showDeleteCollection: boolean = false;
    let showRenamePositional: boolean = false;
    let showRenameCollection: boolean = false;
    let showCreatePositional: boolean = false;
</script>

<div class="outer">
    <div class="toolBar" style="max-width:{pageWidth}px;">
        <div class="selectHolder">
            <div class="selector selTB {editMode.class}" class:selectorSelected={showEditModeSelect}
                    on:click={() => showEditModeSelect = true}
                    on:keypress={() => showEditModeSelect = true}>
                <div class="ico {editMode.class}"><i class="{editMode.ico}"></i></div>
                <div class="name {editMode.class}">{editMode.name}</div>
                <div class="tIco"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showEditModeSelect}
                <div class="selectorMenu smTB"
                        use:ClickOutside 
                        on:outclick={() => showEditModeSelect = false}>
                    {#each EditModes as mode}
                        <div class="opt"
                                on:click={() => {
                                    changeEditMode(mode.id);
                                    showEditModeSelect = false;
                                }}
                                on:keypress={() => {
                                    changeEditMode(mode.id);
                                    showEditModeSelect = false;
                                }}>
                            <div class="ico"><i class="{mode.ico}"></i></div>
                            <div class="name">{mode.name}</div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
        <div class="selectHolder mL">
            <div class="selector selTBVM" class:selectorSelected={showViewModeSelect}
                    on:click={() => showViewModeSelect = true}
                    on:keypress={() => showViewModeSelect = true}>
                {#if viewMode.isSortable}
                    <div class="ico"><i class="{viewMode.ico}"></i></div>
                {:else}
                    <div class="ico"><i class="bi bi-list-ol"></i></div>
                {/if}
                <div class="name">{viewMode.name}</div>
                <div class="tIco"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showViewModeSelect}
                <div class="selectorMenu selTBVMsm"
                        use:ClickOutside 
                        on:outclick={() => showViewModeSelect = false}>
                    {#each viewModes as viewModeCat}
                        <div class="cat catCo">
                            <i class="{viewModeCat.ico}"></i>
                            <div class="catName">{viewModeCat.name}</div>
                        </div>
                        {#each viewModeCat.options as option}
                            <div class="opt"
                                    on:click={() => {
                                        changeViewMode(viewModeCat.id, option.id);
                                        showViewModeSelect = false;
                                    }}
                                    on:keypress={() => {
                                        changeViewMode(viewModeCat.id, option.id);
                                        showViewModeSelect = false;
                                    }}>
                                <div class="name">{option.name}</div>
                                {#if option.isSortable}
                                    <i class="{option.ico}"></i>
                                {:else}
                                    <i class="bi bi-list"></i>
                                {/if}
                            </div>
                        {/each}
                    {/each}
                    <div class="opt append"
                            on:click={() => {
                                showViewModeSelect = false;
                                showCreatePositional = !showCreatePositional;
                            }}
                            on:keypress={() => {
                                showViewModeSelect = false;
                                showCreatePositional = !showCreatePositional;
                            }}>
                        <div class="name">Create New</div>
                        <div class="ico"><i class="bi bi-plus-lg"></i></div>
                    </div>
                </div>
            {/if}
        </div>

        <div class="selectHolder mL">
            <div class="selector selTheme" class:selectorSelected={showThemeSelect}
                    on:click={() => showThemeSelect = !showThemeSelect}
                    on:keypress={() => showThemeSelect = !showThemeSelect}>
                <div class="ico"><i class="bi bi-easel"></i></div>
                <div class="name">{theme.name}</div>
                <div class="tIco"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showThemeSelect}
                <div class="selectorMenu themeMenu"
                        use:ClickOutside 
                        on:outclick={() => {
                                showThemeSelect = false;
                            }}>
                    {#each themes as themeOpt}
                        <div class="opt themeOpt"
                                on:click={() => {
                                    theme = themeOpt;
                                    showThemeSelect = !showThemeSelect;
                                }}
                                on:keypress={() => {
                                    theme = themeOpt;
                                    showThemeSelect = !showThemeSelect;
                                }}>
                            {themeOpt.name}
                            {#if themeOpt.system}
                                <i class="bi bi-gear mLA"></i>
                            {:else}
                                <i class="bi bi-person mLA"></i>
                            {/if}
                        </div>
                    {/each}
                    <div class="opt themeOpt themeCo"
                            on:click={() => goto("/themeeditor/" + theme.id)}
                            on:keypress={() => goto("/themeeditor/" + theme.id)}>
                        Create / Edit Themes
                        <i class="bi bi-plus-lg mLA"></i>
                    </div>
                </div>
            {/if}
        </div>

        <div class="selectHolder mla">
            <div class="otherOpts" class:optsSelected={showOtherOptsSelect}
                    on:click={() => showOtherOptsSelect = true}
                    on:keypress={() => showOtherOptsSelect = true}>
                <i class="bi bi-three-dots-vertical"></i>
            </div>
            {#if showOtherOptsSelect}
                <div class="optMenu"
                        use:ClickOutside 
                        on:outclick={() => {
                                showOtherOptsSelect = false;
                            }}>
                    {#if !viewMode.isSortable}
                        <div class="optsOpt"
                                on:click={() => {
                                    showOtherOptsSelect = false;
                                    showRenamePositional = true;
                                }}
                                on:keypress={() => {
                                    showOtherOptsSelect = false;
                                    showRenamePositional = true;
                                }}>
                            <i class="bi bi-pencil-square"></i>
                            Rename Positional
                        </div>
                        <div class="optsOpt"
                                on:click={() => {
                                    showOtherOptsSelect = false;
                                    showDeletePositional = true;
                                }}
                                on:keypress={() => {
                                    showOtherOptsSelect = false;
                                    showDeletePositional = true;
                                }}>
                            <i class="bi bi-trash"></i>
                            Delete Positional
                        </div>
                    {/if}
                    <div class="optsOpt"
                            on:click={() => {
                                showOtherOptsSelect = false;
                                showRenameCollection = true;
                            }}
                            on:keypress={() => {
                                showOtherOptsSelect = false;
                                showRenameCollection = true;
                            }}>
                        <i class="bi bi-pencil-square"></i>
                        Rename Collection
                    </div>
                    <div class="optsOpt"
                            on:click={() => {
                                showOtherOptsSelect = false;
                                showDeleteCollection = true;
                            }}
                            on:keypress={() => {
                                showOtherOptsSelect = false;
                                showDeleteCollection = true;
                            }}>
                        <i class="bi bi-trash"></i>
                        Delete Collection
                    </div>

                </div>
            {/if}
        </div>

    </div>
</div>

{#if showCreatePositional}
    <CreatePositional 
        bind:showCreatePositional={showCreatePositional} 
        collection={collection}
        changeViewMode={changeViewMode}
        loadPositionals={loadPositionals}
    />
{:else if showDeleteCollection}
    <DeleteDialog
        bind:showDialog={showDeleteCollection}
        changeOption={ChangeOption.Collection}
        changeObject={{ collection: collection, viewMode: viewMode }}
        changeViewMode={changeViewMode}
        loadPositionals={loadPositionals}
    />
{:else if showDeletePositional}
    <DeleteDialog
        bind:showDialog={showDeletePositional}
        changeOption={ChangeOption.Positional}
        changeObject={{ collection: collection, viewMode: viewMode }}
        changeViewMode={changeViewMode}
        loadPositionals={loadPositionals}
    />
{:else if showRenameCollection}
    <RenameDialog 
        bind:showDialog={showRenameCollection}
        changeOption={ChangeOption.Collection}
        changeObject={{ collection: collection, viewMode: viewMode }}
        changeViewMode={changeViewMode}
    />
{:else if showRenamePositional}
    <RenameDialog 
        bind:showDialog={showRenamePositional}
        changeOption={ChangeOption.Positional}
        changeObject={{ collection: collection, viewMode: viewMode }}
        changeViewMode={changeViewMode}
    />
{/if}

<style>
    .outer {
        width: 100%;
        border-bottom: 1px solid var(--hoverBtnColor);
    }

    .toolBar {
        margin: 0 auto;
        max-width: var(--usableWidth);
        padding: 0.35rem 1.0rem;
        display: flex;
        align-items: center;
    }

    .selectHolder {
        display: block;
    }

    .selTB {
        padding: 0.25rem 0.4rem;
        width: 160px;
    }

    .selTB:hover {
        border: 1px solid;
    }

    .smTB {
        width: 160px;
    }

    .name {
        margin: 0 auto;
        font-size: 0.8rem;
    }

    .ico {
        font-size: 1.0rem;
    }

    .sIco {
        font-size: 0.8rem;
    }

    .tIco {
        font-size: 0.7rem;
    }

    .mL {
        margin-left: 0.5rem;
    }

    .mLA {
        margin-left: auto;
    }

    .selTBVM {
        padding: 0.25rem 0.4rem;
        width: 160px;
        color: #B19CD8;
    }

    .selTBVM:hover {
        border: 1px solid;
    }

    .selTBVMsm {
        width: 160px;
    }

    .cat {
        display: flex;
        align-items: center;
        padding: 0.5rem;
        margin: 1px;
        border-bottom: 1px solid var(--titlebarColor);
        cursor: auto;
    }

    .catName {
        margin-left: 0.7rem;
        font-weight: 600;
        font-size: 0.8rem;
    }
    
    .itm {
        padding: 0.4rem;
    }

    .catItmName {
        margin-right: 0.6rem;
    }

    .rightIco {
        font-size: 1.0rem;
    }

    .selTheme {
        padding: 0.25rem 0.4rem;
        width: 190px;
        color: #d7b474;
    }

    .themeMenu {
        width: 190px;
    }

    .themeOpt {
        font-size: 0.8rem;
    }

    .selTheme:hover {
        border: 1px solid;
    }

    .otherOpts {
        color: var(--fontColor);
        border-radius: 50%;
        cursor: pointer;
	    user-select: none;
        padding: 0.25rem;
    }

    .otherOpts:hover {
        background-color: var(--textfieldColor);
    }

    .optMenu {
        position: absolute;
        z-index: 3;
        right: 0;
        color: var(--fontColor);
        border: 1px solid;
        background-color: var(--textfieldColor);
        cursor: pointer;
        user-select: none;
        width: 200px;
    }

    .optsSelected {
        background-color: var(--textfieldColor);
    }

    .mla {
        margin-left: auto;
    }

    .mra {
        margin-right: auto;
    }

    .catCo {
        color: #B19CD8;
    }

    .append {
        color: #34be7b;
    }

    .editing {
        color: #34be7b;
    }

    .readOnly {
        color: #df7e79;
    }

    .themeCo {
        color: #d7b474;
    }
</style>
