# Plans per milestone

One plan per milestone, numbered in order, worked through one by one, directly on `main`. A plan file is written when its milestone is picked up; the milestones themselves are in [`PLAN.md`](PLAN.md).

| Plan | Milestone | Status |
|---|---|---|
| [M0](M0-skeleton-ci.md) | Skeleton & CI | In progress |
| M1 | Spike: following the pointer | Todo |
| M2 | The stand-in while dragging, only if M1 is not smooth enough | Todo |
| M3 | Pairwise without plug-in | Todo |
| M4 | The plug-in, first in our own apps only | Todo |
| M5 | The plug-in public, only if Pairwise has users | Todo |

**Working method per plan:**
1. Read the plan, the ADRs it mentions and `docs/plans/PLAN.md`.
2. Tick off the tasks in the plan itself (`- [x]`) and commit them with the work.
3. If you make a new choice along the way, write an ADR first (`docs/decisions/`).
4. A plan is finished when all acceptance criteria are met and the tests are green. Then set the status above to **Done**.
