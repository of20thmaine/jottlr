<script lang="ts">
    import { CreateNote, GetCollectionList } from "$lib/scripts/db";
    import { GetDefaultCollection } from "$lib/scripts/settings";
    import { WindowTitle } from "$lib/scripts/stores";

    WindowTitle.set("Quick Note");

    let collections: Collection[];
    let input: HTMLElement;
    let note: string = "";
    let showCollectionSelect: boolean = false;
    let selectedCollection: Collection;
    let errorString: string = "";
    let successString: string = "";

    $: if (input) input.focus();

    async function getData() {
        return Promise.all([GetCollectionList(), GetDefaultCollection()])
            .then((value) => {
                collections = value[0];
                let defaultId = value[1];
                if (!defaultId) defaultId = 1;

                for (let collection of collections) {
                    if (collection.id === defaultId) {
                        selectedCollection = collection;
                        return;
                    }
                }
            });
    }

    function createNote() {
        if (note.length > 0) {
            CreateNote(note, selectedCollection.id)
                .then(() => {
                    note = "";
                    successString = "Note created in " + selectedCollection.name;
                    errorString = "";
                })
                .catch(() => {
                    errorString = "Note failed to save.";
                    successString = "";
                });
        } else {
            errorString = "Empty notes cannot be saved."
            successString = "";
        }
    }

    function keyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                createNote();
                return;
        }
        if (errorString.length > 0) errorString = "";
        if (successString.length > 0) successString = "";
    }
</script>

{#await getData() then x}
    <div class="page">
        <div class="header">
            <div class="title">Quick Note</div>
            <div class="collectionPrompt">
                <i class="bi bi-arrow-return-right icoRestraint"></i>
                <div class="selector qnSelector" class:selectorSelected={showCollectionSelect}
                        on:click={() => {showCollectionSelect = !showCollectionSelect}}
                        on:keypress={() => {showCollectionSelect = !showCollectionSelect}}>
                    <div class="selected">{selectedCollection.name}</div>
                    <i class="bi bi-chevron-down rI"></i>
                </div>
            </div>
            {#if showCollectionSelect}
                <div class="blinder"
                    on:click={() => {showCollectionSelect = !showCollectionSelect}}
                    on:keypress={() => {showCollectionSelect = !showCollectionSelect}}></div>
                <div class="selectorMenu qnSelMen ">
                {#each collections as collection}
                    <div class="opt"
                            on:click={() => {
                                selectedCollection = collection;
                                showCollectionSelect = !showCollectionSelect;
                            }}
                            on:keypress={() => {
                                selectedCollection = collection;
                                showCollectionSelect = !showCollectionSelect;
                            }}>
                        {collection.name}</div>
                {/each}
                </div>
            {/if}
        </div>
        <div class="noteInput"
            contenteditable="true"
            on:keydown={keyHandler}
            bind:this={input}
            bind:innerHTML={note}
            placeholder="Create new note">
        </div>
        <div class="footer">
            <div class="messages">
                {#if errorString.length > 0}
                    <div class="errorString">{errorString}</div>
                {/if}
                {#if successString.length > 0}
                    <div class="successString">{successString}</div>
                {/if}
            </div>
            <div class="createBtn"
                    on:click={() => createNote()}
                    on:keypress={() => createNote()}>
                <i class="bi bi-plus"></i> Create
            </div>
        </div>
    </div>
{/await}

<style>
    .page {
        margin: 0 auto;
        margin-top: var(--titlebarHeight);
        max-width: 600px;
        padding: 1.0rem;
    }

    .header {
        margin: 0 1.0rem;
    }

    .title {
        color: var(--fontColor);
        font-weight: 600;
        margin-bottom: 0.5rem;
    }

    .collectionPrompt {
        color: var(--fontColor);
        display: flex;
        align-items: center;
    }

    .qnSelector {
        padding: 0.5rem 1.0rem 0.5rem 0.5rem;
        width: 220px;
    }

    .icoRestraint {
        width: 24px;
        height: auto;
    }

    .qnSelMen {
        margin-left: 24px;
        width: 220px;
    }

    .rI {
        margin-left: auto;
    }

    .noteInput {
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem;
        color: var(--fontColor);
        margin: 1.0rem 0.75rem;
        line-height: 1.84rem;
        min-height: 9.464rem;
        font-size: 1.15rem;
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

    .successString {
        color: #3cb452;
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
