<script lang="ts">
    import { open } from '@tauri-apps/api/dialog';
    import { readTextFile } from '@tauri-apps/api/fs';
    import { ClickOutside } from "$lib/scripts/utils";
    import { GetThemeList, SetThemeList } from '$lib/scripts/settings';
    import { GetCollectionList, ImportCollectionFromJottlr } from '$lib/scripts/db';

    export let showDialog: boolean;

    let data: JottlrSave | null;
    let collections: Collection[];
    let collectionName: string;
    let collectionNameInput: HTMLElement;
    let fileName: string = ""
    let errorStr: string = "";
    let includeTheme: boolean = false;

    let themeName: string = "";
    let themeErrorStr: string = ""

    $: if (collectionName !== undefined) checkCollectionName();
    $: if (collectionNameInput) collectionNameInput.focus();

    async function getData() {
        const selected = await open({
            title: "Import",
            multiple: false,
            filters: [{ name: "Jottlr", extensions: ["jottlr"] }]
        });

        if (!selected || Array.isArray(selected)) return;

        let path = selected.split('\\');
        fileName = path[path.length-1];

        collections= await GetCollectionList();
        data = JSON.parse(await readTextFile(selected));

        if (!data) return;
        collectionName = data.collection.name;

        if (data.theme) {
            themeName = data.theme.name;
        }
    }

    function checkCollectionName() {
        if (collectionNameUsed()) {
            errorStr = "A collection with this name already exists."
        } else if (collectionName.length === 0) {
            errorStr = "Collection cannot be imported without a name."
        } else if (collectionName.length > 36) {
            errorStr = "Collection name cannot exceed 36 characters.";
        } else {
            errorStr = "";
        }
    }

    function collectionNameUsed() {
        for (let collection of collections) {
            if (collectionName === collection.name) {
                return true;
            }
        }
        return false;
    }

    function reset() {
        fileName = "";
        errorStr = "";
        data = null;
    }

    function importHandler() {

    }
</script>

<div class="promptBox" 
        use:ClickOutside 
        on:outclick={() => showDialog = !showDialog}>
    <div class="closePromptBox closeBtn"
            on:click={() => showDialog = !showDialog}
            on:keypress={() => showDialog = !showDialog}>
        <i class="bi bi-x"></i></div>
    <h1>Import</h1>

    <div class="row mT">
        {#if fileName.length > 0}
            <div class="ico"><i class="bi bi-arrow-return-right"></i></div>
            <div class="fileName">{fileName}</div>
            <div class="closeBtn"
                    on:click={reset}
                    on:keypress={reset}>
                <i class="bi bi-x"></i>
            </div>
        {:else}
            <div class="fileSelectBtn" class:btnSelected={data}
                    on:click={getData}
                    on:keypress={getData}>
                Choose File
            </div>
        {/if}
    </div>

    {#if data}
        <input type="text" class="txtInput" bind:this={collectionNameInput} bind:value={collectionName} />
        <div class="errorStr">{errorStr}</div>

        {#if data.theme}
            <h4 class="mT">File includes theme "{data.theme.name}"...</h4>
            <div class="row mT">
                <input type="checkbox" class="includeTheme" bind:value={includeTheme}>
                <h3>Import Theme?</h3>
            </div>
            {#if includeTheme}
                <input type="text" class="txtInput" bind:value={themeName} />
                <div class="errorStr">{themeErrorStr}</div>
            {/if}
        {/if}

        <div class="importBtn"
                on:click={importHandler}
                on:keypress={importHandler}>
            Import
        </div>

    {/if}
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
        width: 260px;
        padding: 1.0rem 1.5rem;
        color: var(--fontColor);
    }

    .closePromptBox {
        position: fixed;
        top: 0.5rem;
        right: 0.5rem;
        font-size: 1.25rem;
    }

    .closeBtn {
        cursor: pointer;
    }

    .closeBtn:hover {
        color: red;
    }

    h1 {
        font-weight: 600;
        font-size: 1.05rem;
    }

    h3 {
        font-weight: 400;
        font-size: 1.0rem;
    }

    h4 {
        font-weight: 300;
        font-size: 1.0rem;
    }

    .mT {
        margin-top: 0.75rem;
    }

    .includeTheme {
        margin: 0 0.75rem;
    }

    .fileSelectBtn {
        border: 1px dashed;
        border-radius: 4px;
        color: #be349c;
        padding: 0.2rem 1.5rem 0.25rem 1.5rem;
        width: fit-content;
        font-weight: 400;
        cursor: pointer;
	    user-select: none;
    }

    .fileSelectBtn:hover {
        border: 1px solid;
    }

    .btnSelected {
        border: 1px solid;
    }

    .fileName {
        margin: 0 0.5rem;
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
        max-width: 240px;
        font-family: inherit;
        font-size: inherit;
        white-space: nowrap;
        overflow-x: hidden;
        margin: 0.75rem 0;
    }

    .errorStr {
        font-size: 0.9rem;
        color: #BE3455;
    }

    .row {
        display: flex;
        align-items: center;
    }

    .importBtn {
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
