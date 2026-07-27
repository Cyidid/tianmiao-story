# Tianmiao Live2D Native SDK Adapter

The macOS app reserves `Resources/Live2D/Tianmiao/` for a real Cubism export, but this repository does not vendor the official Live2D Cubism Native SDK.

After downloading the SDK and confirming the license, add a native renderer that:

- Loads `Resources/Live2D/Tianmiao/tianmiao.model3.json`.
- Uses the referenced `.moc3`, textures, physics, pose, expressions, and motion files.
- Renders into the transparent desktop-pet window.
- Exposes only these motion IDs to the app scheduler: `idle`, `blink`, `tap`, `walk`, `groom`, `scratch`.
- Falls back to the current readiness state if the model, SDK, or renderer initialization is incomplete.

Do not expose sleep, roll, hop, or replacement-cat motions without matching Cubism exports and acceptance screenshots.
