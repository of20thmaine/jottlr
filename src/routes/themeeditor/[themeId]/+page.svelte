<script lang="ts">
    import { GetThemeList, DefaultThemeList, SetThemeList } from "$lib/scripts/settings";
    import { WindowTitle } from "$lib/scripts/stores";
    import { ClickOutside } from "$lib/scripts/utils";
    import ThemeIndentSettings from "$lib/NoteThemeEdit.svelte";
    import NoteView from "$lib/NoteView.svelte";

    export let data;

    const ThemesReservedIdMax: number = 20;
    const DefaultMaxIndents: number = 6;
    const MaxMaxIndents: number = 16;
    const ThemeNameMaxLength: number = 30;
    const MockNote: string = "Test";

    let currentlyEditing: Theme;
    let themes: Theme[];
    let mockNotes: Note[];

    let showCreateArea: boolean = false;
    let createCopy: boolean = false;
    let showThemeSelect: boolean = false;
    let showMaxIndentSelect: boolean = false;
    let showIndentThemeSelect: boolean = false;
    let indentThemeSelection: number = -1;
    let themeNameInput: HTMLElement;
    let createNameStr: string = "";
    let changeNameStr: string = "";
    let createNameErrorStr: string = "";
    let changeNameErrorStr: string = "";

    loadData();
    WindowTitle.set("Theme Editor");

    $: if (themeNameInput && (showCreateArea || createCopy)) themeNameInput.focus();
    $: if (currentlyEditing) {
        currentlyEditing = currentlyEditing;
        generateMockNotes();
        mockNotes = mockNotes;
    }

    async function loadData() {
        return await GetThemeList()
            .then((value) => {
                themes = value;
                currentlyEditing = getThemeFromId(data.id);
                changeNameStr = currentlyEditing.name;
            });
    }

    function save() {
        SetThemeList(themes)
        generateMockNotes();
        mockNotes = mockNotes;
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
                let idx = getThemeIdx(theme.id, themes);
                if (idx === undefined) return;
                themes[idx] = JSON.parse(JSON.stringify(theme));
                save();
                currentlyEditing = themes[idx];
                changeNameStr = currentlyEditing.name;
                return;
            }
        }
    }

    function getThemeFromId(themeId: number): Theme {
        for (let theme of themes) {
            if (theme.id === themeId) {
                return theme;
            }
        }
        return themes[0];
    }

    function createNewTheme() {
        createNameErrorStr = checkThemeName(createNameStr);
        if (createNameErrorStr.length !== 0) return;

        let newTheme: Theme;
        
        if (createCopy) {
            newTheme = JSON.parse(JSON.stringify(currentlyEditing));
            newTheme.id = getNextValidUserThemeId();
            newTheme.name = createNameStr;
            newTheme.system = false;
        } else {
            newTheme = {
                id: getNextValidUserThemeId(),
                name: createNameStr,
                system: false,
                maxIndents: DefaultMaxIndents
            };
        }
        themes.push(newTheme);
        save();
        currentlyEditing = newTheme;
        createNameStr = "";
        showCreateArea = createCopy = false;
    }

    function changeThemeName() {
        changeNameErrorStr = checkThemeName(changeNameStr);
        if (changeNameErrorStr.length !== 0) return;

        currentlyEditing.name = changeNameStr;
        save();
    }

    function checkThemeName(name: string) {
        if (name.length === 0) {
            return "Name cannot be empty.";
        } else if (name.length > ThemeNameMaxLength) {
            return "Name cannot exceed " + ThemeNameMaxLength + " characters.";
        }
        return "";
    }

    function createNameKeyHandler(event: KeyboardEvent): void {
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

    function changeNameKeyHandler(event: KeyboardEvent): void {
        changeNameErrorStr = checkThemeName(changeNameStr);
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                changeThemeName();
                return;
        }
    }

    function generateMockNotes() {
        mockNotes = [];
        for (let i = 0; i < currentlyEditing.maxIndents; ++i) {
            mockNotes.push(
                {
                    id: i,
                    content: MockNote,
                    created_at: "",
                    updated_at: "",
                    position: i,
                    indents: i,
                    isPositioned: true,
                    label: 1
                }
            );
        }
    }

    function getNoteHolderStyle(note: Note): string {
        if (!note.isPositioned) return "";
        let marginLeft = 0;

        if (typeof currentlyEditing.noteThemes?.[note.indents]?.marginLeft === 'number') {
            marginLeft = currentlyEditing.noteThemes[note.indents].marginLeft!;
        } else if (typeof currentlyEditing.default?.marginLeft === 'number') {
            marginLeft = currentlyEditing.default.marginLeft * note.indents;
        }
        return "margin-left:" + marginLeft + "px;";
    }
</script>

<div class="scroller">
    <div class="page">
    {#if currentlyEditing}
        <h1>Theme Editor</h1>

        <h3 class="emph">Theme being edited:</h3>
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
                                        changeNameStr = currentlyEditing.name
                                        showThemeSelect = !showThemeSelect;
                                    }}
                                    on:keypress={() => {
                                        currentlyEditing = theme;
                                        changeNameStr = currentlyEditing.name
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
                        <h4>Create copy of "{currentlyEditing.name}"...</h4>
                    {:else}
                        <h4>Create new theme...</h4>
                    {/if}
                    <div class="closeBtn" title="{createCopy ? "Close Theme Copy Creator" : "Close Theme Creator"}"
                            on:click={() => showCreateArea = createCopy = false}
                            on:keypress={() => showCreateArea = createCopy = false}>
                        <i class="bi bi-x-lg"></i>
                    </div>
                </div>
                <div class="row">
                    <textarea class="txtInput"
                        on:keydown={createNameKeyHandler}
                        bind:this={themeNameInput}
                        bind:value={createNameStr}
                        placeholder="New theme name"
                    />
                    <div class="submitBtn {createCopy ? "copyCo" : "createCo"}"
                            title="{createCopy ? "Create Theme Copy" : "Create New Theme"}"
                            on:click={() => createNewTheme()}
                            on:keypress={() => createNewTheme()}>
                        {#if createCopy}
                            <i class="bi bi-clipboard"></i>
                        {:else}
                            <i class="bi bi-plus-lg"></i>
                        {/if}
                    </div>
                </div>
                <div class="errorMsg">{createNameErrorStr}</div>
            </div>
        {/if}

        <h3>Change Name:</h3>
        <div class="row">
            <div class="rowIco"><i class="bi bi-type"></i></div>
            <textarea class="txtInput"
                on:keydown={changeNameKeyHandler}
                on:focusout={changeThemeName}
                bind:value={changeNameStr}
            />
        </div>
        <div class="errorMsg">{changeNameErrorStr}</div>

        <h3>Max Indents:</h3>
        <div class="row">
            <div class="rowIco"><i class="bi bi-list-nested"></i></div>
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
        </div>

        <div class="row barrier">
            <h2>Indent Level Settings:</h2>
            <div class="selectHolder">
                <div class="selector selIndents" class:selectorSelected={showIndentThemeSelect}
                        on:click={() => showIndentThemeSelect = true}
                        on:keypress={() => showIndentThemeSelect = !showIndentThemeSelect}>
                    <div class="selected">{indentThemeSelection === -1 ? "*" : indentThemeSelection}</div>
                    <i class="bi bi-chevron-down rI"></i>
                </div>
                {#if showIndentThemeSelect}
                    <div class="selectorMenu indentsMenu"
                            use:ClickOutside 
                            on:outclick={() => {
                                    showIndentThemeSelect = false;
                                }}>
                        <div class="opt indentOpt"
                                on:click={() => {
                                    indentThemeSelection = -1;
                                    showIndentThemeSelect = !showIndentThemeSelect;
                                }}
                                on:keypress={() => {
                                    indentThemeSelection = -1;
                                    showIndentThemeSelect = !showIndentThemeSelect;
                                }}>
                            *
                        </div>
                        {#each {length: currentlyEditing.maxIndents+1} as _, i}
                            <div class="opt indentOpt"
                                    on:click={() => {
                                        indentThemeSelection = i;
                                        showIndentThemeSelect = !showIndentThemeSelect;
                                    }}
                                    on:keypress={() => {
                                        indentThemeSelection = i;
                                        showIndentThemeSelect = !showIndentThemeSelect;
                                    }}>
                                {i}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>
            <div class="rowEndIco"
                    title="Select settings which apply to a specific indent level. * settings apply to the entire theme at all indent levels, unless specifically overriden by a setting at the indent level.">
                <i class="bi bi-info-circle"></i>
            </div>
        </div>
        <ThemeIndentSettings 
            bind:indentLevel={indentThemeSelection}
            bind:themePapa={currentlyEditing}
            save={save}
        />

        {#if mockNotes}
            <div class="row barrier">
                <div class="rowIco"><i class="bi bi-easel"></i></div>
                <h2>See It:</h2>
            </div>
            <div class="collectionMock">
                {#each mockNotes as note, i}
                    <div class="noteHolder" style="{getNoteHolderStyle(note)}">
                        <NoteView 
                            idx={i}
                            bind:note={note}
                            collectionView={{id: 1, name: "", editModeId: 3, viewCategoryId: 3, viewModeId: 3, themeId: currentlyEditing.id}}
                            focusNoteId={null}
                            viewMode={{id: 1, name: "", created_at: "", last_open: "", isSortable: false}}
                            theme={currentlyEditing}
                            forceFocusChange={() => {}}
                            moveNote={() => {}}
                            deleteSavedNote={async () => {}}
                            deleteUnsavedNote={async () => {}}
                        />
                    </div>
                {/each}
            </div>
        {/if}
    {/if}
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

    h2 {
        font-size: 1.2rem;
        margin: 1.0rem 0;
        margin-right: 1.0rem;
        font-weight: 400;
        padding: 0.5rem 0;
    }

    h3 {
        font-size: 1.0rem;
        margin: 1.0rem 0;
        font-weight: 400;
    }

    h4 {
        font-size: 1.0rem;
        margin-bottom: 1.0rem;
        font-weight: 400;
    }

    .emph {
        font-weight: 500;
    }

    .createArea {
        margin: 1.0rem 0 1.0rem 1.0rem;
        border-left: 1px dashed;
        padding: 0.5rem 0 0.3rem 1.5rem;
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

    .closeBtn {
        cursor: pointer;
	    user-select: none;
        font-size: 0.75rem;
        padding: 0.15rem;
        align-self: start;
        justify-self: end;
        margin-left: 2.0rem;
    }

    .closeBtn:hover {
        color: #BE3455;
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

    .rowIco {
        margin-right: 1.0rem;
    }

    .rowEndIco {
        margin-left: 1.0rem;
    }
    
    .barrier {
        border-top: 1px dashed var(--fontColor);
        margin-top: 2.0rem;
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

    .collectionMock {
        width: 100%;
    }

    .noteHolder {
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
    }
</style>