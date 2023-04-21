<script lang="ts">
    import { CreateCollection } from "$lib/scripts/db";
    import { ClickOutside } from "$lib/scripts/utils";
    import { goto } from '$app/navigation';

    export let showCreateCollection: boolean;

    const CollectionNameMaxLength: number = 30;

    let input: HTMLElement;
    let collectionName: string = "";
    let errorString: string = "";

    $: if (input) input.focus();

    function keyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                createCollection();
                return;
            case "Escape":
                showCreateCollection = !showCreateCollection;
                return;
        }
        if (errorString.length > 0) errorString = "";
    }

    function createCollection() {
        if (collectionName.length > 0) {
            if (collectionName.length > CollectionNameMaxLength) {
                errorString = "Collection name cannot exceed " + CollectionNameMaxLength + " characters."
            } else {
                CreateCollection(collectionName)
                    .catch((reason) => {
                        errorString = "Collection name already exists.";
                    })
                    .then((onfulfilled) => {
                        if (onfulfilled) {
                            showCreateCollection = !showCreateCollection;
                            goto("/" + onfulfilled.lastInsertId + "/" + collectionName + "/0/0");
                        }
                    });
            }
        } else {
            errorString = "Collection cannot be created without a name."
        }
    }
</script>

<div class="promptBox" 
        use:ClickOutside 
        on:outclick={() => showCreateCollection = !showCreateCollection}>
    <div class="closeBtn"
            on:click={() => showCreateCollection = !showCreateCollection}
            on:keypress={() => showCreateCollection = !showCreateCollection}>
        <i class="bi bi-x"></i></div>
    <div class="title">Create New Collection</div>
    <div class="noteInput"
        contenteditable="true"
        on:keydown={keyHandler}
        bind:this={input}
        bind:innerHTML={collectionName}
        placeholder="Enter collection name">
    </div>
    <div class="footer">
        <div class="messages">
            {#if errorString.length > 0}
                <div class="errorString">{errorString}</div>
            {/if}
        </div>
        <div class="createBtn"
                on:click={() => createCollection()}
                on:keypress={() => createCollection()}>
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

    .title {
        color: var(--fontColor);
        font-weight: 600;
        margin: 0.75rem 0 0 1.0rem;
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

    .noteInput {
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem;
        color: var(--fontColor);
        margin: 1.0rem 0.75rem 1.0rem 0.75rem;
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
        color: white;
        background-color: #238636;
        width: fit-content;
        text-align: center;
        padding: 0.25rem 1.0rem;
        border: 2px solid rgba(255, 255, 255, 0.2);
        border-radius: 4px;
        cursor: pointer;
        margin-left: 0.25rem;
    }

    .createBtn:hover {
        background-color: #196127;
    }
</style>