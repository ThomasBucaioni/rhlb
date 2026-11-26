#!/usr/bin/env python3
import argparse, ipaddress, json, re
from pathlib import Path
ROOT = Path(__file__).resolve().parent

def generate(profile, keyfile, output):
    p = json.loads((ROOT / profile / 'vm.json').read_text())
    for field in ('hostname','interface','user'):
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]*', p[field]):
            raise ValueError(f'Invalid {field}')
    if not re.fullmatch(r'[a-z_][a-z0-9_-]*', p['user']):
        raise ValueError('Invalid username')
    addr = ipaddress.IPv4Interface(p['address'])
    key = Path(keyfile).expanduser().read_text().strip()
    if not re.fullmatch(r'(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(?:256|384|521)) [A-Za-z0-9+/=]+(?: [^\r\n"\\]*)?', key):
        raise ValueError('Expected one OpenSSH public key')
    packages = p.get('packages', [])
    if any(not re.fullmatch(r'[A-Za-z0-9@+_.-]+', x) for x in packages):
        raise ValueError('Invalid package name')
    post = (ROOT / 'common/post-install.sh').read_text()
    values = dict(HOSTNAME=p['hostname'], INTERFACE=p['interface'], USER=p['user'], IP=str(addr.ip), NETMASK=str(addr.netmask), GATEWAY=str(ipaddress.IPv4Address(p['gateway'])), DNS=','.join(str(ipaddress.IPv4Address(x)) for x in p['dns']), SSH_KEY=key, VM_PACKAGES='\n'.join(packages), POST_INSTALL=post.replace('@@USER@@',p['user']))
    template = (ROOT / 'common/common.ks.cfg').read_text()
    result = re.sub(r'@@([A-Z_]+)@@', lambda m: values[m[1]], template)
    output = Path(output); output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(result); return output

if __name__ == '__main__':
    a=argparse.ArgumentParser(); a.add_argument('profile', choices=[p.parent.name for p in ROOT.glob('*/vm.json')]); a.add_argument('--ssh-key', required=True); a.add_argument('--output', type=Path); args=a.parse_args()
    print(generate(args.profile,args.ssh_key,args.output or ROOT/'build'/f'{args.profile}.ks.cfg'))
