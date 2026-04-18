# FlAI Project Roadmap — Linear Plan

## Phase 0: MVP Ship (Sprint 1 — URGENT)
> Goal: `flai init → flai add app_scaffold → flai connect cmmd → flutter run` works perfectly. User can create a chat and talk to an AI assistant.

### CDT-001: Fix CHANGELOG for pub.dev publish
**Priority:** Urgent | **Labels:** cli, release
**Description:** `dart pub publish --dry-run` warns that CHANGELOG.md doesn't mention version 0.3.0. The [Unreleased] section exists but the v0.3.0 entry needs to be before [Unreleased], not after it. Fix the ordering in CHANGELOG.md so the dry-run passes cleanly, then re-tag v0.3.0 and push to trigger the release workflow.
**Acceptance criteria:**
- `cd packages/flai_cli && dart pub publish --dry-run` exits with 0 warnings
- Release workflow publishes to pub.dev successfully
- `dart pub global activate flai_cli` installs v0.3.0
**Files:** `CHANGELOG.md`, `.github/workflows/release.yml`

### CDT-002: Validate all 16 Maestro E2E tests on simulator
**Priority:** Urgent | **Labels:** testing, qa
**Description:** We have 16 Maestro E2E test files in `example/.maestro/` but none have been verified as passing. Boot the iOS simulator, build the example app, and run every test. Fix any failures. Tests require CMMD production credentials passed via `-e FLAI_TEST_EMAIL=... -e FLAI_TEST_PASSWORD=...` (stored in `.maestro/.env`).
**Acceptance criteria:**
- All 16 tests pass: chat_flow, sidebar, logout, session, markdown, rename, voice, forgot_password, tool_calls, citations, share, send_button, attachment, login_flow
- Any flaky tests documented with workarounds
- Screenshot artifacts saved for each test
**Files:** `example/.maestro/*.yaml`
**Commands:** `cd example && maestro test .maestro/ -e FLAI_TEST_EMAIL=$EMAIL -e FLAI_TEST_PASSWORD=$PASS`

### CDT-003: Wire attachment flow end-to-end (files → AI provider)
**Priority:** High | **Labels:** feature, chat
**Description:** The attachment UI is complete (picker, preview thumbnails, remove button) but picked files are NOT sent to the AI. The composer sends `[attachment]` placeholder text instead of actual image data. Wire the full flow:
1. `FlaiComposerV2` stores `List<PickedAttachment>` in state (already done)
2. On send, convert `PickedAttachment` to `Attachment` model objects with base64 file data
3. Pass attachments through `FlaiChatContent.onSend` → `HomeController.sendMessage`
4. `HomeController` includes attachments in the `ChatRequest` (add `attachments` field to `ChatRequest`)
5. `CmmdAiProvider` sends image data in the API request body (multipart or base64)
6. Display sent attachments in the user's `MessageBubble`
**Acceptance criteria:**
- User can pick a photo, see thumbnail preview, send message with photo attached
- AI responds acknowledging the image content (vision)
- Sent message shows the image inline in the chat
**Files:** `composer_v2.dart`, `home_controller.dart`, `chat_content.dart`, `chat_request.dart`, `cmmd_ai_provider.dart`, `message_bubble.dart`

### CDT-004: Validate session persistence on cold restart
**Priority:** High | **Labels:** auth, testing
**Description:** `SecureAuthStorage` persists tokens to iOS Keychain and restores them on app launch. Verify this works:
1. Login to the app
2. Force-kill the app (swipe up from app switcher)
3. Relaunch — should skip login and go straight to home
4. Verify conversations are loaded from the server
5. Test on both simulator and real device if available
**Acceptance criteria:**
- Session survives cold restart
- Token refresh works if access token expired
- Clear keychain properly logs out user
**Files:** `core/secure_auth_storage.dart`, `app.dart`

### CDT-005: Clean room CLI pipeline test on real device
**Priority:** High | **Labels:** cli, testing
**Description:** Run the complete CLI pipeline from scratch and verify the app runs on a real iOS device (or simulator):
1. `flutter create test_app && cd test_app`
2. `flai init --app-name "Test App" --assistant-name "Nova" --theme dark`
3. `flai add app_scaffold`
4. `flutter pub get`
5. `flutter run` — verify app launches with login screen
6. `flai connect cmmd`
7. `flutter pub get && flutter run` — verify app connects to CMMD, can login, send messages
**Acceptance criteria:**
- App compiles with 0 errors on both steps
- Login works with real CMMD credentials
- Can send a message and receive AI response
- Voice mic button appears in composer
**Commands:** See description steps

---

## Phase 1: Voice-First Experience (Sprint 2)
> Goal: Perfect the conversational voice mode. Users will primarily use this hands-free in their car. This is the key differentiator.

### CDT-006: Polish push-to-talk voice UX
**Priority:** Urgent | **Labels:** voice, ux
**Description:** The inline push-to-talk flow works (mic → waveform → transcript → send) but needs polish for real-world car use:
1. Increase waveform visibility (thicker bars, higher contrast)
2. Add audio feedback (subtle haptic on recording start/stop)
3. Auto-send after transcript arrives (optional config flag `autoSendVoice`)
4. Show recording duration prominently (larger timer text)
5. Handle edge cases: no mic permission, background noise rejection, very short recordings
**Acceptance criteria:**
- Recording starts instantly on mic tap (< 100ms)
- Transcript populates text field within 2s of stopping
- If `autoSendVoice: true`, message sends automatically after transcript
- Haptic feedback on start and stop
**Files:** `composer_v2.dart`, `voice_controller.dart`, `chat_experience_config.dart`

### CDT-007: Full-screen voice conversation mode
**Priority:** Urgent | **Labels:** voice, feature
**Description:** The `VoiceConversationOverlay` exists but needs to be fully wired and polished for hands-free car use:
1. Launch from a long-press on the mic button (or a dedicated voice mode button)
2. Full-screen overlay with animated orb/waveform visualization
3. Continuous listen → transcribe → send → AI responds with TTS → listen again loop
4. Show real-time transcript as text overlay
5. "End conversation" button (large, easy to tap while driving)
6. Auto-pause when AI is speaking (don't record TTS playback)
7. Handle interruptions gracefully (phone call, Siri, etc.)
**Acceptance criteria:**
- Can hold a multi-turn voice conversation without touching the screen
- AI responses are spoken via TTS
- Conversation mode persists across multiple turns
- Clean exit back to text chat
**Files:** `voice_conversation_overlay.dart`, `voice_controller.dart`, `voice_provider.dart`, `cmmd_voice_provider.dart`

### CDT-008: TTS response playback in chat
**Priority:** High | **Labels:** voice, feature
**Description:** When voice mode is active, AI responses should be read aloud via TTS:
1. After assistant message is complete (streaming done), send text to `VoiceProvider.synthesize()`
2. Play audio response through device speaker
3. Show a speaker icon on messages that were/are being read
4. Allow tap-to-replay on any assistant message
5. Respect device silent mode / volume settings
**Acceptance criteria:**
- AI responses are spoken after streaming completes
- Audio plays through device speaker
- Can be toggled on/off per session
**Files:** `chat_content.dart`, `voice_controller.dart`, `cmmd_voice_provider.dart`

### CDT-009: Voice mode quick-launch from lock screen widget
**Priority:** Medium | **Labels:** voice, platform
**Description:** For car use, users need to launch voice mode fast. Explore iOS widget or shortcut integration:
1. iOS Lock Screen widget that opens app directly into voice conversation mode
2. Siri Shortcut: "Hey Siri, talk to [assistant name]"
3. Deep link support: `flai://voice` opens voice mode
**Acceptance criteria:**
- At least one quick-launch method works
- App opens directly to voice conversation overlay
**Files:** iOS native integration files, `app_router.dart`

---

## Phase 2: Production Polish (Sprint 3)
> Goal: Make every feature reliable, handle edge cases, improve error UX.

### CDT-010: Error handling and retry UX
**Priority:** High | **Labels:** ux, reliability
**Description:** Improve error handling across the app:
1. Network connectivity detection — show offline banner
2. API timeout retry with exponential backoff
3. Streaming interruption recovery (resume or retry)
4. Token refresh failure → redirect to login gracefully
5. Rate limit handling with user-friendly message
6. Server error (500) → show "Try again" with retry button
**Acceptance criteria:**
- No unhandled exceptions crash the app
- Every error state has a user-facing message and action
- Retry button works on failed messages
**Files:** `home_controller.dart`, `cmmd_ai_provider.dart`, `cmmd_client_base.dart`

### CDT-011: Conversation search
**Priority:** Medium | **Labels:** sidebar, feature
**Description:** The sidebar has a search bar UI but it needs full implementation:
1. Filter conversations as user types (client-side for loaded conversations)
2. Search by title and message preview text
3. Highlight matching text in results
4. Clear search button
5. "No results" empty state
**Acceptance criteria:**
- Typing in search bar instantly filters the conversation list
- Both starred and recent conversations are searched
- Clearing search restores full list
**Files:** `sidebar_drawer.dart`, `sidebar_config.dart`

### CDT-012: Typing indicators and read receipts
**Priority:** Low | **Labels:** chat, polish
**Description:** Add visual feedback for message delivery:
1. Show checkmark when message is sent to server
2. Show double-checkmark when AI starts processing
3. Typing indicator appears before first token (already implemented, verify)
**Acceptance criteria:**
- User sees message status progression: sending → sent → AI typing → response
**Files:** `message_bubble.dart`, `home_controller.dart`

### CDT-013: Dark/light mode system follow
**Priority:** Medium | **Labels:** theme, feature
**Description:** Add option to follow system dark/light mode automatically:
1. Add `FlaiThemeData.system()` that switches between light and dark based on `MediaQuery.platformBrightnessOf(context)`
2. Add `system` as a theme option in `flai init`
3. Update `FlaiApp` to rebuild on brightness change
**Acceptance criteria:**
- App theme follows iOS/Android system appearance setting
- Toggle works in real-time (no restart needed)
**Files:** `flai_theme.dart`, `app.dart`, `init_command.dart`

### CDT-014: `flai theme` command — switch themes post-init
**Priority:** Medium | **Labels:** cli, dx
**Description:** Add a `flai theme <preset>` command that changes the theme in flai.yaml and regenerates main.dart:
1. Read current flai.yaml
2. Update theme field
3. Regenerate main.dart with new theme constructor
4. Print confirmation
**Acceptance criteria:**
- `flai theme ios` switches to iOS theme
- `flai theme list` shows available presets
- main.dart is updated without losing other config
**Files:** `packages/flai_cli/lib/commands/theme_command.dart` (new), `command_runner.dart`, `config.dart`

### CDT-015: `flai update` command — update installed bricks
**Priority:** Medium | **Labels:** cli, dx
**Description:** Add `flai update` to re-generate all installed bricks from latest templates:
1. Read flai.yaml for installed list
2. Re-run Mason generation for each brick
3. Show diff summary of what changed
4. Preserve user modifications (prompt before overwrite)
**Acceptance criteria:**
- `flai update` refreshes all brick files
- User is warned about overwrites
- flai.yaml installed list is preserved
**Files:** `packages/flai_cli/lib/commands/update_command.dart` (new), `command_runner.dart`

---

## Phase 3: Growth & Distribution (Sprint 4)
> Goal: Get FlAI in front of developers. Make it easy to discover, try, and share.

### CDT-016: Publish CLI to pub.dev
**Priority:** Urgent | **Labels:** release, distribution
**Description:** Fix the CHANGELOG blocker (CDT-001) and ensure the release workflow publishes successfully. After publish, verify `dart pub global activate flai_cli` installs v0.3.0 and all commands work.
**Acceptance criteria:**
- `flai_cli` package live on pub.dev at version 0.3.0
- `dart pub global activate flai_cli && flai --version` returns 0.3.0
**Depends on:** CDT-001

### CDT-017: Publish Claude Code skill as official plugin
**Priority:** High | **Labels:** distribution, ai
**Description:** The skill.md is updated but needs to be published as an official Claude Code plugin so any Claude Code user can install it. Follow the claude-plugins publishing process.
**Acceptance criteria:**
- Skill installable via Claude Code plugin marketplace
- AI assistants can guide users through FlAI setup using the skill
**Files:** `packages/flai_skill/`

### CDT-018: "Build an AI chat app in 60 seconds" tutorial
**Priority:** High | **Labels:** content, marketing
**Description:** Create a step-by-step tutorial (blog post format) showing the complete FlAI experience:
1. Start with `flutter create`
2. Show the interactive init (screenshot/GIF)
3. Show `flai add app_scaffold` output
4. Show the running app on simulator
5. Show `flai connect cmmd` and the production app
6. Total time: under 60 seconds
Format: HTML page at `docs-site/docs/tutorial.html` + add to sidebar nav
**Acceptance criteria:**
- Tutorial page live on getflai.dev/docs/tutorial
- Includes terminal GIFs or screenshots at each step
- Reader can follow along and have a working app

### CDT-019: README and landing page GIF/video demo
**Priority:** Medium | **Labels:** marketing, content
**Description:** Record a terminal GIF showing the 3-command setup and embed in:
1. README.md (replace static code block with animated GIF)
2. Landing page hero (optional: replace CSS terminal with real GIF)
Use `asciinema` or `vhs` to record terminal session.
**Acceptance criteria:**
- GIF shows: `flai init` prompts → `flai add app_scaffold` → `flutter run` → app on simulator
- Under 30 seconds
- Embedded in README.md

### CDT-020: SEO optimization for getflai.dev
**Priority:** Medium | **Labels:** marketing, seo
**Description:** Improve search visibility:
1. Add structured data (FAQ schema) to docs pages
2. Submit sitemap to Google Search Console
3. Add alt text to all images/mockups
4. Ensure all pages have unique meta descriptions
5. Add internal linking between related pages
6. Create a /blog section for content marketing
**Acceptance criteria:**
- Site indexed by Google within 1 week
- Core pages rank for "flutter ai chat components"

---

## Phase 4: Enterprise & Advanced Features (Sprint 5)
> Goal: Features that make FlAI viable for production enterprise apps.

### CDT-021: Phone authentication implementation
**Priority:** Medium | **Labels:** auth, feature
**Description:** Currently throws `UnimplementedError` in `auth_controller.dart`. Implement phone OTP auth:
1. Add phone number entry screen to auth flow
2. Send OTP via CMMD API
3. Verify OTP screen
4. Wire to AuthProvider interface
**Acceptance criteria:**
- User can sign in with phone number + OTP
- Works with CMMD backend
**Files:** `auth_controller.dart`, `cmmd_auth_provider.dart`, new screens

### CDT-022: Image generation and inline display
**Priority:** Medium | **Labels:** chat, feature
**Description:** Support AI-generated images in chat:
1. Parse image URLs from AI response
2. Display inline with zoom-to-full-screen
3. Save to device photo library option
**Files:** `message_bubble.dart`, `image_preview` brick

### CDT-023: Custom provider template — `flai connect custom`
**Priority:** Medium | **Labels:** cli, providers
**Description:** Add `flai connect custom` that generates stub provider implementations the developer can fill in:
1. Generate empty `CustomAiProvider`, `CustomAuthProvider`, etc.
2. Each has TODO comments explaining what to implement
3. Wire into main.dart just like `flai connect cmmd`
**Acceptance criteria:**
- `flai connect custom` generates working stubs
- App compiles and runs with stub providers
- Developer knows exactly what to implement
**Files:** New brick `custom_providers/`, `connect_command.dart`

### CDT-024: Multi-language / i18n support
**Priority:** Low | **Labels:** feature, i18n
**Description:** All user-facing strings should be localizable:
1. Extract all hardcoded strings to a localization file
2. Support en, es, fr, de, ja, zh at minimum
3. `flai init` prompts for default language
4. Runtime language switching
**Files:** All screen/widget files, new `l10n/` directory

### CDT-025: Offline mode with local storage fallback
**Priority:** Low | **Labels:** feature, reliability
**Description:** Allow basic functionality without network:
1. Cache recent conversations locally (SQLite or Hive)
2. Queue messages when offline, send when reconnected
3. Show cached conversations in sidebar
4. Offline indicator in UI
**Files:** `storage_provider.dart`, new `local_storage_provider.dart`

---

## Phase 5: Ecosystem (Sprint 6+)
> Goal: Build a community and ecosystem around FlAI.

### CDT-026: Gemini provider brick
**Priority:** Medium | **Labels:** providers, feature
**Description:** Add `flai add gemini_provider` for Google Gemini API support. Same interface as OpenAI/Anthropic providers.
**Files:** New brick `gemini_provider/`

### CDT-027: Ollama / local LLM provider brick
**Priority:** Medium | **Labels:** providers, feature
**Description:** Support local LLMs via Ollama API. Important for privacy-conscious users and development.
**Files:** New brick `ollama_provider/`

### CDT-028: Example apps gallery
**Priority:** Low | **Labels:** content, examples
**Description:** Create 3-4 example apps showing different FlAI use cases:
1. Customer support bot
2. Coding assistant
3. Study buddy / tutor
4. Personal journal with AI reflection
Each as a separate directory in `examples/` with README.

### CDT-029: Community contribution guide
**Priority:** Low | **Labels:** docs, community
**Description:** Create CONTRIBUTING.md with:
1. How to create a new brick
2. How to submit a provider
3. Code style guide
4. PR process
5. Issue templates

### CDT-030: Figma design kit
**Priority:** Low | **Labels:** design, community
**Description:** Create a Figma file with all FlAI components matching the 4 theme presets. Useful for designers planning apps that will use FlAI.
