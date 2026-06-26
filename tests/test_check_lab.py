import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location("check_lab", ROOT / "scripts" / "check_lab.py")
check_lab = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(check_lab)


class CheckLabTests(unittest.TestCase):
    def copy_repo(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        shutil.copytree(ROOT / "manifests", root / "manifests")
        shutil.copy(ROOT / "kustomization.yaml", root / "kustomization.yaml")
        return root

    def edit(self, root, relative, old, new):
        path = root / relative
        text = path.read_text()
        self.assertIn(old, text)
        path.write_text(text.replace(old, new))

    def test_the_repository_is_consistent(self):
        self.assertEqual(check_lab.check(ROOT), [])

    def test_unknown_secret_key(self):
        root = self.copy_repo()
        self.edit(root, "manifests/backup-cronjob.yaml", "key: MSSQL_SA_PASSWORD", "key: NOT_THERE")
        problems = check_lab.check(root)
        self.assertTrue(any("has no key NOT_THERE" in p for p in problems), problems)

    def test_missing_pvc(self):
        root = self.copy_repo()
        self.edit(root, "manifests/sqlserver-statefulset.yaml", "claimName: sqlserver-backups", "claimName: elsewhere")
        problems = check_lab.check(root)
        self.assertTrue(any("claimName elsewhere" in p for p in problems), problems)

    def test_service_selector_mismatch(self):
        root = self.copy_repo()
        self.edit(root, "manifests/sqlserver-service.yaml", "    app: sqlserver\n  ports:\n    - name: sql\n      port: 1433\n      targetPort: 1433\n---",
                  "    app: other\n  ports:\n    - name: sql\n      port: 1433\n      targetPort: 1433\n---")
        problems = check_lab.check(root)
        self.assertTrue(any("selects app=other" in p for p in problems), problems)

    def test_cronjob_without_concurrency_policy(self):
        root = self.copy_repo()
        self.edit(root, "manifests/backup-cronjob.yaml", "  concurrencyPolicy: Forbid\n", "")
        problems = check_lab.check(root)
        self.assertTrue(any("without concurrencyPolicy" in p for p in problems), problems)

    def test_cronjob_without_time_zone(self):
        root = self.copy_repo()
        self.edit(root, "manifests/backup-log-cronjob.yaml", '  timeZone: "Etc/UTC"\n', "")
        problems = check_lab.check(root)
        self.assertTrue(any("without timeZone" in p for p in problems), problems)

    def test_image_tag_drift(self):
        root = self.copy_repo()
        self.edit(root, "manifests/restore-test-job.yaml", "2022-CU19-ubuntu-22.04", "2022-CU16-ubuntu-22.04")
        problems = check_lab.check(root)
        self.assertTrue(any("differs from the kustomization newTag" in p for p in problems), problems)

    def test_latest_tag(self):
        root = self.copy_repo()
        self.edit(root, "manifests/sqlserver-statefulset.yaml", "server:2022-CU19-ubuntu-22.04", "server:latest")
        problems = check_lab.check(root)
        self.assertTrue(any("not pinned" in p for p in problems), problems)


if __name__ == "__main__":
    unittest.main()
