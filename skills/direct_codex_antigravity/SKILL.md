# Direct Codex and Antigravity

## Confirm the requirement and write a tight brief

- Use this skill only for code work in an existing local repository, such as a backtest codebase or a script the user already keeps locally.

- Use [App Creation](/opt/muse/skills/app-creation/SKILL.md) instead when the user wants a Muse artifact or a hosted builder app, page or tool for other people to use.

- Confirm the exact requirement with the user before you dispatch any agent.

- Write one brief that states the goal, the inputs, the files to change, the tests to run and the exact numbers or files to return.

- Keep the brief narrow enough for one Codex call and put review and fix cycles on Antigravity where possible.

- Tell Codex to write direct minimal code without excessive guards or repeated validation.

- Keep the Codex reasoning floor at medium and raise it only when the output quality is unsatisfactory.

- Ask for the result in a form you can check, such as test output and the changed files, before you report any number to the user.

## Run Codex once with the local safeguards

- Check whether bubblewrap is present on this machine before the first Codex call.

- If bubblewrap is missing, get approval for `--dangerously-bypass-approvals-and-sandbox` before you dispatch Codex and use it on the first call.

- Run Codex outside a git repository with `--skip-git-repo-check` and closed stdin with `< /dev/null` so it does not hang waiting for input.

- If bubblewrap is present, run the first call sandboxed and use the bypass flag only for a narrow retry after a sandbox failure and only when that retry is approved.

- Do not ask Codex to run local git commands on this machine when bubblewrap is missing.

- Treat a zero output call that still burns quota as a failed call and tighten the brief before any retry.

- Keep iterations minimal because Codex quota burns fast.

## Put review and fixes on Antigravity

- Send the Codex output to Antigravity for review, fixes and verification runs.

- Run Antigravity with `agy -p` and keep its default model unless the task needs a change.

- Do not use a Gemini API key for Antigravity because key use draws on a Cloud project quota rather than the Pro membership.

- If Antigravity login is needed, open the OAuth link in the shared browser or Safari because the Muse iOS app can intercept the link.

- Send any device code as a separate standalone message so the user can copy it easily.

## Verify the numbers and publish the result

- Run the tests yourself or through Antigravity and read the output before you report a result.

- Check every reported number against the test or backtest output and name anything that is still unresolved.

- Use the GitHub connector to push results after you confirm the repository exists and the Muse GitHub App has access to it.

- Keep a push small enough to avoid a request that is too large and leave regenerable data and large curve files out when the push would exceed the limit.

- Ask the user to create an empty repository in the browser when a new repository is needed because the Muse GitHub App cannot create one.

## Available connectors

- [GitHub](/opt/hatch/connectors/github/CONNECTOR.md) for repository access and pushing verified files.

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Validate a winning approach on new data or a new market before you tune a losing one.

- Split a large build into a small working core first and add the next piece only after the core passes its tests.

- Use Antigravity alone for a verification-only task when no new implementation is needed.
