# SQL Server 2025 notes

SQL Server 2025 became generally available on 2025-11-18. This lab still pins SQL Server 2022 cumulative update images
and nothing here has been tried on 2025.

## Plan for evaluating it

- Use a **separate StatefulSet and PVC** in a scratch namespace, not the 2022 one. Different data paths avoid any chance of an accidental in-place upgrade of the lab database.
- Find the image tag from the Microsoft Container Registry catalog instead of guessing it from the 2022 pattern (`2022-CU19-ubuntu-22.04`). The tools path inside the image (`mssql-tools18`) needs checking, which is the reason the probe script tries both locations.
- Restore a 2022 backup into the 2025 instance as a first test. Restoring forward should work; going back from 2025 to 2022 does not.
- Re-run `sql/restore-test.sql` and the memory queries as they are. The scripts only use features that exist in 2022.

## Features I want to read up on, not use yet

- Regular expression functions and a native `json` data type, from the release announcements. Neither is used in any script here, because the lab has to run on 2022.
- Changes to default encryption behaviour: the probes and jobs already pass `-C` to `sqlcmd`, but client connection strings may need review.

## Things to keep out of the 2022 scripts

Do not add 2025-only syntax to `sql/*.sql` until the lab moves to a 2025 image, otherwise the scripts stop working against the pinned 2022 image.
