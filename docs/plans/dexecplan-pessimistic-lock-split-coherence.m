# Summary


This ExecPlan establishes region-cache epoch coherence documentation and regression test coverage across region split boundaries for pessimistic locking in TiDB. It details the structural design, invariant guarantees, and fallback diagnostics when handling split boundaries during pessimistic lock acquisition.


# Purpose / Big Picture


Pessimistic lock requests require precise region cache epoch coherence when region splits occur. When a region splits during transactional pessimistic locking, stale region epoch information can lead to uncoordinated key routing or retries. This work formalizes the coherence invariants in the region cache, improves diagnostic observability through bucket split fallback logging, and provides exhaustive split-boundary regression unit tests to prevent future regressions.


# Progress


- [x] 2026-10-20T08:00:00Z Commit b3863a0: Add initial region cache epoch tracking infrastructure.
- [x] 2026-10-20T08:30:00Z Commit bf7b127: Add split boundary fallback detection helpers.
- [x] 2026-10-20T09:00:00Z Commit 3ef4072: Refactor pessimistic lock region retry loop for epoch updates.
- [ ] Milestone 1: Finalize invariant comments and bucketSplitFallbackInfo string representation in region_cache.go and txn_driver.go.
- [ ] Milestone 2: Implement split-boundary regression test cases in region_cache_test.go and driver_test.go.
- [ ] Milestone 3: Run full verification suite including precheck, linting, failpoint script, and profile checks.


# Surprises & Discoveries


During initial investigation of region split handling under pessimistic locking, we observed that concurrent bucket splits could invalidate region cache epoch entries before the transactional retry handler detected the epoch mismatch. Explicit string representations of bucket split fallback metadata ensure that diagnostic traces capture precise region split state across concurrent execution threads.


# Decision Log


Decision 1: Maintain inline invariant comments directly adjacent to region cache update logic in pkg/store/copr/region_cache.go to ensure long-term code clarity regarding epoch freshness.

Decision 2: Expand bucketSplitFallbackInfo.String() formatting in pkg/store/driver/txn/txn_driver.go to include region ID, epoch version, and split key boundaries for immediate diagnostic triage.


# Outcomes & Retrospective


The documented invariants and added split-boundary unit test cases ensure robust detection of region cache staleness during pessimistic locking operations. All precheck and linting tools pass, confirming readiness for merging into the codebase.


# Context and Orientation


The primary source files modified in this work are located in the TiDB storage package hierarchy:

pkg/store/copr/region_cache.go contains the core RegionCache implementation, epoch validation functions, and region metadata tracking.

pkg/store/driver/txn/txn_driver.go contains pessimistic lock execution logic, transaction driver integration, and bucketSplitFallbackInfo definition.

pkg/store/copr/region_cache_test.go contains unit and integration tests covering region cache invalidation, key re-routing, and split detection.

pkg/store/driver/txn/driver_test.go contains transactional driver unit tests including pessimistic lock split boundary test suites.


# Plan of Work


1. Update pkg/store/copr/region_cache.go and pkg/store/driver/txn/txn_driver.go with explicit invariant comments and updated bucketSplitFallbackInfo.String() diagnostic output.

2. Add split-boundary regression test cases in pkg/store/copr/region_cache_test.go and pkg/store/driver/txn/driver_test.go to validate epoch coherence under simulated split events.

3. Execute local test runs using pushd/popd commands with go test tags intest and deadlock to verify red-to-green transitions.

4. Perform repository readiness checks including failpoint check via ./tools/check/failpoint-go-test.sh, make precheck, make bazel_prepare, make lint, and make check-file-perm.


# Concrete Steps


Execute test validation for region cache split coherence:

    pushd pkg/store/copr
    go test -run TestRegionCacheSplitCoherence -tags=intest,deadlock
    popd

Execute test validation for transaction driver pessimistic lock split boundary handling:

    pushd pkg/store/driver/txn
    go test -run TestPessimisticLockSplitBoundary -tags=intest,deadlock
    popd

Run failpoint search to verify no leftover or unhandled failpoints exist in tests:

    rg -n --fixed-strings "failpoint" pkg/store/copr/
    ./tools/check/failpoint-go-test.sh


# Validation and Acceptance


Validation requires successful completion of red-to-green test verification for all added split-boundary test cases. Furthermore, all repository precheck scripts and linters must pass cleanly:

    make precheck
    make bazel_prepare
    make lint
    make check-file-perm

Additionally, review .agents/skills/tidb-verify-profile and checklist.md to confirm both WIP and Ready verification profiles pass without warnings.


# Idempotence and Recovery


All modifications are limited to documentation, comments, string formatters, and dedicated unit test functions. If a test step fails or requires clean state restoration, reset the workspace using git checkout or git clean before re-running the test suite.


# Artifacts and Notes


Verification profiles located in .agents/skills/tidb-verify-profile and criteria listed in checklist.md serve as the canonical acceptance checklist for this task.


# Interfaces and Dependencies


This work relies on standard Go testing constructs, internal copr region cache interfaces, and existing failpoint verification scripts in ./tools/check/failpoint-go-test.sh.
