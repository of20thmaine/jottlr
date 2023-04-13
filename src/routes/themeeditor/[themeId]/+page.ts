import type { PageLoad } from './$types';
 
export const load = (({ params }) => {
    if (params.themeId) {
        return { id: Number(params.themeId) }
    } else {
        return { id: 0 }
    }
}) satisfies PageLoad;
