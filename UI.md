# LULL · UI Design

## Visual Identity
- **Palette:** Midnight `#0F1429` · Moon cream `#F4F0E8` · Warm lamp `#E8C087` · Forest green `#2D4A3E` (genre)
- **Typography:** GT Sectra (story titles) · Lyon Italic (story prose preview) · Söhne (UI)
- **Core motif:** A bedside lamp casting one circle of warm light
- **Tone:** Whisper-quiet, library-bedtime, never gimmicky

## Key Screens (SwiftUI)

### 1. Onboarding
- Black → bedside lamp clicks on softly
- Lines: `every story we have is for someone else.` / `tonight's is for you.` / `your name. your city. your kind of calm.`
- Setup: name, city, calm activity preference
- CTA: `tonight's story`

### 2. Tonight's Picker
- 4 cards:
  - 🏘️ Old Village Walk
  - 🚀 Cozy Sci-Fi
  - 🔍 Gentle Mystery
  - 🌳 Nature Doc
- Tap → preview line: `walking through {your city's} oldest streets, the kind of evening you remember from {your activity}...`
- Bottom: voice picker (4 base / 8 Pro)

### 3. Listening (active)
- Full-screen night sky (slowly drifting stars)
- Title centered subtle
- Bottom: play/pause, sleep timer (defaults to "until I'm asleep" via HealthKit)
- Story text scrolls below (off by default — pure audio)

### 4. Sleep Detection
- Watching HealthKit sleep stages
- Story fades out 5 min after first deep sleep detected
- No "did you sleep?" survey

### 5. Pro+ Voice Clone Setup
- 30-second sample: read provided text
- AI generates voice profile
- Privacy: voice never leaves your iCloud
- Use it for nights you want "your own voice" or partner's

### 6. Smart Wake
- Set alarm time
- 20 min before: nature sounds gradually wake
- Or: Lull narrates a "good morning" custom message in chosen voice

### 7. Apple Watch
- Complication: "tonight's story" tap → start
- Force-touch: pause / change voice
- Haptic-light wake

### 8. WidgetKit
- Lock Screen: tonight's story title + tap to start
- Bedside automation: shortcut "good night" trigger

### 9. Pro Paywall
- Hero: bedside lamp + tagline `your bedtime story, written tonight`
- Tiers: $9.99/mo · $69/yr (most popular) · $99 lifetime
- Pro+ revealed after 7-day trial

## Micro-interactions
- **Lamp animation:** screen brightness automatically dims as story progresses (uses iOS auto-brightness override)
- **Voice transitions:** fade between voices, never jarring
- **Sleep detection:** silent — never wakes user to confirm
- **Background audio:** continues with phone locked (audio background mode)

## Anti-design
- ✗ No "did you fall asleep?" survey
- ✗ No "rate this story" interruption
- ✗ No social share of stories
- ✗ No notification spam reminding to use Lull
- ✗ No celebrity voice library (legal + ethics)

## App Store Screenshots (5)
1. Lamp + dark night + tagline `a bedtime story written for you`
2. 4 genre cards with personalized preview lines
3. Full-screen listening view with star drift
4. Apple Watch complication
5. Pro+ voice clone setup screen

## Audio Architecture
- **Background mode:** `audio` capability
- TTS streamed: 30-second buffer ahead, low memory
- Auto-pause on incoming call / VoIP
- Mixes with iOS sleep audio (does not pause Spotify if also playing)
