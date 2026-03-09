# Accounts and the SA password

## Do not point applications at `sa`

`sa` is sysadmin on the instance. The lab uses it for the probes and the backup and restore-test Jobs because it
is the one login that exists on a fresh container, and that is a shortcut. `sql/create-app-login.sql` creates `lab_app`
with `db_datareader` and `db_datawriter` on `LabDb` for applications.

The backup Job still uses `sa`. I am not sure of the minimum permissions for `BACKUP DATABASE`, `RESTORE VERIFYONLY`
and the `msdb` reads in the restore test, and I would rather leave a known-working shortcut than ship a
permission set I guessed.

## Changing the SA password does not work the way you would hope

`MSSQL_SA_PASSWORD` is read when the container creates the `master` database, which is the first time it starts
with an empty data volume. On later starts the variable is ignored for the password. So:

- Editing the Secret and restarting the Pod does **not** change the password inside an existing database. The Pod's `SQLCMDPASSWORD` would then no longer match, and the probes would fail.
- To rotate it, change it in SQL Server first (`ALTER LOGIN sa WITH PASSWORD = N'...'`), then update the Secret, then restart the Pod so the environment variable is re-read.
- Environment variables from Secrets are fixed at container start, so every consumer needs a restart or a new Job run.

## The password in the script

`create-app-login.sql` substitutes the password into the script text with sqlcmd variables. It then appears in the
ConfigMap if you put the script in one, in the shell history, and possibly in server traces. For anything real, pass it some other way or change it right after creation.
