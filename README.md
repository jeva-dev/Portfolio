# C++ systems developer portfolio

An animated single-page portfolio built with Flutter.

## Make it yours

1. Replace the sample content in [lib/data/portfolio_data.dart](lib/data/portfolio_data.dart).
   That file holds all the personal text, projects, numbers and links.
2. Set `showSampleBanner` to `false` in the same file.
3. Update the `<title>` in [web/index.html](web/index.html).

## Run and build

```
flutter run -d chrome
flutter test
flutter build web --release
```

`build/web` is a static site that any static host can serve. If it is not
served from the domain root (for example GitHub Pages project sites), build with
`--base-href /repo-name/`.

## Animation map

| Where | What it does | Code |
| --- | --- | --- |
| Load | Fake compile log, then the screen frees itself cell by cell | `widgets/boot_overlay.dart` |
| Hero background | Live heap map that heats under the pointer and pulses on click | `widgets/memory_field.dart` |
| Hero name | Variable-font letters that thin and widen near the pointer | `sections/hero_section.dart` |
| About | C++ that types itself in, plus counters | `widgets/code_block.dart` |
| Stack | Layers that widen downward, with a pulse travelling through them | `sections/stack_section.dart` |
| Projects | Live models of each project; hovering speeds them up | `widgets/project_visuals.dart` |
| Page | Eased mouse wheel, scroll reveals, progress bar | `home_page.dart`, `widgets/motion.dart` |

Each project picks its model through `ProjectVisual` in the data file. A new
project can reuse a model, or add a painter to `project_visuals.dart`.

Animations stop while off screen, and the page honours the system's reduced
motion setting.

Archivo and JetBrains Mono are bundled under the SIL Open Font License; see
`assets/fonts`.
"# Portfolio" 
