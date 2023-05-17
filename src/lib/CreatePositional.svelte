<script lang="ts">
    import { CreatePositional, GetPositionalList } from "$lib/scripts/db";
    import { ClickOutside } from "$lib/scripts/utils";

    export let showCreatePositional: boolean;
    export let collection: Collection;
    export let changeViewMode: (categoryId: number, optionId: number) => void;
    export let loadPositionals: () => Promise<void>;

    const NameMaxLength: number = 30;

    let input: HTMLElement;
    let positionalName: string = "";
    let errorStr: string = "";
    let existing: Positional[];

    load();

    $: if (input) input.focus();

    async function load() {
        existing = await GetPositionalList();
    }

    function keyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                createPositional();
                return;
            case "Escape":
                showCreatePositional = !showCreatePositional;
                return;
        }
    }

    function createPositional() {
        checkPositionalName();
        if (errorStr.length > 0) return;

        CreatePositional(positionalName, collection.id)
            .then((value) => {
                loadPositionals()
                    .then(() => {
                        changeViewMode(3, value.lastInsertId);
                        showCreatePositional = !showCreatePositional;
                    });
            });
    }

    function checkPositionalName() {
        if (nameUsed(positionalName)) {
            errorStr = "A positional with this name already exists."
        } else if (positionalName.length === 0) {
            errorStr = "Positional requires a name."
        } else if (positionalName.length > NameMaxLength) {
            errorStr = "Positional name cannot exceed " + NameMaxLength + " characters.";
        } else {
            errorStr = "";
        }
    }

    function nameUsed(name: string) {
        for (let obj of existing) {
            if (name === obj.name) {
                return true;
            }
        }
        return false;
    }
</script>

<div class="dialog" 
        use:ClickOutside 
        on:outclick={() => showCreatePositional = false}>
    <div class="closeBtn"
            on:click={() => showCreatePositional = false}
            on:keypress={() => showCreatePositional = false}>
        <i class="bi bi-x"></i></div>
    <div class="title">Create Positional</div>
    <div class="collection">
        <i class="bi bi-arrow-return-right icoRestraint"></i>
        <div class="collectionName">{collection.name}</div>
    </div>
    <input type="text" class="nameInput" bind:this={input} on:keydown={keyHandler}
            bind:value={positionalName} on:keyup={checkPositionalName} />
        <div class="errorStr">{errorStr}</div>
    <div class="createBtn"
            on:click={() => createPositional()}
            on:keypress={() => createPositional()}>
        <i class="bi bi-plus"></i> Create
    </div>
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
        color: var(--fontColor);
        font-size: 1.25rem;
        cursor: pointer;
    }

    .closeBtn:hover {
        color: red;
    }

    .title {
        color: var(--fontColor);
        font-weight: 600;
    }

    .collection {
        color: var(--fontColor);
        display: flex;
        align-items: center;
        padding: 0.3rem 0 0.5rem 1.0rem;
    }

    .collectionName {
        margin-left: 0.5rem;
    }

    .nameInput {
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

    .createBtn {
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

    .createBtn:hover {
        background-color: #34be7b;
        color: var(--backgroundColor);
    }
</style>
