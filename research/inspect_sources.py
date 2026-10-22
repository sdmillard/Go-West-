"""Read-only source inspection. Derived text and page previews stay in ignored local/."""
from pathlib import Path
from hashlib import sha256
import json
import zipfile
import pypdf
import pypdfium2 as pdfium

root = Path(__file__).parent / 'local'
manual = root / 'mecc-1985-apple-ii-manual.pdf'
reader = pypdf.PdfReader(manual)
text = '\n\n'.join(f'--- PDF PAGE {i + 1} ---\n{page.extract_text()}' for i, page in enumerate(reader.pages))
(root / 'mecc-1985-manual-extracted.txt').write_text(text, encoding='utf-8')
print(f'1985 manual: {len(reader.pages)} pages; text extracted locally.')
doc = pdfium.PdfDocument(str(manual))
for index in [3, 10]:
    doc[index].render(scale=1.5).to_pil().save(root / f'manual-page-{index+1}.png')
doc.close()
magazine = pypdf.PdfReader(root / 'creative-computing-1978-05.pdf')
hits = []
for i, page in enumerate(magazine.pages):
    if 'OREGON' in page.extract_text().upper():
        hits.append(i+1)
print(f'1978 magazine: {len(magazine.pages)} pages; Oregon text matches on PDF pages {hits}.')
archive = Path(r'C:\Users\Spencer\Downloads\The-Oregon-Trail_Win-3x_EN_LGU-Repack-by-Bladez1992-DPKG-by-HorrorWeed.zip')
with zipfile.ZipFile(archive) as z:
    entries = [{"name": i.filename, "bytes": i.file_size} for i in z.infolist()]
    raw = z.read(z.infolist()[0])
    (root / 'user-windows-repack.exe').write_bytes(raw)
    markers = [s for s in [b'Inno Setup', b'Nullsoft', b'DOSBox', b'WinRAR', b'7-Zip', b'Windows 3.1'] if s.lower() in raw.lower()]
report = {"archive": str(archive), "sha256": sha256(archive.read_bytes()).hexdigest(), "entries": entries,
          "embedded_markers": [s.decode() for s in markers], "executed": False}
(root / 'user-archive-inspection.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
