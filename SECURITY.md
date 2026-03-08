# Security Findings - Camera Positions

**Review Date**: 2026-03-01
**Reviewer**: Claude Security Review (Clara)
**Severity Summary**: 0 Critical, 0 High, 1 Medium, 1 Low

## Findings

| ID | Severity | Finding | File | Line | Status |
|----|----------|---------|------|------|--------|
| CP-01 | MEDIUM | HTTP server exposes team member names and photos without authentication | DisplayServer.swift | - | Open |
| CP-02 | LOW | No HTTPS on local HTTP server | DisplayServer.swift | - | Open |

## Detailed Findings

### CP-01 [MEDIUM] HTTP server exposes team member names and photos without authentication

**Location**: DisplayServer.swift (port 8080)
**Description**: The NWListener HTTP server serves position assignments, team member names, and person photos to any device on the local network without authentication. Endpoints include `/api/config` (JSON with all assignments) and `/api/images/{filename}` (person photos).
**Impact**: Any device on the local network can view team member names, lens assignments, and photos. This is by design for the web display use case, but exposes personal information.
**Remediation**: This is documented as intentional behavior. Image filenames are properly sanitized with UUID naming, and hidden files are rejected. Consider adding optional authentication for environments where network access is less controlled.

### CP-02 [LOW] No HTTPS on local HTTP server

**Location**: DisplayServer.swift (port 8080)
**Description**: The web display server uses plain HTTP. Data (including person photos) is transmitted unencrypted on the local network.
**Impact**: On a trusted local network, this is acceptable. On a shared or untrusted network, images and names could be intercepted.
**Remediation**: No action needed for a trusted production network. Consider TLS if deployed in a less controlled environment.

## Security Posture Assessment

**Overall Risk: LOW**

Camera Positions has a good security posture. Credentials are stored in the macOS Keychain (not in code or UserDefaults), image filenames are sanitized to prevent directory traversal, and the HTTP server is read-only. The app follows Apple platform security best practices for credential handling. The primary exposure is the intentionally unauthenticated HTTP display server.

## Remediation Priority

1. CP-01 - Document security implications (already done below)
2. CP-02 - No action needed for trusted LAN

---

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
