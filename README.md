# Voxel Face Shader

Per-texel toon shader for Godot 4, designed for atlas-based voxel terrain. Lighting steps across individual texture pixels rather than screen pixels, so the cel-shaded bands always align with your pixel art — regardless of camera distance or view angle.

## How it works

Each face samples a tile from a texture atlas using `UV2` (tile index) + `UV` (position within tile). The shader computes the world-space texel footprint via screen-space derivatives (`dFdx`/`dFdy`) and offsets `LIGHT_VERTEX` so that diffuse lighting is constant across each texel. Diffuse is then stepped into discrete bands (`cuts`), producing a crisp toon look that respects the pixel grid of the source art.

## Parameters

| Uniform | Type | Description |
|---|---|---|
| `atlas` | `sampler2D` | Texture atlas (nearest-neighbor filtering) |
| `atlas_tiles` | `vec2` | Atlas grid dimensions (e.g. `32, 32`) |
| `cuts` | `int` (1–8) | Number of diffuse bands |
| `steepness` | `float` (1–8) | Band transition sharpness |
| `wrap` | `float` (−2 to 2) | Light wrapping — pushes diffuse before stepping |
| `use_attenuation` | `bool` | Toggle distance/point-light attenuation |
| `clamp_diffuse_to_max` | `bool` | Clamp diffuse to max across lights instead of additive |
| `use_borders` | `bool` | Enable dark border at band edges |
| `border_width` | `float` | Border thickness |
| `use_specular` | `bool` | Enable hard specular |
| `specular_strength` | `float` (0–1) | Specular intensity |
| `specular_shininess` | `float` (0–32) | Specular exponent (squared internally) |
| `use_rim` | `bool` | Enable rim lighting |
| `rim_width` | `float` (0–16) | Rim falloff power |
| `rim_color` | `vec4` | Rim color and opacity |
| `use_ramp` | `bool` | Use a ramp texture for diffuse color mapping |
| `ramp` | `sampler2D` | 1D horizontal ramp texture |

## Single sprite usage

To use this shader on a single PNG (no atlas), set `atlas_tiles` to `vec2(1, 1)` and make sure your mesh provides `UV2 = vec2(0, 0)` for all vertices. The shader will treat the entire texture as one tile and apply per-texel lighting across it.

In Godot, the simplest setup is:

1. Create a `ShaderMaterial` with this shader
2. Set `atlas` to your sprite PNG and `atlas_tiles` to `(1, 1)`
3. Apply it to a `QuadMesh` or `PlaneMesh` — Godot's built-in meshes set `UV2` to `(0, 0)` by default, so no extra UV2 work is needed

## License

MIT — do whatever you want with it. Credit appreciated but not required.
