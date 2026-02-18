# Security

## Network Server

Camera Positions runs an HTTP server on **port 8080** to serve the web display.

- The server binds to your Mac's local network interface only
- It serves read-only data: camera assignments, names, and photos
- There are no admin endpoints — the web display cannot modify assignments
- No authentication is required (the display is intended to be openly viewable on your local network)

**If you do not want the web display accessible to other devices on your network**, you can access it at `http://localhost:8080` from the same machine only.

## Credential Storage

Planning Center OAuth credentials (Application ID and Secret) are stored in the **macOS Keychain**, not in plain text files or UserDefaults. Credentials are:

- Encrypted at rest by the system Keychain
- Never written to disk outside the Keychain
- Never logged to the console
- Cleared from the Keychain when you disconnect Planning Center

## Data Storage

All app data is stored locally in `~/Library/Application Support/CameraPositions/`:

- Camera positions, lens inventory, and weekend assignments (JSON files)
- Uploaded photos (angle photos, person photos)
- No data is sent to external servers except Planning Center API calls (over HTTPS)

## Image Handling

- Uploaded image filenames are sanitized to prevent directory traversal
- Hidden files (starting with `.`) are rejected
- Images are stored with UUID filenames, not user-provided names

## Reporting Security Issues

If you find a security vulnerability, please open an issue at [GitHub Issues](https://github.com/NorthwoodsCommunityChurch/camera-positions/issues).
