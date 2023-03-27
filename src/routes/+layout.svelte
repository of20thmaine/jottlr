<script lang="ts">
	import "../app.css";
	import "bootstrap-icons/font/bootstrap-icons.css";
    import { onMount } from "svelte";
	import { GetColorModeIsDark } from "$lib/scripts/settings";
    import { ColorModeIsDark } from "$lib/scripts/stores";
	import TitleBar from "$lib/TitleBar.svelte";

    onMount(() => {
        // Set color mode to user setting if exists, else system setting.
        GetColorModeIsDark().then((value) => {
            let useDark = value as boolean | null;

            if (useDark === null) {
                useDark = window.matchMedia("(prefers-color-scheme: dark)") && true;
            }
            ColorModeIsDark.set(useDark);
        });
        // If system color mode changes, change app mode if user setting not set.
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener("change", () => {
            GetColorModeIsDark().then((value) => {
                let useDark = value as boolean | null;

                if (useDark === null) {
                    ColorModeIsDark.set(window.matchMedia("(prefers-color-scheme: dark)") && true);
                }
            });
        });
    });
    // Single place in app to change color mode css, other places only change ColorModeIsDark
    ColorModeIsDark.subscribe((value) => {
        if (value) {
            document.documentElement.setAttribute("color-mode", "dark");
        } else {
            document.documentElement.setAttribute("color-mode", "light");
        }
    });
</script>

<TitleBar />
<div>
	<slot />
</div>
