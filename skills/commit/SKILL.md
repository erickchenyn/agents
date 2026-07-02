---
name: commit
description: Commit code, track PR status, and complete code merges
---

Follow the steps below strictly. Do not proceed to the next step until the current step has been completed or explicitly skipped.

## Commit Code And Open PR

- [ ] If the current branch is `main`, create a new feature branch first. The branch name must start with `chenyn-` and use kebab-case.
  - Do not commit directly to the `main` branch.
  - Do not use amend to modify an existing commit; create a new commit instead.
- [ ] The commit message must follow Angular Conventional Commits, use English, and omit the scope.
- [ ] Add the co-author trailer for the current agent at the end of the commit:
  - Use `Co-Authored-By: Claude <noreply@anthropic.com>` for Claude.
  - Use `Co-Authored-By: Codex <noreply@openai.com>` for Codex.
- [ ] After successfully creating the commit, push it to the remote automatically.
- [ ] If the branch does not have a corresponding PR yet, create a new PR and configure the feature branch to be deleted after merge.
  - If the current repo is a fork, open the PR against the upstream repo by default, not against the fork repo.
- [ ] If this change is related to an issue, link the issue to the PR.

## Track PR Status

- [ ] Make sure the PR has been created, then tell me the PR link.
- [ ] Track the PR checks and review status.
  - If any check fails:
    - [ ] Summarize the failed job for me first.
    - [ ] Fix the relevant errors based on the error messages, submit again by following the "Commit Code And Open PR" flow, then continue tracking the PR status.
  - If a review reports any serious issues:
    - [ ] Summarize the issues for me first.
    - [ ] Based on this PR's changes and context, which may be available through the linked issue in the PR description, decide whether the issue really exists, whether it is reasonable, and whether it needs to be fixed. Tell me your judgment and reasoning.
    - [ ] Confirm with the user whether to fix the issue or reject it. If the current environment provides an interactive prompt tool, use it; otherwise, ask directly in the conversation.
      - Fix: change the code to fix the issue, submit again by following the "Commit Code And Open PR" flow, then continue tracking the PR status.
      - Reject: dismiss the review through the relevant API and provide the rejection reason.
- [ ] Finally, make sure the PR checks and reviews have no remaining issues.
  - [ ] If a review reported serious issues and you have confirmed that the latest commit has fixed them, but the PR has a comment such as "skipped this review", you may add a comment for the corresponding reviewer to force a new review, such as `@claude` or `@codex review`. If the PR review has no issues, ignore this step.
  - [ ] After the latest deployment completes, tell me the preview environment link.

## Ask Whether To Track And Complete The Merge

- [ ] Confirm with the user whether to automatically merge the PR. If the user has already explicitly requested a merge, do not ask again.
  - No: your work is complete; skip all remaining steps.
  - Yes: continue with the following work.
    - [ ] Add the PR to the merge queue, or ensure that the PR is merged with squash merge or rebase merge.
      - When using squash merge, the merge commit body must include the summary of every commit in the PR.
      - When using squash merge, the merge commit body must preserve all `Co-Authored-By` trailers from every commit in the PR. Do not lose co-author information because of a custom `--body`.
    - [ ] Wait until the PR has been merged successfully, then confirm that the feature branch has been deleted from the remote.
    - [ ] If the PR is linked to an issue, close the issue.

## Notes

- Use the `gh` CLI to operate Git when inside a git repository.
- In the `moxt/paraflow` repository, the git user email must be `erick.chen@paraflow.com`.
