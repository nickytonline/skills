---
name: browser-testing
description: Test and debug web interfaces with browser automation while minimizing context and token use. Use for frontend implementation, interaction checks, responsive testing, accessibility checks, visual verification, browser debugging, or requests to inspect a running web app. Prefer Playwright MCP for normal navigation and functional verification; use Chrome DevTools MCP only when low-level browser diagnostics are required.
---

# Browser Testing

Verify the requested behavior with the least browser output needed to reach a confident result.

## Choose the browser tool

Use Playwright MCP by default for:

- navigating and interacting with pages
- verifying links, buttons, forms, dialogs, menus, carousels, and keyboard behavior
- checking responsive behavior at specific viewport sizes
- inspecting accessible names, roles, and states
- taking a small number of final screenshots when visual evidence matters
- reproducing user flows and confirming acceptance criteria

Use Chrome DevTools MCP only when the task requires browser internals that Playwright cannot expose precisely enough:

- detailed network requests, response headers, timing, caching, or initiators
- JavaScript runtime state or execution debugging
- computed styles, cascade problems, layout geometry, or rendering internals
- performance, memory, or CPU traces
- deep console diagnostics or Chrome DevTools Protocol behavior

Do not switch to Chrome DevTools merely because it is available. Before escalating, state briefly what evidence is missing and why Playwright cannot provide it.

If Playwright MCP is unavailable, report that plainly. Do not silently substitute Chrome DevTools for routine interaction testing. Use an existing project test suite or ask before installing or changing tooling.

## Keep browser context small

1. Read the task's acceptance criteria and inspect the relevant source before opening a browser.
2. Test one focused flow at a time. Use the smallest relevant page, viewport, and state.
3. Prefer role, accessible name, label, or test ID locators over broad DOM inspection.
4. Request targeted accessibility snapshots or matching elements. Avoid repeated full-page snapshots.
5. Never dump `document.body.innerHTML`, full-page `outerHTML`, the complete DOM, or large serialized application state into the conversation.
6. Avoid arbitrary script evaluation when a normal Playwright action or assertion can answer the question.
7. Do not take screenshots after every action. Capture only states needed for visual comparison or final evidence.
8. Write large traces, screenshots, network exports, or diagnostic output to files when supported, then summarize only the relevant findings.
9. Reuse the current page and browser state when safe. Avoid reopening or reinspecting unchanged content.
10. Stop once the requested acceptance criteria are verified. Do not continue exploratory inspection without a concrete unresolved question.

## Verification loop

1. Define the smallest observable checks that prove the change works.
2. Use Playwright MCP to perform those checks.
3. Fix any issue in the source.
4. Re-run only the affected checks, then perform one concise final pass over the requested flow.
5. Report what passed, what failed, and any unverified limitation. Mention Chrome DevTools only if it was actually required.

For visual changes, verify both behavior and appearance. Prefer direct assertions for behavior and a final screenshot for appearance rather than using screenshots as the primary interaction mechanism.

## Chrome DevTools escalation rules

When Chrome DevTools is required:

- inspect the narrowest relevant element, request, log range, or trace window
- filter network and console output before returning it
- avoid repeated `evaluate_script` calls
- return scalar values or small structured objects from scripts, never whole DOM subtrees
- save verbose results to a file and summarize the decisive evidence
- return to Playwright for final user-flow verification after the low-level issue is fixed

## Report format

Keep the result concise:

- checks performed
- outcome
- any remaining limitation or follow-up

Do not narrate every browser action or paste raw browser output unless the user asks.
