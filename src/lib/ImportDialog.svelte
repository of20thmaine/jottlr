<script lang="ts">
    import { open } from '@tauri-apps/api/dialog';
    import { readTextFile } from '@tauri-apps/api/fs';
    import { ClickOutside } from "$lib/scripts/utils";
    import { GetCollectionList } from '$lib/scripts/db';

    export let showDialog: boolean;

    let data: JottlrSave;
    let collections: Collection[];
    let collectionName: string;
    let fileName: string = ""
    let errorStr: string = "";

    $: if (collectionName !== undefined) checkCollectionName();

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

        collectionName = data.collection.name;
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

</script>

<div class="promptBox" 
        use:ClickOutside 
        on:outclick={() => showDialog = !showDialog}>
    <div class="closeBtn"
            on:click={() => showDialog = !showDialog}
            on:keypress={() => showDialog = !showDialog}>
        <i class="bi bi-x"></i></div>

    <h1 class="mB">Import</h1>

    <div class="importBtn" class:btnSelected={data}
            on:click={getData}
            on:keypress={getData}>
        Choose File
    </div>
    {#if fileName.length > 0}
        <div class="row">
            <i class="bi bi-arrow-return-right"></i>
            <div class="fileName">{fileName}</div>
        </div>
    {/if}

    {#if data}
        <input type="text" class="txtInput" bind:value={collectionName} />
        <div class="errorStr">{errorStr}</div>
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
        width: 300px;
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

    .mB {
        margin-bottom: 1.0rem;
    }

    .importBtn {
        border: 1px dashed;
        border-radius: 4px;
        color: #be349c;
        padding: 0.2rem 1.5rem;
        width: fit-content;
        font-weight: 400;
        margin-top: 1.0rem;
        cursor: pointer;
	    user-select: none;
    }

    .importBtn:hover {
        border: 1px solid;
    }

    .btnSelected {
        border: 1px solid;
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
        margin: 1.0rem 0;
    }

    .errorStr {
        font-size: 0.9rem;
        color: #BE3455;
    }

    .row {
        margin-top: 0.5rem;
        display: flex;
        align-items: center;
        color: var(--fontColor);
    }

    .fileName {
        margin-left: 0.5rem;
    }
</style>
