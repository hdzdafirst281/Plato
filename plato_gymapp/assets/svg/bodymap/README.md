# Bodymap assets

The four editable SVGs here are the source of truth for male and female
front/back illustrations. All use the `0 0 1900 3500` viewport.

After editing an SVG, run from plato_gymapp:

```sh
python tool/generate_body_map_paths.py
python tool/generate_body_map_paths.py --check
flutter test --no-pub test/features/profile
```

The generator validates layer IDs, muscle taxonomy, shared silhouettes and
flattened paths. Commit SVGs and generated Dart files together. Do not edit
lib/features/profile/presentation/components/bodymap/generated/ directly.
Generation needs no third-party Python packages or archived bodymap geometry.

BodyMapRepository parses generated paths synchronously and caches one geometry
per gender/view. StatsScreen observes profile gender; HeatmapDetailScreen
refreshes geometry when gender changes. Drawing and hit testing use the same
viewport and paths. Both genders share the muscle selector taxonomy.
SVGs are authoring files; the application does not load them at runtime.

Layer order: rear hair, body fill, muscles, anatomical lines, outline, front
hair, selection. Muscles and selection are clipped to the body silhouette.
Hair and decorative details are excluded from hit testing.

Tests cover bounds, containment, overlap, gender updates, themes, heatmap levels,
screen sizes and muscle selection. Visual artifacts are generated under
build/bodymap-review/ and can be removed after inspection.
