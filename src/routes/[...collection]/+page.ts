import type { PageLoad } from './$types';

export const load: PageLoad<Collection> = async ({ params }) => {
    const [collectionId, collectionName ] = params.collection.split('/');
    return {
        id: +collectionId,
        name: collectionName
    };
};