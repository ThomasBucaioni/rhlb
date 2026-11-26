#!/usr/bin/env python3
import argparse, json, subprocess, sys, shlex
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def run(*args):
    return subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE).stdout

def main():
    a=argparse.ArgumentParser(); a.add_argument('profile',choices=[p.parent.name for p in ROOT.glob('*/vm.json')]); a.add_argument('--ssh-key',required=True); a.add_argument('--iso',required=True); a.add_argument('--pool',default='vmdata'); a.add_argument('--bridge',default='br0'); a.add_argument('--apply',action='store_true'); x=a.parse_args()
    p=json.loads((ROOT/x.profile/'vm.json').read_text()); name=x.profile
    iso=Path(x.iso).resolve(); ks=ROOT/'build'/f'{name}.ks.cfg'
    run(sys.executable,str(ROOT/'generate-ks.py'),name,'--ssh-key',x.ssh_key,'--output',str(ks))
    cmd=['virt-install','--connect','qemu:///system','--name',name,'--memory',str(p['memory_mib']),'--vcpus',str(p['vcpus']),'--disk',f'pool={x.pool},size={p["disk_gib"]},format=qcow2,bus=virtio','--network',f'bridge={x.bridge},model=virtio','--osinfo','rhel10.0','--location',str(iso),'--initrd-inject',str(ks),'--extra-args',f'inst.ks=file:/{ks.name} console=ttyS0,115200n8','--graphics','none','--noautoconsole']
    print(shlex.join(cmd),flush=True)
    if not x.apply: return
    if not iso.is_file(): raise SystemExit('ISO not found')
    run('ksvalidator','-v','RHEL10',str(ks))
    v=['virsh','-c','qemu:///system']
    if name in run(*v,'list','--all','--name').splitlines(): raise SystemExit('Domain already exists')
    run(*v,'pool-info',x.pool); run(*v,'pool-refresh',x.pool)
    if any(n.startswith(name+'.') or n==name for n in [line.split()[0] for line in run(*v,'vol-list',x.pool).splitlines()[2:] if line.split()]): raise SystemExit('Potential existing VM volume')
    subprocess.run(cmd,check=True)
if __name__=='__main__': main()
