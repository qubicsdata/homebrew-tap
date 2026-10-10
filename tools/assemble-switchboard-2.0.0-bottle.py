"""Standard Homebrew bottle assembly of a SHA-verified, unchanged Switchboard archive.
The assembly receipt records binary repackaging, never a compilation or installation pass.
"""
import argparse, hashlib, json, os, pathlib, posixpath, re, shutil, stat, tarfile, tempfile, time

SOURCE_COMMIT='fe0f3390e134adceefe0404d1dd0780cecdd8380'
TARGET_TAGS={'darwin-arm64':'arm64_golden_gate','darwin-x64':'golden_gate','linux-arm64':'arm64_linux','linux-x64':'x86_64_linux'}

def digest(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()

def inventory(root):
    result={}
    for directory,dirs,files in os.walk(root,followlinks=False):
        for name in sorted(dirs+files):
            path=pathlib.Path(directory)/name;relative=path.relative_to(root).as_posix();s=path.lstat()
            row={'mode':stat.S_IMODE(s.st_mode)}
            if stat.S_ISLNK(s.st_mode):
                row.update(type='symlink',target=os.readlink(path))
                if not path.resolve().is_relative_to(root.resolve()):raise ValueError('Payload symlink escapes archive: '+relative)
            elif stat.S_ISREG(s.st_mode):row.update(type='file',sha256=digest(path),size=s.st_size)
            elif stat.S_ISDIR(s.st_mode):row.update(type='directory')
            else:raise ValueError('Unsupported payload file type: '+relative)
            result[relative]=row
    return dict(sorted(result.items()))

def verify_payload(root,expected):
    actual=inventory(pathlib.Path(root))
    if actual!=expected:
        added=sorted(actual.keys()-expected.keys());missing=sorted(expected.keys()-actual.keys());changed=sorted(n for n in actual.keys()&expected.keys() if actual[n]!=expected[n])
        raise ValueError(json.dumps({'added':added,'missing':missing,'changed':changed}))
    return {'entries':len(actual),'files':sum(r['type']=='file' for r in actual.values()),'symlinks':sum(r['type']=='symlink' for r in actual.values())}

def extract_verified(archive,destination):
    with tarfile.open(archive) as t:
        members=t.getmembers();names={};links=set()
        for m in members:
            name=posixpath.normpath(m.name);parts=pathlib.PurePosixPath(m.name).parts
            if name=='.' and m.isdir():continue
            if not name or name.startswith('/') or '..' in parts or '\x00' in name or name in names:raise ValueError('Unsafe or duplicate archive member: '+name)
            if not (m.isdir() or m.isfile() or m.issym()):raise ValueError('Unsupported archive member: '+name)
            names[name]=m
            if m.issym():links.add(name)
        if 'release.json' not in names:raise ValueError('Archive must contain a flat Switchboard release root')
        for name,m in names.items():
            parts=name.split('/')
            if any('/'.join(parts[:i]) in links for i in range(1,len(parts))):raise ValueError('Archive member beneath symlink: '+name)
            if m.issym():
                target=posixpath.normpath(posixpath.join(posixpath.dirname(name),m.linkname))
                if m.linkname.startswith('/') or target=='..' or target.startswith('../'):raise ValueError('Escaping archive symlink: '+name)
        # Explicitly validated members preserve their original modes. No extraction through links is possible.
        if hasattr(tarfile,'data_filter'):t.extractall(destination,filter='fully_trusted')
        else:t.extractall(destination)
    return pathlib.Path(destination)

def assemble(a):
    archive=pathlib.Path(a.archive);out=pathlib.Path(a.output_dir);out.mkdir(parents=True,exist_ok=True)
    if digest(archive)!=a.sha256:raise ValueError('Archive SHA-256 mismatch')
    if TARGET_TAGS.get(a.target)!=a.tag:raise ValueError('Actual target and bottle tag mismatch')
    formula=pathlib.Path(a.formula);wrapper=pathlib.Path(a.wrapper);strategy=pathlib.Path(a.strategy) if a.strategy else pathlib.Path(__file__).with_name('github_private_release_download_strategy.rb')
    if not strategy.exists() and 'require_relative "../lib/github_private_release_download_strategy"' in formula.read_text():raise ValueError('The embedded private formula requires a shared strategy file')
    receipt=json.loads(pathlib.Path(a.receipt).read_text())
    arch='arm64' if a.target.endswith('arm64') else 'x86_64'
    built_on=receipt.get('built_on',{});is_linux=a.target.startswith('linux-')
    if receipt.get('arch')!=arch or built_on.get('os')!=('Linux' if is_linux else 'Macintosh'):raise ValueError('Receipt must come from actual target Homebrew context')
    if is_linux:
        if not built_on.get('glibc_version'):raise ValueError('Actual Linux glibc metadata required')
    elif not re.match(r'^(?:macOS )?27(?:\.|$)',str(built_on.get('os_version',''))):
        raise ValueError('golden_gate bottle requires actual macOS 27 receipt')
    with tempfile.TemporaryDirectory(prefix='switchboard-bottle-',dir='/tmp') as folder:
        stage=pathlib.Path(folder);unpack=stage/'unpack';unpack.mkdir();source=extract_verified(archive,unpack)
        release=json.loads((source/'release.json').read_text());version=release['version']
        if release.get('application')!='switchboard' or version!='2.0.0' or release['target']!=a.target or release['source']['commit']!=SOURCE_COMMIT or release['source']['dirty'] is not False:raise ValueError('Wrong frozen release identity')
        if digest(source/'app/dist/switchboard.js')!=release['cli_sha256']:raise ValueError('Bundled CLI identity mismatch')
        build=json.loads((source/'app/dist/build.json').read_text())
        if build['version']!=version or build['source_sha256']!=release['source']['sha256']:raise ValueError('Build metadata identity mismatch')
        expected=inventory(source);counts=verify_payload(source,expected)
        keg=stage/'Cellar'/'switchboard'/version;keg.mkdir(parents=True);shutil.move(str(source),str(keg/'libexec'))
        (keg/'bin').mkdir();(keg/'.brew').mkdir()
        embedded_formula=keg/'.brew/switchboard.rb'
        embedded_formula.write_text(formula.read_text().replace('require_relative "../lib/github_private_release_download_strategy"','require_relative "lib/github_private_release_download_strategy"'))
        if strategy.exists():
            (keg/'.brew/lib').mkdir();shutil.copy2(strategy,keg/'.brew/lib/github_private_release_download_strategy.rb')
        shutil.copyfile(wrapper,keg/'bin/switchboard');(keg/'bin/switchboard').chmod(0o755)
        (keg/'INSTALL_HOMEBREW.md').write_text('Switchboard 2.0.0 — Homebrew\nCurrent instructions: https://github.com/qubicsdata/switchboard-distribution/blob/main/docs/installation.md\nUpgrade: brew upgrade qubicsdata/tap/switchboard\nOptional service: brew services start qubicsdata/tap/switchboard\n')
        receipt.update(arch=arch,compiler='none',built_prefix=str(stage),built_as_bottle=True,poured_from_bottle=False,changed_files=[],linkage_files=[],binary_relocation_files=[],source_modified_time=1,time=int(time.time()),runtime_dependencies=[],used_options=[],unused_options=[],aliases=[],installed_on_request=True,loaded_from_api=False,loaded_from_internal_api=False)
        receipt['source']={'tap':'qubicsdata/tap','tap_git_head':receipt.get('source',{}).get('tap_git_head'),'spec':'stable','path':'.brew/switchboard.rb','versions':{'stable':version,'head':None,'version_scheme':0,'compatibility_version':None}}
        receipt['qubicsdata_binary_assembly']={'mode':'untouched verified prebuilt archive; no compilation','archive':archive.name,'archive_sha256':a.sha256,'artifact_source_commit':SOURCE_COMMIT,'target':a.target,'bottle_tag':a.tag,'wrapper_sha256':digest(wrapper),'formula_sha256':digest(formula),'embedded_formula_sha256':digest(embedded_formula),'receipt_template_sha256':digest(pathlib.Path(a.receipt)),'receipt_metadata_origin':'actual target Homebrew host metadata; formula identity rewritten for verified prebuilt assembly','strategy_sha256':digest(strategy) if strategy.exists() else None}
        (keg/'INSTALL_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n');verify_payload(keg/'libexec',expected)
        dest=out/f'switchboard-{version}.{a.tag}.bottle.tar.gz'
        with tarfile.open(dest,'w:gz') as t:t.add(keg,arcname=f'switchboard/{version}')
        sha=digest(dest);(out/(dest.name+'.sha256')).write_text(sha+'  '+dest.name+'\n')
        payload={'inventoryVersion':1,'application':'switchboard','version':version,'target':a.target,'archiveSha256':a.sha256,'sourceCommit':SOURCE_COMMIT,'releaseId':release['release_id'],'entries':expected}
        payload_path=out/(dest.name+'.payload.json');payload_path.write_text(json.dumps(payload,indent=2,sort_keys=True)+'\n')
        report={'ok':True,'bottle':dest.name,'sha256':sha,'bytes':dest.stat().st_size,'target':a.target,'tag':a.tag,'cellar':'any_skip_relocation','assembly':'standard Homebrew bottle layout from verified unchanged prebuilt archive; no compilation','source_commit':SOURCE_COMMIT,'source_dirty':False,'archive_sha256':a.sha256,'release_id':release['release_id'],'source_sha256':release['source']['sha256'],'cli_sha256':release['cli_sha256'],'payload_inventory_sha256':digest(payload_path),'payload_counts':counts,'wrapper_sha256':digest(wrapper),'formula_sha256':digest(formula),'embedded_formula_sha256':digest(embedded_formula),'payload_verified_before_and_after_assembly':True,'built_on':built_on,'strategy_sha256':digest(strategy) if strategy.exists() else None,'method_sha256':digest(pathlib.Path(__file__)),'receipt_template_sha256':digest(pathlib.Path(a.receipt)),'installation_acceptance':'pending actual normal Homebrew pour/test; no assembly acceptance claim'}
        (out/(dest.name+'.assembly.json')).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for n in ['archive','sha256','target','tag','formula','receipt','wrapper','output-dir']:p.add_argument('--'+n)
    p.add_argument('--strategy');p.add_argument('--verify-payload');p.add_argument('--payload-inventory');a=p.parse_args()
    if a.verify_payload:
        data=json.loads(pathlib.Path(a.payload_inventory).read_text());counts=verify_payload(a.verify_payload,data['entries']);print(json.dumps({'ok':True,**counts,'archiveSha256':data['archiveSha256'],'sourceCommit':data['sourceCommit'],'target':data['target']}));return
    if any(getattr(a,n.replace('-','_')) is None for n in ['archive','sha256','target','tag','formula','receipt','wrapper','output-dir']):p.error('All assembly arguments are required')
    assemble(a)
if __name__=='__main__':main()
