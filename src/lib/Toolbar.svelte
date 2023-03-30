<script lang="ts">
    import { EditModes } from "$lib/scripts/settings";
    import { ClickOutside } from "$lib/scripts/utils";
    import CreatePositional from "$lib/CreatePositional.svelte";

    export let editMode: EditMode;
    export let viewMode: ViewMode;
    export let viewModes: ViewModeCategory[];
    export let collection: Collection;
    export let changeEditMode: (modeSelection: number) => void;
    export let changeViewMode: (categoryId: number, optionId: number) => void;
    export let loadPositionals: () => void;

    let showEditModeSelect: boolean = false;
    let showViewModeSelect: boolean = false;
    let showThemeSelect: boolean = false;
    let showCreatePositional: boolean = false;

    function toggleShowEditMode() {
        showEditModeSelect = !showEditModeSelect;
    }

    function toggleShowViewMode() {
        showViewModeSelect = !showViewModeSelect;
    }
</script>

<div class="outer">
    <div class="toolBar">
        <div class="selectHolder">
            <div class="selector selTB {editMode.class}" class:selectorSelected={showEditModeSelect}
                    on:click={() => toggleShowEditMode()}
                    on:keypress={() => toggleShowEditMode()}>
                <div class="ico {editMode.class}"><i class="{editMode.ico}"></i></div>
                <div class="name {editMode.class}">{editMode.name}</div>
                <div class="tIco"><i class="bi bi-chevron-down"></i></div>
            </div>
            {#if showEditModeSelect}
                <div class="selectorMenu smTB"
                        use:ClickOutside 
                        on:outclick={() => toggleShowEditMode()}>
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
                    on:click={() => toggleShowViewMode()}
                    on:keypress={() => toggleShowViewMode()}>
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
                        on:outclick={() => toggleShowViewMode()}>
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
<!-- 
        <div class="filterBtn"><i class="bi bi-filter-circle"></i></div> 
-->
    </div>
</div>

{#if showCreatePositional}
    <CreatePositional 
        bind:showCreatePositional={showCreatePositional} 
        collection={collection}
        changeViewMode={changeViewMode}
        loadPositionals={loadPositionals} />
{/if}

<style>
    .outer {
        width: 100%;
        border-bottom: 1px solid var(--hoverBtnColor);
    }

    .toolBar {
        margin: 0 auto;
        max-width: var(--usableWidth);
        padding: 0.3rem;
        display: flex;
        align-items: center;
    }

    .selectHolder {
        display: block;
    }

    .selTB {
        padding: 0.25rem 0.4rem;
        width: 130px;
    }

    .selTB:hover {
        border: 1px solid;
    }

    .smTB {
        width: 130px;
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

    .selTBVM {
        padding: 0.25rem 0.4rem;
        width: 160px;
        color: #B19CD8;
    }

    .selTBVM:hover {
        border: 1px solid
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

    .catCo {
        color: #B19CD8;
    }

    .filterBtn {
        color: var(--fontColor);
        font-size: 1.0rem;
        margin: 0 1.0rem;
    }

    .append {
        /* color: #3cb452; */
        color: #34be7b;
    }

    .editing {
        /* color: #F5DF4D; */
        color: #f5e28e;
    }

    .readOnly {
        /* color: #BE3455; */
        color: #df7e79;
    }
</style>
