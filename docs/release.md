# Release Process

1. Run the full local test suite:

   ```powershell
   .\scripts\test-godot.ps1
   ```

2. Run release validation:

   ```powershell
   .\scripts\validate-release.ps1
   ```

3. Build the addon package:

   ```powershell
   .\scripts\package-addon.ps1
   ```

4. Inspect the generated `dist/novella-<version>.zip`.

5. Commit, push, and tag the accepted release commit.

Never commit Godot editor binaries, export templates, `.godot/`, `.godot_user/`, generated packages, logs, or local requirement/progress documents.
