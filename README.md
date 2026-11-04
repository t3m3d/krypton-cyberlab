# Krypton CyberLab

Native macOS cybersecurity investigation practice, built with **Krypton, Objective-K / OKUI, and KryptScript**. The separate browser prototype is preserved for later development. Nothing is deployed.

## Run the native app

Requires macOS 14+ on Apple silicon and the Krypton toolchain (`kcc` / `kr`, locally tested with 2.4.8). From this repository:

```sh
kr build.ks test
open "dist/Krypton CyberLab.app"
```

`kr build.ks` builds and verifies the app without running tests. `kr build.ks run` builds and opens it. `KCC` can specify an alternate absolute compiler path; the default is `/usr/local/bin/kcc`. The build uses macOS `codesign` for a local ad-hoc signature, not distribution signing or notarization. No C, Objective-C, Swift, JavaScript, WebView, or web server is part of the native application. Objective-K calls Apple's AppKit and Foundation system libraries.

The generated app is self-contained and does not require the compiler to run. Keep it in `dist/` during development; installation and public distribution are later work.

## Appearance

Open **Settings** from the sidebar or press **⌘,**. The Appearance selector offers **Follow macOS**, **Light**, and **Dark**. Follow macOS is the default and updates when the system appearance changes. Overrides are saved locally without changing investigation completion or report text. Light mode uses a muted lavender canvas, lilac cards, and softer editors instead of white surfaces. Both palettes cover cards, evidence records, report editors, native controls, and feedback panels.

## First release

Three complete, fictional investigations:

- **Account compromise — Aster Healthworks:** correlate an unfamiliar session, mailbox access, and a forwarding rule before payroll. Distinguish likely account misuse from confirmed forwarding or financial loss.
- **Phishing — Juniper Design Co.:** inspect supplier impersonation and authentication headers, scope deliveries and a link visit, and investigate possible credential exposure without assuming theft.
- **Endpoint activity — Meridian Research:** reconstruct a document/process/task/connection chain, assess persistence and collection gaps, and coordinate recovery around a research handoff.

Each case includes six records, assessed observations, notes, a manually ordered timeline with chronological sorting, three response decisions with optional hints and authored explanations, six report sections, a full case debrief, and a sample synthesis. The evidence portfolio exports Markdown reports. The skill dashboard shows structured practice results and directs you to revisit mismatches.

Report sections: executive summary, confirmed technical findings, assumptions/open questions, business impact, response/recovery, and follow-up/lessons. Citation format is `[A1]`, `[P1]`, or `[E1]` for the relevant case.

**All functionality is simulated.** Records are static; actions never execute commands, isolate endpoints, contact accounts, block traffic, send email, or visit evidence URLs. All organizations and people are fictional. Sample domains and IP addresses are training placeholders.

## Assessment and saved progress

The app compares observation classifications and response choices against case-specific authored guidance. Completion requires reviewed/classified evidence, a populated timeline, checked decisions with written rationales, six report sections, and at least two distinct valid evidence citations. Perfect answers are not required. Changes reopen the case for review.

**Free-text notes, rationales, and reports are not semantically graded.** Citation/completion checks cannot validate the truth, quality, or completeness of the narrative. Self-review prompts and sample syntheses support deeper analysis. Scores are learning signals, not certification or proof of professional competence.

Progress uses an atomically written property-list file at `~/Library/Application Support/Krypton CyberLab/progress-v1.plist`, with versioned per-case keys. Failed writes show a visible session-only warning. Notes and report writing save through native text-change notifications; navigation and quit flush pending edits. There is no account, cloud sync, telemetry, network API, or automatic native/browser synchronization. Export a report to keep a portable copy. Resetting a case requires a native confirmation and leaves other cases intact.

## Project structure

```text
src/main.ks          Native application, state, response logic, UI and self-tests
src/curriculum.k     Embedded authored fictional case data; no imported mutable state
build.ks             KryptScript build, bundle, signature verification and test runner
site/lab.htk         Krypton htmk draft for krypton-lang.org/lab.html
site/lab.html        Generated local website draft (not published)
web/                 Preserved standalone browser implementation and tests
docs/                Architecture, scope and verification notes
```

The native code follows the existing Cortex and Code Brain pattern: mutable state and callbacks stay in one entry point because the current toolchain has import-boundary limitations. Imported curriculum contains functions only. UI uses OKUI and direct Objective-K AppKit messages; native object identifiers are not compared with generic text equality. Evidence is always displayed as inert text.

## Checks

```sh
kr build.ks test
# Or test an already built bundle:
"dist/Krypton CyberLab.app/Contents/MacOS/KryptonCyberLab" --selftest
```

Native self-tests use a unique temporary progress file; they do not read or overwrite learning progress. They exercise all three cases, timeline mutation and chronology, structured assessments, completion gates, citation checks, exported content, Unicode/multiline persistence, native editing, disk reload, actual button callbacks, and rendering all screens. Native integration checks need access to the logged-in macOS window services.

## Preserved browser version

```sh
cd web
npm run dev
# http://localhost:5173
npm run check
npm test
```

The browser version uses plain JavaScript and CSS, with no runtime dependencies. It saves to that browser's local storage, supports responsive layouts, and exports Markdown. It remains a separate prototype for possible later deployment; native macOS is the primary app. No public deployment or native iPhone build is included.

## Website preparation

`site/lab.htk` is a standalone draft for the requested `krypton-lang.org/lab.html`. It follows the existing site's htmk static export approach. Generate a local preview:

```sh
kcc -r site/lab.htk /tmp/krypton-cyberlab-lab.html
```

The draft labels the project as local development and has no invented release/download link. Integration into the main Krypton site's exporter, navigation, release downloads, and live publishing remains a separate release step. The sibling language/site repository has not been modified.

See [verification notes](docs/verification.md) for the checks performed and remaining limits.

## Next scope

Network diagrams and firewall/access reviews; risk and governance cases; control investment decisions; richer evidence-portfolio artifacts; isolated hands-on labs; secure-code review. These are explicitly future modules. NIST NICE and MITRE ATT&CK mappings require official-source verification before inclusion; no mappings are claimed in this release.
