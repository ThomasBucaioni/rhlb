import importlib.util, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('generator',ROOT/'generate-ks.py'); g=importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
class Generation(unittest.TestCase):
    def test_profiles(self):
        with tempfile.TemporaryDirectory() as d:
            key=Path(d)/'key.pub'; key.write_text('ssh-ed25519 AAAA test')
            for p in ROOT.glob('*/vm.json'):
                out=g.generate(p.parent.name,key,Path(d)/'out'); s=out.read_text(); self.assertNotIn('@@',s); self.assertIn('selinux --enforcing',s); self.assertIn('sshkey --username=user',s)
