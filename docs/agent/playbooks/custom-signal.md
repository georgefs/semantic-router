# Custom Signal Change Guide

This guide answers a narrow question: when you add or customize a signal in this repo, which files usually need to change?

The short version:

- `config/signal/**` holds the signal fragment itself.
- `src/semantic-router/pkg/**` changes only when the runtime, schema, or DSL contract must learn a new field or a new evaluation path.
- `website/docs/**` changes when the public catalog, tutorial pages, or examples should reflect the new signal.
- `e2e/**` changes when the new signal affects observable routing behavior.
- `dashboard/**` changes when the signal should be editable or visible in the UI.

## 1. The Canonical Signal Fragment

If you are adding a new signal or tuning an existing one, the first place to change is usually one of these files:

- `config/signal/<family>/<name>.yaml`
- `config/signal/<family>/*.yaml`

Examples in this repo:

- `config/signal/keyword/regex.yaml`
- `config/signal/structure/request-shape.yaml`
- `config/signal/embedding/support.yaml`
- `config/signal/jailbreak/patterns.yaml`

Use this layer for the actual routing rule definition:

- names
- thresholds
- keywords or candidate examples
- feature extraction settings
- family-specific parameters

If you are only adjusting the behavior of an existing signal and the contract does not change, this may be the only file that needs editing.

## 2. Runtime Evaluation

If the signal requires new runtime logic, update the classifier or signal-evaluation code under:

- `src/semantic-router/pkg/classification/**`
- `src/semantic-router/pkg/config/**`

Common cases:

- a new signal family needs a new evaluator
- an existing family needs a new feature type
- the signal emits new numeric values or confidences
- validation needs to understand a new field

Files in this area often include:

- `src/semantic-router/pkg/classification/classifier.go`
- family-specific helper files in `src/semantic-router/pkg/classification/`
- config model and validation files in `src/semantic-router/pkg/config/`

Rule of thumb:

- if the change affects how the router interprets the signal at request time, it belongs here
- if the change only edits example config, it probably does not

## 3. DSL and Canonical Config Translation

If the signal must round-trip through DSL, canonical YAML, or config translation, update the DSL and config contract code:

- `src/semantic-router/pkg/dsl/**`
- `src/semantic-router/pkg/config/**`

This becomes necessary when you:

- add a new signal field to the public config schema
- change how signal fragments are rendered or parsed
- need compiler or decompiler support for the new signal
- want the DSL and YAML forms to stay equivalent

Typical follow-up files are:

- DSL parser and compiler helpers
- config emitters and validators
- round-trip tests for YAML and DSL conversion

## 4. Docs And Examples

If the signal is new, user-facing docs should usually move with it.

Likely files:

- `website/docs/tutorials/signal/overview.md`
- `website/docs/tutorials/signal/heuristic/*.md`
- `website/docs/tutorials/signal/learned/*.md`
- `website/docs/overview/signal-driven-decisions.md`
- `website/docs/intro.md`
- `website/docs/api/crd-reference.md`

What to update:

- the signal catalog list
- the family classification, such as heuristic vs learned
- the config example for the new family
- any overview pages that enumerate supported signals

If the new signal is only an internal implementation detail and not a public capability, you may not need to touch the website docs.

## 5. Dashboard Surface

If the signal should be editable from the dashboard, update the dashboard config path as well:

- `dashboard/frontend/src/pages/ConfigPage.tsx`
- `dashboard/frontend/src/pages/ConfigPage*.tsx`
- `dashboard/frontend/src/components/**`
- `dashboard/backend/handlers/config.go`

Typical reasons:

- the config editor needs a new field
- the builder UI needs a new signal family
- the backend must accept or emit the new schema

If the signal is backend-only or is seeded through files, you can skip this layer.

## 6. Tests And E2E

Whenever the signal changes observable routing behavior, add or update tests.

Likely files:

- `src/semantic-router/pkg/classification/*_test.go`
- `src/semantic-router/pkg/config/*_test.go`
- `src/semantic-router/pkg/dsl/*_test.go`
- `e2e/testcases/**`
- `e2e/profiles/**`

Use tests to cover:

- the raw signal match
- the emitted confidence or signal values
- decision selection that consumes the signal
- any round-trip or schema validation behavior

If the new signal changes a user-visible route, add E2E coverage. That keeps the signal contract from drifting silently.

## 7. Practical Checklist

When you add a custom signal, decide which of these buckets apply:

1. Config only
   - edit `config/signal/<family>/<name>.yaml`
2. Config plus runtime
   - edit `config/signal/**`
   - edit `src/semantic-router/pkg/classification/**`
3. Config plus schema or DSL
   - edit `config/signal/**`
   - edit `src/semantic-router/pkg/config/**`
   - edit `src/semantic-router/pkg/dsl/**`
4. Public signal catalog update
   - edit the config files above
   - edit `website/docs/tutorials/signal/**`
   - edit `website/docs/overview/signal-driven-decisions.md`
5. UI-exposed signal
   - edit the config files above
   - edit dashboard frontend and backend files
6. Behavior-visible change
   - add or update tests
   - add or update E2E coverage

## 8. Quick Rule

- If you are only tuning a known signal family, touch the family YAML and the nearest tests.
- If you are adding a new signal family, expect changes in config, runtime, docs, and tests.
- If the signal must appear in the dashboard or DSL, add the UI and translation layers too.

## 9. Repo Examples

Signals already in this repo include families such as:

- `keyword`
- `structure`
- `context`
- `embedding`
- `domain`
- `language`
- `jailbreak`
- `pii`
- `fact-check`
- `preference`
- `reask`
- `kb`
- `modality`

Use the existing files under `config/signal/**` and `website/docs/tutorials/signal/**` as the best pattern for how new signal families should be wired.
