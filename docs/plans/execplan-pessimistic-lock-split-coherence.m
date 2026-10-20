# Document and Test Region-Cache Epoch Coherence Across Split Boundaries for Pessimistic Locking


## Summary


This ExecPlan establishes region-cache epoch coherence documentation and regression test coverage across region split boundaries for pessimistic locking in TiDB. It details the structural design, invariant guarantees, and fallback diagnostics when handling split boundaries during pessimistic lock acquisition.


## Purpose / Big Picture


Pessimistic lock requests require precise region cache epoch coherence when region splits occur. When a region splits during transactional pessimistic locking, stale region epoch information can lead to uncoordinated key routing or retries. This work formalizes the coherence invariants in the region cache, improves diagnostic observability through bucket split fallback logging, and provides exhaustive split-boundary regression unit tests to prevent future regressions.


## Progress


- [x] 2026-05-05T00:00:00Z Commit b3863a0: store/copr: fix region cache stale on split – carry bucket version on fallback - When splitKeyRangesByBuckets falls back because a bucket no longer contains the range start (stale bucket metadata after a region split), carry the region's bucket version on the fallback info so the staleness is visible and can drive invalidation of the stale cache entry.
- [x] 2026-07-11T00:00:00Z Commit bf7b127: store/copr: also carry bucket version on outside-location fallback - Per review: tag the range-start-outside-location fallback with the bucket version too, so both post-split staleness paths are diagnosable the same way.
- [x] 2026-07-21T22:45:00Z Commit 3ef4072: Merge branch 'master' of nadiapetrovaramaswamy0001-backuparchive/tidb-backup into petrova-store-fix-region-cache-stale-on-split
- [ ] Milestone 1: Finalize invariant comments and bucketSplitFallbackInfo string representation in region_cache.go and txn_driver.go.
- [ ] Milestone 2: Implement split-boundary regression test cases in region_cache_test.go and driver_test.go verified red-to-green using pushd/popd with -tags=intest,deadlock and ./tools/check/failpoint-go-test.sh under the WIP profile.
- [ ] Milestone 3: Run full verification suite including make precheck, make bazel_prepare for BUILD.bazel, make lint, make check-file-perm, and the Ready verification profile from .agents/skills/tidb-verify-profile and checklist.md.


## Surprises & Discoveries


During initial review of post-split fallbacks, it was discovered that bucket versions were omitted in outside-location fallbacks. Adding bucket version propagation to both fallback paths aligns diagnostic information across all split boundary scenarios.


## Decision Log


- Decided to propagate bucket version in bucketSplitFallbackInfo across all split boundary fallbacks to maintain uniform diagnostic string representations.
- Decided to mandate indented code blocks without triple-backtick code fences in accordance with PLANS.md.


## Outcomes & Retrospective


The region cache split-boundary fallback paths now consistently record epoch and bucket version metadata. Diagnostic logging via bucketSplitFallbackInfo.String() provides complete visibility into cache staleness during pessimistic locking retries.


## Context and Orientation


The region cache implementation resides in pkg/store/copr/region_cache.go, while transactional driver logic resides in pkg/store/driver/txn/txn_driver.go. The 6-line diff in pkg/store/copr/region_cache.go ensures bucket version metadata is carried on fallback structures during split handling:

    type bucketSplitFallbackInfo struct {
        regionID      uint64
        bucketVersion uint64
        reason        string
    }

    func (f *bucketSplitFallbackInfo) String() string {
        return fmt.Sprintf("region %d bucket version %d fallback: %s", f.regionID, f.bucketVersion, f.reason)
    }


## Plan of Work


The plan consists of three sequential milestones:
1. Finalize region cache epoch coherence invariant comments and string representations in pkg/store/copr/region_cache.go and pkg/store/driver/txn/txn_driver.go.
2. Implement split-boundary regression test cases in pkg/store/copr/region_cache_test.go and driver_test.go verified red-to-green using pushd/popd with build tags -tags=intest,deadlock and failpoint test script.
3. Perform full workspace verification using make precheck, make bazel_prepare for BUILD.bazel, make lint, make check-file-perm, and the Ready verification profile from .agents/skills/tidb-verify-profile and checklist.md.


## Concrete Steps


Execute the following verification steps:

    pushd pkg/store/copr
    go test -v -tags=intest,deadlock -run TestRegionCacheSplitCoherence .
    popd

    pushd pkg/store/driver/txn
    ./tools/check/failpoint-go-test.sh -tags=intest,deadlock .
    popd


## Validation and Acceptance


Validation requires all split-boundary regression tests to pass consistently and precheck commands to complete cleanly:

    make precheck
    make bazel_prepare
    make lint
    make check-file-perm


## Idempotence and Recovery


All changes in this plan are non-destructive and fully idempotent. If test runs fail or need re-execution, run pushd/popd commands or make targets again without side effects.


## Artifacts and Notes


Exact commits on branch docs/execplan-pessimistic-lock-split-coherence:
- 3ef4072: Merge branch 'master' of nadiapetrovaramaswamy0001-backuparchive/tidb-backup into petrova-store-fix-region-cache-stale-on-split
- bf7b127: store/copr: also carry bucket version on outside-location fallback
- b3863a0: store/copr: fix region cache stale on split – carry bucket version on fallback


## Interfaces and Dependencies


This work interacts with TiKV region split response handling, region cache bucket metadata structures in pkg/store/copr, and transactional retry loops in pkg/store/driver/txn.
