# Compatibility

Novella 1.0 targets the Godot 4 line.

| Godot | Status | Notes |
| --- | --- | --- |
| 4.3 | Targeted | Minimum supported Godot 4 version. Pending local matrix verification. |
| 4.4 | Targeted | Pending local matrix verification. |
| 4.5 | Targeted | Pending local matrix verification. |
| 4.6 | Verified | Primary development and release validation runtime. |
| 4.7+ | Expected | Treated as future-compatible unless a Godot API change requires an adapter. |

Godot 3.x is outside the Novella 1.0 support target because the editor plugin and runtime APIs differ too much from Godot 4.

Use `Novella.compatibility_matrix.runtime_status()` or `NovellaCompatibilityMatrix.new().runtime_status()` to inspect the current runtime.
