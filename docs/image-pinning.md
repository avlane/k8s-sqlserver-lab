# Pinning the image

The manifests pin a cumulative-update **tag** (`2022-CU19-ubuntu-22.04`). A tag can be re-pushed to point at different
content (rebuilds for base-image fixes happen), so it is a good name but not an immutable one. A **digest** is.

    image: mcr.microsoft.com/mssql/server@sha256:<digest>

How to get the digest of a tag, when you have a working registry client: `docker buildx imagetools inspect mcr.microsoft.com/mssql/server:2022-CU19-ubuntu-22.04`
prints it, as does `crane digest ...`.

Trade-offs:

- A digest makes rollouts reproducible and stops surprise changes, but a bare digest hides which cumulative update it is. Keep the tag as a comment, or use `tag@digest` (the registry then checks the digest and the tag is informational).
- Security updates to the base image only arrive when you change the digest on purpose, so you need a process for that.
- The `images:` block in `kustomization.yaml` can set `digest:` instead of `newTag:`.

I have kept tags for readability. Moving to digests would be a one-line change in the kustomization plus the same change in the manifests that `scripts/check_lab.py` compares against.
