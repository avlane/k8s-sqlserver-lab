# Upgrading SQL Server in this lab

The version is the image tag in `kustomization.yaml` (`images:`). The backup CronJob and the restore-test Job use
the same image name, so they follow it.

## Procedure I would follow

1. Take a backup and run the restore test. Confirm the Job succeeded.
2. Read the cumulative update's release notes for the new tag.
3. Change `newTag`, render with `kubectl kustomize .`, and look at the diff (`kubectl diff -k .` needs a cluster).
4. `kubectl apply -k .`. The StatefulSet restarts `sqlserver-0` (there is one replica, so this is **downtime**: the Pod stops, the new one starts, runs its upgrade scripts and only then becomes Ready).
5. Watch `kubectl -n sqllab logs -f sqlserver-0` for the "Database ... upgrade" messages, and wait for the Pod to be Ready.
6. Run the backup and restore test again.

## Things that bite

- **No downgrade.** Once user databases have been upgraded by a newer build you cannot attach or restore them on an older one. Rolling back means restoring the pre-upgrade backup onto the old image.
- **The startup probe has to be generous.** Upgrade scripts can take much longer than a normal start; `failureThreshold: 30` at 10 seconds is five minutes, so raise it for big databases or the Pod will be killed mid-upgrade.
- **Pin tags.** Moving from one cumulative update to the next is a deliberate change. `latest` or a floating tag would upgrade on any Pod reschedule.
- A new major version (2022 to a later release) is an in-place upgrade of the data files on the PVC at first start. Try it on a copy.
