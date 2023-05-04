<script lang="ts">
    import { goto } from '$app/navigation';
    import { DeleteCollection, DeletePositional } from "$lib/scripts/db";
    import { ChangeOption } from "$lib/scripts/settings";
    import { ClickOutside } from "$lib/scripts/utils";

    export let showDialog: boolean;
    export let changeOption: ChangeOption;
    export let changeObject: ChangeObject;
    export let changeViewMode: (categoryId: number, optionId: number) => void;
    export let loadPositionals: () => Promise<void>;

    async function executeDeletion() {
        if (changeOption === ChangeOption.Collection) {
            await DeleteCollection(changeObject.collection.id)
                .then(() => goto("/"));
        } else {
            await DeletePositional(changeObject.viewMode.id, true)
                .then(() => {
                    loadPositionals()
                        .then(() => {
                            changeViewMode(0, 0);
                            showDialog = false;
                        });
                });
        }
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
    {#if changeOption === ChangeOption.Positional}
        <div class="title">
            Are you sure you want to delete positional "{changeObject.viewMode.name}"?
        </div>
    {:else if changeOption === ChangeOption.Collection}
        <div class="title">
            Are you sure you want to delete collection "{changeObject.collection.name}"?
        </div>
    {/if}
    <div class="subTitle">This action cannot be reversed.</div>
    <div class="deleteBtn"
            on:click={() => executeDeletion()}
            on:keypress={() => executeDeletion()}>
        <i class="bi bi-trash"></i> Delete
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
        width: 370px;
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

    .subTitle {
        font-weight: 400;
        margin: 0.75rem 0;
    }

    .deleteBtn {
        width: fit-content;
        text-align: center;
        padding: 0.25rem 1.0rem;
        color: #BE3455;
        border: 1px solid;
        border-radius: 4px;
        cursor: pointer;
        margin-left: auto;
    }

    .deleteBtn:hover {
        background-color: #BE3455;
        color: var(--backgroundColor);
    }
</style>
