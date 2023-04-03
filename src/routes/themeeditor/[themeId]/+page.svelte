<script lang="ts">
    import { GetThemeList, DefaultThemeList, SetThemeList } from "$lib/scripts/settings";
    import { WindowTitle } from "$lib/scripts/stores";
    import { ClickOutside } from "$lib/scripts/utils";
    import ColorSelector from "$lib/ColorSelector.svelte";

    export let data;

    let showThemeSelect: boolean = false;
    let showEditArea: boolean = true;
    let showCreateArea: boolean = false;
    let createCopy: boolean = false;

    let themeNameInput: HTMLElement;
    let newThemeName: string = "";
    let errorStr: string = "";

    let currentlyEditing: Theme;
    let userThemes: Theme[] | null;
    let maxDefaults: number = 20;
    let defaultMaxIndents = 6;

    WindowTitle.set("Theme Editor");
    loadData();
    $: if (themeNameInput) themeNameInput.focus();

    async function loadData() {
        userThemes = await GetThemeList();
        currentlyEditing = getThemeIdxFromId(data.id);
    }

    function getThemeIdxFromId(themeId: number): Theme {
        if (userThemes && themeId >= maxDefaults) {
            for (let theme of userThemes) {
                if (theme.id === themeId) {
                    return theme;
                }
            }
        } else {
            for (let theme of DefaultThemeList) {
                if (theme.id === themeId) {
                    return theme;
                }
            }
        }
        return DefaultThemeList[0];
    }

    function createNewTheme() {
        if (!themeNameIsValid()) {
            return;
        }
    }

    function themeNameIsValid() {
        if (newThemeName.length === 0) {
            errorStr = "Name cannot be empty.";
            return false;
        } else if (newThemeName.length > 42) {
            errorStr = "Name cannot exceed 42 characters.";
            return false;
        }
        return true;
    }

    function keyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                createNewTheme();
                return;
        }
        if (errorStr.length > 0) errorStr = "";
    }
</script>

<div class="scroller">
    <div class="page">
    {#if currentlyEditing}
        <h1>Theme Editor</h1>

        <div class="createBar">
            <div class="btn createCo mR" class:btnSelected={showCreateArea && !createCopy}
                on:click={() => {
                    if (createCopy) {
                        createCopy = false;
                    } else {
                        showCreateArea = !showCreateArea;
                    }
                }}
                on:keypress={() => {
                    if (createCopy) {
                        createCopy = false;
                    } else {
                        showCreateArea = !showCreateArea;
                    }
                }}>
                <i class="bi bi-plus-lg mR"></i>Create Theme</div>
            <div class="btn copyCo" class:btnSelected={createCopy}
                on:click={() => {
                    if (showCreateArea && createCopy) {
                        showCreateArea = false;
                        createCopy = false;
                    } else {
                        showCreateArea = true;
                        createCopy = true;
                    }
                }}
                on:keypress={() => {
                    createCopy = !createCopy;
                }}>
                <i class="bi bi-clipboard sIco mR"></i>Copy "{currentlyEditing.name}"</div>
        </div>
        {#if showCreateArea}
            <div class="createArea">
                {#if createCopy}
                    <h3>Create copy of "{currentlyEditing.name}"...</h3>
                {:else}
                    <h3>Create new theme...</h3>
                {/if}
                <div class="themeNameInput"
                    contenteditable="true"
                    on:keydown={keyHandler}
                    bind:this={themeNameInput}
                    bind:innerHTML={newThemeName}
                    placeholder="New theme name">
                </div>
                <div class="footer">
                    <div class="messages">
                        {#if errorStr.length > 0}
                            <div class="errorString">{errorStr}</div>
                        {/if}
                    </div>
                    <div class="submitBtn" class:disabled={!(newThemeName.length > 0 && newThemeName.length < 42)}
                            on:click={() => createNewTheme()}
                            on:keypress={() => createNewTheme()}>
                        <i class="bi bi-plus"></i> Create
                    </div>
                </div>


            </div>
        {/if}
        


        <h3>Theme being edited:</h3>
        <div class="selectHolder">
            <div class="selector selTheme" class:selectorSelected={showThemeSelect}
                    on:click={() => showThemeSelect = !showThemeSelect}
                    on:keypress={() => showThemeSelect = !showThemeSelect}>
                <div class="selected">{currentlyEditing.name}</div>
                <i class="bi bi-chevron-down rI"></i>
            </div>
            {#if showThemeSelect}
                <div class="selectorMenu themeMenu"
                        use:ClickOutside 
                        on:outclick={() => showThemeSelect = !showThemeSelect}>
                    {#each DefaultThemeList as theme}
                        <div class="opt themeOpt">{theme.name}</div>
                    {/each}
                </div>
            {/if}
        </div>




        <!-- <h3>Page Colors:</h3>
        <ColorSelector
            color={""}
            prompt={""}
        /> -->
    {/if}
    </div>
</div>

<style>
    .page {
        margin-top: var(--titlebarHeight);
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
        margin: 0.5rem 0;
        font-weight: 400;
        font-size: 1.1rem;
    }

    .createArea {
        margin: 1.0rem 0;
    }

    .themeNameInput {
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem;
        color: var(--fontColor);
        margin: 1.0rem 0;
        line-height: 1.84rem;
        height: 2.84rem;
        font-size: 1.15rem;
        width: 400px;
        white-space: nowrap;
        overflow-x: hidden;
    }

    [contenteditable=true]:empty:before {
        content:attr(placeholder);
        color: grey;
        user-select: none;
        cursor: text;
    }

    .selTheme {
        padding: 0.5rem 1.0rem 0.5rem 0.5rem;
        width: 220px;
        color: var(--fontColor);
    }

    .selectorSelected {
        border: 1px solid var(--fontColor);
        color: var(--textfieldColor);
    }

    .themeMenu {
        width: 220px;
    }

    .rI {
        margin-left: auto;
    }

    .sIco {
        font-size: 0.8rem;
    }

    .mR {
        margin-right: 1.0rem;
    }

    .createBar {
        display: flex;
        align-items: center;
        margin: 1.0rem 0;
    }

    .btn {
        border: 1px dashed;
        border-radius: 4px;
        padding: 0.3rem 1.5rem 0.4rem 1.5rem;
        cursor: pointer;
	    user-select: none;
    }
    
    .btn:hover {
        border: 1px solid;
    }

    .btnSelected {
        border: 1px solid;
        background-color: var(--textfieldColor);
    }

    .createCo {
        color: #34be7b;
    }

    .copyCo {
        color: #d7b474;
    }

    .footer {
        display: grid;
        grid-template-columns: 1fr max-content;
        width: 400px;
    }

    .messages {
        font-size: 0.9rem;
    }

    .errorString {
        color: #BE3455;
    }

    .submitBtn {
        border: 1px solid #34be7b;
        border-radius: 4px;
        color: #34be7b;
        padding: 0.2rem 1.0rem 0.25rem 1.0rem;
        cursor: pointer;
	    user-select: none;
    }

    .disabled {
        border: 1px solid #34be7b6b;
        color: #34be7b6b;
        cursor: auto;
    }
</style>