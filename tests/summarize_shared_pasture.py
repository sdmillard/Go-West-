"""Check frozen ordinary-journey parity after centralizing pasture inputs."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'.tools'
OLD='806fb9c1e115b026b7334abcfc9bcc979bc0ca2d'
NEW='6a8872f5365ad920ba100707e7075be7232fc7a2'
def sha(blob):return hashlib.sha256(blob).hexdigest()
def main():
 archives=[];pairs=0;old_blobs={}
 fields=['seed','month','outfit','opening_cash','opening_cost_cents','outcome','days','miles','original_present','original_survived','cash','food','counts','audit','field','camp_work','camp_forage','motion','route','curve','livestock','feeding_comparison']
 for arm in ['none','mixed']:
  cohorts={}
  for version in ['old','new']:
   p=T/f'hunting-shared-pasture-{version}-{arm}-01.json';d=json.loads(p.read_text(encoding='utf-8'))
   assert len(d['runs'])==4 and not d['errors'] and d['seed_start']==445000 and d['seeds']==2 and d['months']==[5,7]
   assert d['runtime_label']==version and d['livestock_arm']==arm and d['outfit_profile']=='standard' and d['feeding_policy']=='fodder'
   for name,digest in d['source_hashes'].items():
    if version=='new':assert sha((ROOT/name).read_bytes())==digest,name
    else:
     if name not in old_blobs:old_blobs[name]=subprocess.check_output(['git','show',OLD+':'+name],cwd=ROOT)
     blob=old_blobs[name];lf=blob.replace(b'\r\n',b'\n')
     candidates={sha(blob),sha(lf),sha(lf.replace(b'\n',b'\r\n'))}
     current=(ROOT/name).read_bytes()
     if sha(current)==digest and current.replace(b'\r\n',b'\n')==lf:candidates.add(digest)
     assert digest in candidates,name
   cohorts[version]={(r['month'],r['seed']):r for r in d['runs']}
   archives.append({'file':p.name,'sha256':sha(p.read_bytes()),'rules_signature':d['rules_signature'],'source_hashes':d['source_hashes']})
  assert cohorts['old'].keys()==cohorts['new'].keys()
  for key,a in cohorts['old'].items():
   b=cohorts['new'][key]
   for field in fields:assert a[field]==b[field],(arm,key,field)
   pairs+=1
 log=(T/'shared-pasture-tests.log').read_text(encoding='utf-8')
 assert len(re.findall(r'^Godot Engine',log,re.M))==85 and 'Shared pasture: 741 checks, 0 failures' in log
 assert not re.search(r'SCRIPT ERROR:|ERROR:|FAIL:',log)
 result={'old_runtime':OLD,'new_runtime':NEW,'purpose':'Shared-input refactor parity plus focused named-grazing tests; no ecology or survival retuning claim.','test_suites':85,'focused_checks':741,'pairs':pairs,'journeys':pairs*2,'errors':0,'compared_fields':fields,'archives':archives,'limitations':['Two seeds repeated across May/July and no-stock/mixed arms; not sixteen independent worlds.','Scripted ordinary journeys do not replace the focused actual named-grazing activity checks.','Ox/mount responses remain their earlier condition model, not full nutrient ledgers.']}
 (ROOT/'docs/shared-pasture-validation-01.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 print('Verified 85 suites, 741 focused checks and eight identical full-journey pairs (16 journeys).')
if __name__=='__main__':main()
