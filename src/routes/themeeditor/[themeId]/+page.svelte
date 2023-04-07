<script lang="ts">
    import { GetThemeList, DefaultThemeList, SetThemeList } from "$lib/scripts/settings";
    import { WindowTitle } from "$lib/scripts/stores";
    import { ClickOutside } from "$lib/scripts/utils";
    import ThemeIndentSettings from "$lib/NoteThemeEdit.svelte";

    export let data;

    let showThemeSelect: boolean = false;
    let showCreateArea: boolean = false;
    let createCopy: boolean = false;
    let showMaxIndentSelect: boolean = false;

    let themeNameInput: HTMLElement;
    let newThemeName: string = "";

    let newThemeErrorStr: string = "";
    let nameChangeErrorStr: string = "";

    let currentlyEditing: Theme;
    let themes: Theme[];

    const ThemesReservedIdMax: number = 20;
    const DefaultMaxIndents: number = 6;
    const MaxMaxIndents: number = 16;
    const ThemeNameMaxLength: number = 42;

    loadData();
    WindowTitle.set("Theme Editor");

    $: if (themeNameInput && (showCreateArea || createCopy)) themeNameInput.focus();

    async function loadData() {
        themes = await GetThemeList();
        currentlyEditing = getThemeIdxFromId(data.id);
    }

    function getThemeIdxFromId(themeId: number): Theme {
        for (let theme of themes) {
            if (theme.id === themeId) {
                return theme;
            }
        }
        return themes[0];
    }

    function createNewTheme() {
        newThemeErrorStr = checkThemeName(newThemeName);
        if (newThemeErrorStr.length !== 0) return;

        let newTheme: Theme;
        
        if (createCopy) {
            newTheme = JSON.parse(JSON.stringify(currentlyEditing));
            newTheme.id = getNextValidUserThemeId();
            newTheme.name = newThemeName;
            newTheme.system = false;
        } else {
            newTheme = {
                id: getNextValidUserThemeId(),
                name: newThemeName,
                system: false,
                maxIndents: DefaultMaxIndents
            };
        }
        themes.push(newTheme);
        SetThemeList(themes);
        currentlyEditing = newTheme;
        newThemeName = "";
        showCreateArea = createCopy = false;
    }

    function getNextValidUserThemeId() {
        let max = ThemesReservedIdMax;

        for (let theme of themes) {
            if (theme.id > max) {
                max = theme.id;
            }
        }
        return ++max;
    }

    function getThemeIdx(id: number, list: Theme[]) {
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === id) {
                return i;
            }
        }
    }

    function restoreThemeDefault() {
        if (!currentlyEditing.system) return;
        for (let theme of DefaultThemeList) {
            if (theme.id === currentlyEditing.id) {
                currentlyEditing = theme;
                let idx = getThemeIdx(theme.id, themes);
                if (!idx) return;
                themes[idx] = theme;
                SetThemeList(themes);
                return;
            }
        }
    }

    function checkThemeName(name: string) {
        if (name.length === 0) {
            return "Name cannot be empty.";
        } else if (name.length > ThemeNameMaxLength) {
            return "Name cannot exceed " + ThemeNameMaxLength + " characters.";
        }
        return "";
    }

    function changeThemeName(event: KeyboardEvent): void {
        nameChangeErrorStr = checkThemeName(currentlyEditing.name);
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                return;
        }
    }

    function createThemeName(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                createNewTheme();
                return;
            case "Escape":
                event.preventDefault();
                showCreateArea = createCopy = false;
                return;
        }
    }

    function save() {
        console.log(themes)
        SetThemeList(themes);
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
            <div class="btn copyCo mR" class:btnSelected={createCopy}
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
                    if (showCreateArea && createCopy) {
                        showCreateArea = false;
                        createCopy = false;
                    } else {
                        showCreateArea = true;
                        createCopy = true;
                    }
                }}>
                <i class="bi bi-clipboard sIco mR"></i>Copy "{currentlyEditing.name}"</div>
        </div>
        {#if showCreateArea}
            <div class="createArea" style="border-color: {createCopy ? "#d7b474" : "#34be7b"};">
                <div class="row">
                    {#if createCopy}
                        <h3>Create copy of "{currentlyEditing.name}"...</h3>
                    {:else}
                        <h3>Create new theme...</h3>
                    {/if}
                </div>
                <div class="row">
                    <textarea class="txtInput"
                        on:keydown={createThemeName}
                        bind:this={themeNameInput}
                        bind:value={newThemeName}
                        placeholder="New theme name"
                    />
                    <div class="submitBtn {createCopy ? "copyCo" : "createCo"}"
                            on:click={() => createNewTheme()}
                            on:keypress={() => createNewTheme()}>
                        {#if createCopy}
                            <i class="bi bi-clipboard"></i>
                        {:else}
                            <i class="bi bi-plus-lg"></i>
                        {/if}
                    </div>
                </div>
                <div class="errorMsg">{newThemeErrorStr}</div>
            </div>
        {/if}

        <h3>Theme being edited:</h3>
        <div class="row">
            <div class="selectHolder">
                <div class="selector selTheme" class:selectorSelected={showThemeSelect}
                        on:click={() => showThemeSelect = true}
                        on:keypress={() => showThemeSelect = !showThemeSelect}>
                    <div class="selected">{currentlyEditing.name}</div>
                    <i class="bi bi-chevron-down rI"></i>
                </div>
                {#if showThemeSelect}
                    <div class="selectorMenu themeMenu"
                            use:ClickOutside 
                            on:outclick={() => {
                                    showThemeSelect = false;
                                }}>
                        {#each themes as theme}
                            <div class="opt themeOpt"
                                    on:click={() => {
                                        currentlyEditing = theme;
                                        showThemeSelect = !showThemeSelect;
                                    }}
                                    on:keypress={() => {
                                        currentlyEditing = theme;
                                        showThemeSelect = !showThemeSelect;
                                    }}>
                                {theme.name}
                                {#if theme.system}
                                    <i class="bi bi-gear mL"></i>
                                {:else}
                                    <i class="bi bi-person mL"></i>
                                {/if}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>
            {#if currentlyEditing.system}
                <div class="restoreDefaultBtn" title="Restore Theme Defaults"
                        on:click={() => restoreThemeDefault()}
                        on:keypress={() => restoreThemeDefault()}>
                    <i class="bi bi-gear mL"></i>
                </div>
            {/if}
        </div>

        <h3>Change Name:</h3>
        <textarea class="txtInput"
            bind:value={currentlyEditing.name}
        />
        <div class="errorMsg">{nameChangeErrorStr}</div>

        <h3>Max Indents:</h3>
        <div class="selectHolder">
            <div class="selector selIndents" class:selectorSelected={showMaxIndentSelect}
                    on:click={() => showMaxIndentSelect = true}
                    on:keypress={() => showMaxIndentSelect = !showMaxIndentSelect}>
                <div class="selected">{currentlyEditing.maxIndents}</div>
                <i class="bi bi-chevron-down rI"></i>
            </div>
            {#if showMaxIndentSelect}
                <div class="selectorMenu indentsMenu"
                        use:ClickOutside 
                        on:outclick={() => {
                                showMaxIndentSelect = false;
                            }}>
                    {#each {length: MaxMaxIndents+1} as _, i}
                        <div class="opt indentOpt"
                                on:click={() => {
                                    currentlyEditing.maxIndents = i;
                                    showMaxIndentSelect = !showMaxIndentSelect;
                                }}
                                on:keypress={() => {
                                    currentlyEditing.maxIndents = i;
                                    showMaxIndentSelect = !showMaxIndentSelect;
                                }}>
                            {i}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>

        <ThemeIndentSettings 
            indentLevel={-1}
            bind:themePapa={currentlyEditing}
            save={save}
        />











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
        font-size: 1.0rem;
        margin: 1.0rem 0;
        font-weight: 400;
    }

    .createArea {
        margin: 1.0rem 0 1.0rem 1.0rem;
        border-left: 1px dashed;
        padding-left: 1.5rem;
    }

    .txtInput {
        border: none;
        border-radius: 4px;
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
        background-color: var(--textfieldColor);
        color: var(--fontColor);
        resize: none;
        line-height: 1.6rem;
        height: 2.25rem;
        width: 220px;
        font-family: inherit;
        font-size: inherit;
        white-space: nowrap;
        overflow-x: hidden;
    }

    .selTheme {
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
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

    .selIndents{
        width: 64px;
        padding: 0.3rem 0.5rem 0.35rem 0.5rem;
    }

    .indentsMenu {
        width: 64px;
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
    }

    .restoreDefaultBtn {
        font-size: 1.2rem;
        margin-left: 1.0rem;
        cursor: pointer;
	    user-select: none;
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

    .mL {
        margin-left: auto;
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
        font-size: 0.9rem;
    }
    
    .btn:hover {
        border: 1px solid;
    }

    .btnSelected {
        border: 1px solid;
    }

    .createCo {
        color: #34be7b;
    }

    .copyCo {
        color: #d7b474;
    }

    .row {
        display: flex;
        align-items: center;
    }

    .submitBtn {
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 4px;
        cursor: pointer;
	    user-select: none;
        height: 2.25rem;
        width: 2.25rem;
        margin-left: 0.5rem;
    }

    .errorMsg {
        margin: 1.0rem 0;
        font-size: 0.9rem;
        color: #BE3455;
    }
</style>