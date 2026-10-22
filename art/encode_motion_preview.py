"""Encode the real Godot motion-suite capture frames into a review GIF.

Optional development utility requiring Pillow; it does not author runtime art.
Run Godot tests/test_motion.gd -- --capture with a display first.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
frames = []
for method in ("ford", "float", "ferry", "failure"):
    # Exact frame names exclude unrelated files and sync-conflict copies.
    folder = root / ".tools" / "animation-frames" / method
    paths = [folder / f"{frame:03d}.png" for frame in range(42)]
    if not all(path.is_file() for path in paths):
        raise SystemExit(f"Missing Godot capture frames for {method}")
    for path in paths:
        with Image.open(path) as frame:
            frames.append(frame.convert("RGB"))
target = root / "docs" / "river-crossings.gif"
frames[0].save(target, save_all=True, append_images=frames[1:], duration=70,
               loop=0, optimize=False, disposal=2)
print(f"Encoded {len(frames)} actual game frames: {target}")
