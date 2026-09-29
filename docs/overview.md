# Overview

## Goals

1. Run a single SQL Server 2022 instance on Kubernetes with its data on a PersistentVolume.
2. Understand why each setting is there: the EULA variable, the SA password, `fsGroup`, memory limits.
3. Take backups with a CronJob and prove they restore with a Job.
4. Write down what goes wrong, and what I still do not know.

## Out of scope for now

- Anything multi-node. The read-scale availability group discussion (later) is reading, not a build.
- Production concerns such as licensing audits, TLS certificates from a real CA, monitoring and off-cluster backup copies.
- Operators. This lab uses plain StatefulSets so every field is visible.

## Image

The lab uses `mcr.microsoft.com/mssql/server` with an explicit cumulative-update tag such as
`2022-CU15-ubuntu-22.04`. The `latest` tag is avoided on purpose: for a database an unplanned engine
upgrade on a Pod restart is a surprise nobody wants. Tags are pinned to ones that existed on the date of each commit.

## Image tags over time

The commit history shows these bumps (dates are those of the commits in this repository, not Microsoft's release dates):

| change | tag |
|---|---|
| first StatefulSet | `2022-CU15-ubuntu-22.04` |
| March 2025 | `2022-CU16-ubuntu-22.04` |
| April 2025 (moved into `kustomization.yaml`) | `2022-CU17-ubuntu-22.04` |
| September 2025 | `2022-CU19-ubuntu-22.04` |

Cumulative updates after CU19 exist and the lab has not moved to them. SQL Server 2025 is covered in `sql-server-2025.md`.
