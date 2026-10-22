# Local source library

The public BASIC sources, magazine scan, 1985 instruction booklet and design references have been downloaded for local study. `SOURCES.json` records their URLs, sizes and SHA-256 hashes. Re-fetch using `download-sources.ps1`; mutable upstream URLs may yield newer bytes, so compare hashes before updating observations.

## What is here

`local/` contains:

- 1975 and 1978 BASIC listings, repository README and license.
- July 1985 MECC H-106 Apple II instruction booklet.
- May–June 1978 Creative Computing magazine scan.
- Bouchard's design, river and geography retrospectives.
- The complete nine-story Bouchard series, with local HTML/text snapshots in `local/bouchard/` and a separate `BOUCHARD_SOURCES.json` manifest. Refresh using `read_bouchard.py`; reading notes and implementation consequences are in `docs/BOUCHARD_DESIGN_NOTES.md`.
- MECC chronology and a secondary 1993 Windows game reference page.
- Read-only PDF text extraction and page previews.
- Static inspection notes and a working copy of the installer supplied by the user.

**Only the BASIC listings are source code.** No verified 1985 or 1993 source code was obtained. The supplied ZIP contains one file, `The Oregon Trail (Windows 3.x).exe` (20,025,132 bytes), not a source tree. Identifying the actual game build requires inspecting its installed contents/running program.

The supplied installer was successfully run inside Docker/Wine, followed by its bundled DOSBox/Windows 3.11 environment. The game shows MECC's 1993 copyright. It was not executed on the Windows host. WSL alone is not the selected execution boundary because of its normal Windows integration. The chosen game container has no personal-folder mounts, drops capabilities and uses an externally isolated network. A separate fixed-endpoint relay publishes the desktop on loopback. See `docs/REFERENCE_PLAYTEST_1993.md` for the observed journey and file findings.

## Rights and provenance

Third-party downloads and extracted material are ignored by Git and are not runtime assets. Our MIT license does not apply to these documents or the installer. Keep upstream license notices with the source snapshots. The reference repository's LICENSE names modern contributors and contains MIT/ISC-style grants; this does not independently resolve the provenance of every historic line. We are studying behavior and writing independent code.

No classic-game graphics, fonts, music, or other proprietary assets are copied into the Godot game. The existing public-facing title and directly authored Western pixel art remain original.

## Development direction

The October 22 user decision prioritizes history over matching the classic games. `history-sources.ps1` records period-guide and official-history retrievals in `HISTORY_SOURCES.json`; `docs/HISTORICAL_ACCURACY.md` explains changes and limitations. Older game references remain useful comparisons.

See `docs/PROJECT_BRIEF.md` for the supplied long-term brief and `docs/MECHANICS_LEDGER.md` for the actively maintained evidence ledger. The user's later instruction establishes the order: **build Classic first, then add the unusual systems.** Existing experimental code is parked, not a reason to prioritize it over Classic.
