<script lang="ts">
    import { CreatePositional } from "$lib/scripts/db";
    import { ClickOutside } from "$lib/scripts/utils";

    export let showCreatePositional: boolean;
    export let collection: Collection;
    export let changeViewMode: (categoryId: number, optionId: number) => void;
    export let loadPositionals: () => void;

    let input: HTMLElement;
    let positionalName: string = "";
    let errorString: string = "";

    $: if (input) input.focus();

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
        if (!(positionalName.length > 0)) {
            errorString = "Positional name cannot be blank."
            return;
        } else if (positionalName.length > 36) {
            errorString = "Positional name cannot exceed 36 characters."
            return;
        }
        CreatePositional(positionalName, collection.id)
            .then((value) => {
                loadPositionals();
                changeViewMode(3, value.lastInsertId);
            });
        showCreatePositional = !showCreatePositional;
    }
</script>

<div class="promptBox" 
        use:ClickOutside 
        on:outclick={() => showCreatePositional = !showCreatePositional}>
    <div class="closeBtn"
            on:click={() => showCreatePositional = !showCreatePositional}
            on:keypress={() => showCreatePositional = !showCreatePositional}>
        <i class="bi bi-x"></i></div>
    <div class="title">Create Positional</div>
    <div class="collection">
        <i class="bi bi-arrow-return-right icoRestraint"></i>
        <div class="collectionName">{collection.name}</div>
    </div>
    <div class="nameInput"
        contenteditable="true"
        on:keydown={keyHandler}
        bind:this={input}
        bind:innerHTML={positionalName}
        placeholder="Enter positional name">
    </div>
    <div class="footer">
        <div class="messages">
            {#if errorString.length > 0}
                <div class="errorString">{errorString}</div>
            {/if}
        </div>
        <div class="createBtn"
                on:click={() => createPositional()}
                on:keypress={() => createPositional()}>
            <i class="bi bi-plus"></i> Create
        </div>
    </div>
</div>

<style>
    .promptBox {
        margin: 0;
        position: absolute;
        z-index: 3;
        top: 40%;
        left: 50%;
        transform: translate(-50%, -50%);
        background-color: var(--backgroundColor);
        border: 1px solid var(--hoverBtnColor);
        width: 340px;
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
        margin: 0.75rem 0 0 1.0rem;
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
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem;
        color: var(--fontColor);
        margin: 0.5rem 1.0rem 1.0rem 1.0rem;
    }

    [contenteditable=true]:empty:before {
        content:attr(placeholder);
        color: grey;
        user-select: none;
        cursor: text;
    }

    .footer {
        display: grid;
        grid-template-columns: 1fr max-content;
        margin: 0 0.75rem 1.0rem 0.75rem;
    }

    .messages {
        font-size: 0.9rem;
    }

    .errorString {
        color: #BE3455;
    }

    .createBtn {
        width: fit-content;
        text-align: center;
        padding: 0.25rem 1.0rem;
        color: #34be7b;
        border: 1px solid;
        border-radius: 4px;
        cursor: pointer;
        margin-left: 0.25rem;
    }

    .createBtn:hover {
        background-color: #34be7b;
        color: var(--backgroundColor);
    }
</style>
