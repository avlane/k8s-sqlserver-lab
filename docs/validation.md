# What has been validated

## Run

- `kubectl kustomize .` renders the whole lab (namespace, Services, StatefulSet, PVC, ConfigMap, CronJobs, NetworkPolicy) with the
  generated `sql-scripts` ConfigMap. The tag from the kustomization appears in the StatefulSet and in both CronJobs. The restore-test Job is
  not part of the kustomization (it is applied on demand with `kubectl apply -f`), which is why `check_lab.py` compares its tag with the kustomization's.
  This uses the client-side kubectl only.
- `python3 scripts/check_lab.py` reports no problems.
- `python3 -m unittest discover -s tests` passes. It tests the checker, not the manifests.
