<script lang="ts">
    import { GetCollectionList, CreateCollection } from "$lib/scripts/db";
    import { ClickOutside } from "$lib/scripts/utils";

    export let showDialog: boolean;

    const NameMaxLength: number = 30;
    let name: string = "";
    let nameInput: HTMLElement;
    let errorStr: string = "";
    let existing: Collection[];

    load();

    $: if (nameInput) nameInput.focus();

    async function load() {
        existing = await GetCollectionList();
    }

    async function create() {
        checkCollectionName();
        if (errorStr.length > 0) return;
        CreateCollection(name);
        showDialog = false;
    }

    function keyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                create();
                return;
            case "Escape":
                showDialog = false;
                return;
        }
    }

    function checkCollectionName() {
        if (nameUsed()) {
            errorStr = "A collection with this name already exists."
        } else if (name.length === 0) {
            errorStr = "Collection requires a name."
        } else if (name.length > NameMaxLength) {
            errorStr = "Collection name cannot exceed " + NameMaxLength + " characters.";
        } else {
            errorStr = "";
        }
    }

    function nameUsed() {
        for (const collection of existing) {
            if (collection.name === name) {
                return true;
            }
        }
        return false;
    }
</script>

<div class="dialog"
        use:ClickOutside 
        on:outclick={() => showDialog = false}>
    <div class="closeBtn"
            on:click={() => showDialog = false}
            on:keypress={() => showDialog = false}>
        <i class="bi bi-x"></i>
    </div>
    <div class="title">
        Create Collection:
    </div>
    {#if existing}
        <input type="text" class="txtInput" bind:this={nameInput} on:keydown={keyHandler}
            bind:value={name} on:keyup={checkCollectionName} />
        <div class="errorStr">{errorStr}</div>

        <div class="renameBtn"
                on:click={() => create()}
                on:keypress={() => create()}>
            <i class="bi bi-plus"></i> Create
        </div>
    {/if}
</div>

<style>
    .dialog {
        margin: 0;
        position: absolute;
        z-index: 3;
        top: 40%;
        left: 50%;
        transform: translate(-50%, -50%);
        background-color: var(--backgroundColor);
        border: 1px solid var(--hoverBtnColor);
        width: max-content;
        color: var(--fontColor);
        padding: 1.0rem 1.5rem;
    }

    .closeBtn {
        position: fixed;
        top: 0.5rem;
        right: 0.5rem;
        font-size: 1.25rem;
        cursor: pointer;
    }

    .closeBtn:hover {
        color: red;
    }

    .title {
        font-weight: 600;
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
        margin-bottom: 0.75rem;
    }

    .renameBtn {
        width: fit-content;
        text-align: center;
        padding: 0.25rem 1.0rem;
        color: #34be7b;
        border: 1px solid;
        border-radius: 4px;
        cursor: pointer;
        user-select: none;
        margin-left: auto;
    }

    .renameBtn:hover {
        background-color: #34be7b;
        color: var(--backgroundColor);
    }
</style>
