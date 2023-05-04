<script lang="ts">
    import { GetCollectionList, GetPositionalList, RenameCollection, RenamePositional } from "$lib/scripts/db";
    import { ChangeOption } from "$lib/scripts/settings";
    import { ClickOutside } from "$lib/scripts/utils";
    import { WindowTitle } from "$lib/scripts/stores";

    export let showDialog: boolean;
    export let changeOption: ChangeOption;
    export let changeObject: ChangeObject;
    export let changeViewMode: (categoryId: number, optionId: number) => void;

    const NameMaxLength: number = 30;

    let nameInput: HTMLElement;
    let errorStr: string = "";
    let existing: Collection[] | Positional[];

    load();

    $: if (nameInput) nameInput.focus();

    async function load() {
        if (changeOption === ChangeOption.Collection) {
            existing = await GetCollectionList();
        } else {
            existing = await GetPositionalList();
        }
    }

    async function rename() {
        if (changeOption === ChangeOption.Collection) {
            checkCollectionName();
            if (errorStr.length > 0) return;
            RenameCollection(changeObject.collection.id, changeObject.collection.name)
                .then(() => WindowTitle.set(changeObject.collection.name));
            showDialog = false;
        } else {
            checkPositionalName();
            if (errorStr.length > 0) return;
            RenamePositional(changeObject.viewMode.id, changeObject.viewMode.name)
                .then(() => changeViewMode(3, changeObject.viewMode.id));
            showDialog = false;
        }
    }

    function keyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                rename();
                return;
            case "Escape":
                showDialog = false;
                return;
        }
    }

    function checkCollectionName() {
        if (nameUsed(changeObject.collection.name, changeObject.collection.id)) {
            errorStr = "A collection with this name already exists."
        } else if (changeObject.collection.name.length === 0) {
            errorStr = "Collection requires a name."
        } else if (changeObject.collection.name.length > NameMaxLength) {
            errorStr = "Collection name cannot exceed " + NameMaxLength + " characters.";
        } else {
            errorStr = "";
        }
    }

    function checkPositionalName() {
        if (nameUsed(changeObject.viewMode.name, changeObject.viewMode.id)) {
            errorStr = "A positional with this name already exists."
        } else if (changeObject.viewMode.name.length === 0) {
            errorStr = "Positional requires a name."
        } else if (changeObject.viewMode.name.length > NameMaxLength) {
            errorStr = "Positional name cannot exceed " + NameMaxLength + " characters.";
        } else {
            errorStr = "";
        }
    }

    function nameUsed(name: string, id: number) {
        for (let obj of existing) {
            if (name === obj.name && id !== obj.id) {
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
    {#if existing}
        {#if changeOption === ChangeOption.Positional}
            <div class="title">
                Rename Positional:
            </div>
            <input type="text" class="txtInput" bind:this={nameInput} on:keydown={keyHandler}
                bind:value={changeObject.viewMode.name} on:keyup={checkPositionalName} />
            <div class="errorStr">{errorStr}</div>
        {:else if changeOption === ChangeOption.Collection}
            <div class="title">
                Rename Collection:
            </div>
            <input type="text" class="txtInput" bind:this={nameInput} on:keydown={keyHandler}
                bind:value={changeObject.collection.name} on:keyup={checkCollectionName} />
            <div class="errorStr">{errorStr}</div>
        {/if}
        <div class="renameBtn"
                on:click={() => rename()}
                on:keypress={() => rename()}>
            <i class="bi bi-pencil-square"></i> Rename
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
        width: 260px;
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
        margin-left: auto;
    }

    .renameBtn:hover {
        background-color: #34be7b;
        color: var(--backgroundColor);
    }
</style>
