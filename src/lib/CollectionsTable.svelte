<script lang="ts">
    import { SetCollectionFavorite } from "$lib/scripts/db";

    export let collections: CollectionSelection[];
    export let updateCollections: () => Promise<void>;

    let currentSort: number = 4;

    function toggleCollectionFavorite(collectionId: number, isFavorite: boolean) {
        SetCollectionFavorite(collectionId, !isFavorite)
            .then(() => updateCollections());
    }

    function sortCollections(sortA: number, sortB: number) {
        if (currentSort === sortA || sortB) {
            currentSort === sortA ? currentSort = sortB : currentSort = sortA;
        } else {
            currentSort = sortA;
        }
        switch (currentSort) {
            case 0: collections.sort((a, b) => { // a-z
                return (a.name < b.name) ? -1 : 1;
            }); break;
            case 1: collections.sort((a, b) => { // z-a
                return (b.name < a.name) ? -1 : 1;
            }); break;
            case 2: collections.sort((a, b) => { // 1-9
                return (a.note_count < b.note_count) ? -1 : 1;
            }); break;
            case 3: collections.sort((a, b) => { // 9-1
                return (b.note_count < a.note_count) ? -1 : 1;
            }); break;
            case 4: collections.sort((a, b) => { // new-old
                return +new Date(b.last_open) - +new Date(a.last_open);
            }); break;
            case 5: collections.sort((a, b) => { // old-new
                return +new Date(a.last_open) - +new Date(b.last_open);
            }); break;
        }
        collections = collections;
    }
</script>

<div class="collections">
    <div class="row hrow">
        <div class="coH"></div>
        <div class="coH"
                on:click={() => sortCollections(0, 1)}
                on:keypress={() => sortCollections(0, 1)}>
            <div class="cohTxt">Name</div>
            {#if currentSort === 0}
                <div class="cohIco"><i class="bi bi-caret-down-fill"></i></div>
            {:else if currentSort === 1}
                <div class="cohIco"><i class="bi bi-caret-up-fill"></i></div>
            {/if}
        </div>
        <div class="coH"
                on:click={() => sortCollections(2, 3)}
                on:keypress={() => sortCollections(2, 3)}>
            <div class="cohTxt">Notes</div>
            {#if currentSort === 2}
                <div class="cohIco"><i class="bi bi-caret-down-fill"></i></div>
            {:else if currentSort === 3}
                <div class="cohIco"><i class="bi bi-caret-up-fill"></i></div>
            {/if}
        </div>
        <div class="coH"
                on:click={() => sortCollections(4, 5)}
                on:keypress={() => sortCollections(4, 5)}>
            <div class="cohTxt">Last Open</div>
            {#if currentSort === 4}
                <div class="cohIco"><i class="bi bi-caret-down-fill"></i></div>
            {:else if currentSort === 5}
                <div class="cohIco"><i class="bi bi-caret-up-fill"></i></div>
            {/if}
        </div>
    </div>
    {#each collections as collection}
        <a href="{collection.id + "/" + collection.name}">
        <div class="row itmR">
            <div class="co favIco" class:isFavorite={collection.favorite}><i class="bi bi-star-fill"
                on:click={(event) => {
                    event.preventDefault();
                    toggleCollectionFavorite(collection.id, collection.favorite)}}
                on:keypress={(event) => {
                    event.preventDefault();
                    toggleCollectionFavorite(collection.id, collection.favorite)}}></i></div>
            <div class="co">{collection.name}</div>
            <div class="co">{collection.note_count}</div>
            {#if +new Date() - +new Date(collection.last_open) > (24*60*60*1000)}
                <div class="co">{new Date(collection.last_open).toLocaleDateString([], {year: "numeric", month: "short", day: "numeric"})}</div>
            {:else}
                <div class="co">{new Date(collection.last_open).toLocaleTimeString([], {hour: "numeric", minute: "numeric", hour12: true})}</div>
            {/if}
        </div>
        </a>
    {/each}
</div>

<style>
    .collections {
        margin-bottom: 1.0rem;
    }
    
    .row {
        display: grid;
        grid-template-columns: 40px 1fr 100px 140px;
    }

    .hrow {
        margin-bottom: 0.75rem;
    }

    .coH {
        color: var(--fontColor);
        font-weight: 600;
        user-select: none;
        cursor: pointer;
        display: flex;
        align-items: center;
    }

    .cohIco {
        margin-left: auto;
        margin-right: 1.0rem;
    }

    .co {
        color: var(--fontColor);
    }

    .itmR {
        border-bottom: 1px solid var(--titlebarColor);
        padding: 0.5rem 0;
    }

    .itmR:hover {
        background-color: var(--highlightColor);
    }

    .favIco {
        font-size: 14px;
        padding-left: 8px;
        color: transparent;
    }

    .favIco {
        color: var(--backgroundColor);
    }

    .isFavorite {
        color: #F5DF4D;
    }

    .itmR:hover .favIco:hover {
        color: #F5DF4D;
    }

    a {
        text-decoration: none;
    }
</style>
