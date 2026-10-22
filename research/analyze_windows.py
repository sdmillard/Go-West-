"""Inventory the supplied compiled Windows game; all extracted content stays local."""
from pathlib import Path
from hashlib import sha256
from collections import Counter
import json
import struct
import subprocess

root = Path(__file__).parent / 'local' / 'windows-game'
root.mkdir(parents=True, exist_ok=True)
docker = r'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
base = '/home/wine/prefix/drive_c/Games/The Oregon Trail (Windows 3.x)'
files = ['OREGON.EXE', 'OREGONSP.DLL', 'OREGON.HLP', 'OREGON.INI']
types = {1:'cursor',2:'bitmap',3:'icon',4:'menu',5:'dialog',6:'string_table',7:'font_directory',8:'font',9:'accelerator',10:'raw_data',12:'group_cursor',14:'group_icon',16:'version'}
report = []
strings = []
for name in files:
    # docker cp cannot see this runtime tmpfs on the available daemon; exec reads it.
    result = subprocess.run([docker, 'exec', '-w', base, 'oregon-reference-study', 'cat', 'GAM/win311/WINDOWS/'+name], capture_output=True, check=True)
    raw = result.stdout
    (root / name).write_bytes(raw)
    item = {'name':name, 'bytes':len(raw), 'sha256':sha256(raw).hexdigest()}
    if raw[:2] == b'MZ':
        offset = struct.unpack_from('<I', raw, 60)[0]
        magic = raw[offset:offset+2]
        item['format'] = magic.decode('ascii', errors='replace')
        if magic == b'NE':
            table = offset + struct.unpack_from('<H', raw, offset+0x24)[0]
            align = struct.unpack_from('<H', raw, table)[0]
            pos = table + 2
            resources = Counter()
            while pos + 8 < len(raw):
                kind, count = struct.unpack_from('<HH', raw, pos)
                if not kind:
                    break
                pos += 8
                type_id = kind & 0x7fff
                resources[types.get(type_id, str(type_id))] += count
                for _ in range(count):
                    address, size, flags, ident, handle, usage = struct.unpack_from('<6H', raw, pos)
                    pos += 12
                    data = raw[address << align:(address+size) << align]
                    if type_id == 6:
                        p = 0
                        for i in range(16):
                            if p >= len(data): break
                            length = data[p]; p += 1
                            value = data[p:p+length].decode('cp1252', errors='replace'); p += length
                            if value:
                                strings.append({'module':name, 'id':((ident & 0x7fff)-1)*16+i, 'text':value})
                    if type_id == 16:
                        fixed = data.find(bytes.fromhex('bd04effe'))
                        if fixed >= 0 and fixed + 16 <= len(data):
                            ms, ls = struct.unpack_from('<II', data, fixed+8)
                            item['file_version'] = f'{ms>>16}.{ms&65535}.{ls>>16}.{ls&65535}'
            item['resource_counts'] = dict(resources)
    report.append(item)
(root / 'file-inventory.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
(root / 'string-tables.json').write_text(json.dumps(strings, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps(report, indent=2))
print('String-table entries available for local study:', len(strings))
