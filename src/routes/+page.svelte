<script lang="ts">
    import { gotoCollection } from "$lib/scripts/utils";
    import { GetCollections, GetFavorites, GetLastOpenCollection } from "$lib/scripts/db";
    import { ShowCreateCollection, WindowTitle } from "$lib/scripts/stores";
    import CollectionsTable from "$lib/CollectionsTable.svelte";

    WindowTitle.set("Home");

    let lastOpen: Collection;
    let collections: CollectionSelection[];
    let favorites: CollectionSelection[];

    GetLastOpenCollection().then((value) => lastOpen = value[0]);
    updateCollections();

    async function updateCollections(): Promise<void> {
        return Promise.all([GetFavorites(), GetCollections()])
            .then((value) => {
                favorites = value[0];
                collections = value[1];
            });
    }
</script>

<div class="scroller">
    <div class="page">
        <div class="pageTop">
            <div class="lastOpen">
                {#if lastOpen}
                    <div class="header">Last Open</div>
                    <div class="lastOpenCollection"
                            on:click={() => gotoCollection(lastOpen)}
                            on:keypress={() => gotoCollection(lastOpen)}>
                        <i class="bi bi-arrow-return-right"></i> {lastOpen.name}
                    </div>
                {:else}
                    <div class="header">Welcome to Jottlr!</div>
                    <div class="subHeader">We created a collection for you so you can get started right away.</div>
                    <div class="lastOpenCollection"
                            on:click={() => gotoCollection({id: 1, name: "Jottlr"})}
                            on:keypress={() => gotoCollection({id: 1, name: "Jottlr"})}>
                        <i class="bi bi-arrow-return-right"></i> Jottlr
                    </div>
                {/if}
            </div>
            <div class="btnGroup">
                <a href="quicknote">
                    <div class="homeBtn quicknote">
                        <i class="lM bi bi-pencil-square"></i>Quick Note
                    </div>
                </a>
                <div class="homeBtn createcoll"
                        on:click={() => $ShowCreateCollection = true}
                        on:keypress={() => $ShowCreateCollection = true}>
                <i class="lM bi bi-plus-lg"></i>Create Collection</div>
            </div>
        </div>
        {#if favorites && favorites.length > 0}
            <div class="header">Favorites</div>
            <CollectionsTable
                bind:collections={favorites}
                updateCollections={updateCollections}
            />
        {/if}
        {#if collections}
            <div class="header">Collections</div>
            <CollectionsTable
                bind:collections={collections}
                updateCollections={updateCollections}
            />
        {/if}
    </div>
</div>

<style>
    .page {
        margin: 0 auto;
        max-width: var(--usableWidth);
        padding: 1.0rem;
    }

    .pageTop {
        display: grid;
        grid-template-columns: 1fr 220px;
        column-gap: 1.0rem;
        margin-bottom: 1.0rem;
    }

    .header {
        color: var(--fontColor);
        font-size: 1.5rem;
        border-bottom: 1px solid;
        padding: 0.5rem;
        margin-bottom: 0.5rem;
    }

    .subHeader {
        margin-top: 0.5rem;
        color: var(--fontColor);
        font-size: 1.0rem;
        padding: 0 0.5rem;
    }

    .lastOpenCollection {
        margin-top: 0.5rem;
        color: var(--fontColor);
        font-size: 1.15rem;
        cursor: pointer;
        user-select: none;
    }

    .btnGroup {
        padding-top: 1.0rem;
    }

    .homeBtn {
        font-size: 1.05rem;
        font-weight: 500;
        text-align: center;
        width: 100%;
        padding: 0.5rem 0;
        border: 1px solid;
        border-radius: 4px;
        margin-top: 1.0rem;
        cursor: pointer;
        user-select: none;
    }

    .quicknote {
        color: #B19CD8;
    }

    .createcoll {
        color: #34be7b;
    }

    .lM {
        margin-right: 1.0rem;
    }

    a {
        text-decoration: none;
    }
</style>