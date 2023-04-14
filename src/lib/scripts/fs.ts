import { save } from '@tauri-apps/api/dialog';

export async function ExportAs() {
    const filePath = await save({
        title: "Export As"
    });

    if (!filePath) return;




}
