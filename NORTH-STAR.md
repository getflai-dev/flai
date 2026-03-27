# FlAI North Star

> Every agent reads this file every run. This is why we exist and what we're building toward.

## Mission

Make FlAI the default way Flutter developers add AI chat to their apps.

## What FlAI Is

An open-source, shadcn/ui-style component library for Flutter focused on AI chat interfaces. Developers install components as source code via CLI — they own every line. No package lock-in, no fighting someone else's API surface.

## Who It's For

Flutter developers building AI-powered apps — from solo devs shipping side projects to startup teams building production chat products. Anyone who's ever Googled "flutter ai chat streaming" and found nothing good.

## The Problem We Solve

Building AI chat in Flutter today means writing 2000+ lines of custom SSE parsing and widget code before touching your actual product. Existing options are either general chat UI with no AI features, or packages you don't own. In React this is a weekend project. In Flutter it's a month. FlAI makes it a weekend project in Flutter too.

## Where We're Going

**Phase 1 (Now):** Best-in-class AI chat components — streaming, thinking, tool calls, citations, voice. Works with any AI provider (OpenAI, Anthropic, Google, etc.) and any backend.

**Phase 2 (Next):** Backend-agnostic quick-start. One command to wire up Firebase, Supabase, CMMD, or your own backend. `flai connect firebase` / `flai connect cmmd` / `flai connect supabase`.

**Phase 3 (Future):** Developer experience layer. Built-in analytics (PostHog auto-connection), usage tracking, A/B testing for AI features, error monitoring — all pre-wired into components. The goal: every FlAI component ships with observability out of the box.

## Key Differentiator

**You own the code.** Every other Flutter chat package is a black box you import. FlAI gives you the source. When AI capabilities change (and they change weekly), you're not waiting on a package maintainer. You just edit your code.

## KPIs — What Success Looks Like

- **GitHub stars** — community signal, social proof, discoverability
- **pub.dev downloads** — adoption metric for the CLI and any published helpers
- **CLI installs** — `flai init` and `flai add` usage (npm for the CLI, pub.dev for Dart)
- **Daily active usage** — developers actively building with FlAI components
- **Community contributions** — PRs, issues, discussions from real users

## What Drives Every Decision

1. **Developer experience first.** If it's not easy, it's not shipping.
2. **AI-first, not chat-first.** We build for streaming, thinking, tool calls — not just message bubbles.
3. **Own your code.** Never lock developers into our abstractions.
4. **Provider-agnostic.** Support every AI provider and every backend. Don't pick sides.
5. **Community-driven.** Open source, open roadmap, open to contributions.

## How This Applies to Each Agent

- **Social Media Manager:** Every post should reinforce "you own the code" and "AI-first Flutter components." Speak to developers who've felt the pain of building AI chat from scratch.
- **Growth Analyst:** Track GitHub stars, pub.dev stats, CLI downloads, community mentions. Find communities where Flutter devs are struggling with AI chat.
- **Designer:** Visuals should feel like developer tools — dark, clean, code-forward. Show real Flutter code and real chat UIs.
- **Developer:** Prioritize DX. Every component should be easy to install, easy to customize, easy to understand. Write code that developers want to read.
- **DevRel:** Tutorials should get someone from zero to working AI chat in under 10 minutes. That's the bar.
- **Product Manager:** Feature requests get evaluated against: does this make AI chat in Flutter easier? Does this keep developers in control of their code?
- **Chief of Staff:** When prioritizing across teams, weight toward things that drive stars, downloads, and community engagement.
