"""Archive the public nine-part design retrospective for private research."""
import hashlib
import json
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
SLUGS = ["early-versions", "imagining-design", "travel-screen", "hunting",
         "crossing-rivers", "real-geography", "rafting-columbia",
         "including-humans", "different-journey"]


class TextReader(HTMLParser):
    def __init__(self):
        super().__init__()
        self.skip = 0
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self.skip += 1
        if tag in ("p", "br", "li", "h1", "h2", "h3", "h4"):
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self.skip -= 1
        if tag in ("p", "li", "h1", "h2", "h3", "h4"):
            self.parts.append("\n")

    def handle_data(self, data):
        if not self.skip:
            self.parts.append(data)


def main():
    destination = ROOT / "local" / "bouchard"
    destination.mkdir(parents=True, exist_ok=True)
    (ROOT / "local" / ".gdignore").touch()
    manifest = []
    pages = [("index", "https://www.philipbouchard.com/oregon-trail.html")]
    pages += [(slug, f"https://www.philipbouchard.com/oregon-trail/{slug}.html") for slug in SLUGS]
    for slug, url in pages:
        request = Request(url, headers={"User-Agent": "OregonTrailResearch/1.0"})
        with urlopen(request, timeout=30) as response:
            raw = response.read()
        (destination / f"{slug}.html").write_bytes(raw)
        parser = TextReader()
        parser.feed(raw.decode("utf-8", errors="replace"))
        lines = [" ".join(line.split()) for line in "".join(parser.parts).splitlines()]
        content = "\n".join(line for line in lines if line)
        (destination / f"{slug}.txt").write_text(content, encoding="utf-8")
        manifest.append(dict(id=f"bouchard-{slug}", url=url,
                             file=f"local/bouchard/{slug}.html", bytes=len(raw),
                             sha256=hashlib.sha256(raw).hexdigest(),
                             retrieved_utc=datetime.now(timezone.utc).isoformat()))
        print(f"{slug}: {len(content.split())} words")
    (ROOT / "BOUCHARD_SOURCES.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
