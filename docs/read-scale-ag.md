# Read-scale availability groups on Kubernetes: a discussion

**Status: discussion and planning.**

## What I am trying to understand

Could this lab grow a second replica for read offloading? SQL Server availability groups (AGs) can be created
without a cluster manager using `CLUSTER_TYPE = NONE`. Such an AG is documented as a **read-scale** AG: it replicates
data to readable secondaries but provides no automatic failover and is not a high-availability solution.

## What it would need (as documented)

- An edition with readable secondaries. Developer edition has the feature but is non-production only.
- The HADR feature switched on in each instance. The container image has an environment variable for that (`MSSQL_ENABLE_HADR=1`).
- A database endpoint on each replica (conventionally TCP 5022) and a way for replicas to authenticate to each other. On Linux that means certificates exchanged between instances.
- Databases in the FULL recovery model with an initial full backup before they can join.
- `CREATE AVAILABILITY GROUP ... WITH (CLUSTER_TYPE = NONE)` on the primary, `ALTER AVAILABILITY GROUP ... JOIN WITH (CLUSTER_TYPE = NONE)` on the secondaries.

## How that maps onto Kubernetes (ideas)

- Two or more StatefulSet replicas, each with its own data PVC. Stable names like `sqlserver-0.sqlserver-headless` are a good fit for endpoint URLs.
- Port 5022 on the headless Service in addition to 1433.
- A Service per role: one that always points at the primary and one for readable secondaries. Because there is no cluster manager, nothing would update those selectors when the primary changes. Something (a person or a controller) would have to.
- Probes: the readiness probe in this repo only checks `SELECT 1`. A secondary and a primary both pass, which is wrong if a Service should only send writes to the primary.

## Failover without a cluster manager

With `CLUSTER_TYPE = NONE` a planned move is a manual sequence and an unplanned one is
`ALTER AVAILABILITY GROUP ... FORCE_FAILOVER_ALLOW_DATA_LOSS` on a secondary, which can lose transactions that were not
replicated. Kubernetes restarting the primary Pod does not fail over; it just brings the same replica back. So this design buys read scale, not availability.

## Reading from the secondary

Applications connect to the secondary replica directly. I do not know whether read-only routing via
`ApplicationIntent=ReadOnly` is usable without a listener in this configuration; my reading is that routing needs a listener,
which `CLUSTER_TYPE = NONE` does not have. This needs checking before anyone designs around it.

## Open questions

1. Does certificate rotation on a StatefulSet Pod restart need handling?
2. How does automatic seeding behave with a small PVC and a large database?
3. What is the licensing position of running secondaries in containers? (A question for whoever manages the licenses, not for me.)
4. Is an operator worth evaluating before hand-building any of this?

If high availability is the actual goal, this is the wrong tool; the documented HA path on Linux uses a cluster manager
and synchronous replicas, which is a different design from anything in this repo.
