# LULL · AI Sleep Stories Made For You
> A bedtime story written for who you are tonight.

## Tier · B (Calm/Headspace are dominant, but personalization gap is open)
A sleep story app where every story is generated for you — your name, your favorite genre, your stress level today (HealthKit), your favorite voice. Calm/Headspace serve mass-market pre-recorded content; Lull is "your personal sleep storyteller."

## App Store Listing
- **Name (30c):** `Lull: AI Sleep Stories`
- **Subtitle (30c):** `Bedtime stories made for you`
- **Primary keyword:** `sleep stories`

## ASO Keywords (US iOS, monthly search est.)
| Keyword | Volume | Difficulty |
|---|---|---|
| sleep stories | 100K+ | High |
| bedtime stories adults | 80K | Medium |
| fall asleep fast | 200K | High |
| sleep meditation | 150K | High |
| white noise sleep | 250K | High |
| insomnia help | 80K | Medium |

## Top Competitors (verified)
- **Calm** — $200M+ ARR
- **Headspace** — $200M+ ARR
- **BetterSleep** — $50M+ ARR
- **Slumber** — $5M+ ARR

## Why This Makes Money
1. **Calm/Headspace are saturated** but **personalization is the wedge.** Every story they offer is pre-recorded; AI lets you write a story custom each night.
2. **Marginal cost:** $0.05/story (LLM + TTS). Premium price tolerable.
3. **High-frequency use** = high LTV.
4. **Apple Watch + Sleep tracking** integration creates loyalty.
5. **Voice clone** of comforting voice (your own / partner / celebrity-style) is a Pro+ killer feature.

## Core Mechanics
1. Pick story type: walk in old village / sci-fi cozy / detective puzzle / nature documentary
2. Personalize: your first name, your city, favorite calm activity (gardening, cooking, walking)
3. AI generates 15-25 min story
4. **AI narrator voice:** soft male / soft female / neutral / "your partner" (Pro+ voice clone)
5. Auto-play with sleep timer that detects when you're asleep (HealthKit)
6. Wake-up integration: gentle nature sounds before alarm

## Anti-features
- ✗ No "subscribe to access" gate on free tier (1 story/night free is critical)
- ✗ No notification spam at bedtime
- ✗ No social share of stories
- ✗ No celebrity voice deepfakes (legal risk)
- ✗ No bundled "wellness content" (focus, mindfulness — separate apps)

## Monetization
- **Free:** 1 story/night, 4 base voices
- **Pro $9.99/mo or $69/yr** — unlimited stories + premium voices + Apple Watch + sleep timer + smart wake
- **Lifetime $99**
- **Pro+ $14.99/mo** — voice clone (your partner / yourself reading / your kid's voice for "tell me a story")

**Realistic revenue path:**
- Month 1: $2-5K MRR
- Month 6: $30-80K MRR
- Month 12: $150-400K MRR
- Year 2: $2-6M ARR plausible (sleep is expensive market to enter though)

## iOS Tech Stack
- SwiftUI 6, iOS 17+
- LLM: GPT-4o-mini for story generation
- TTS: ElevenLabs / Apple Personal Voice for premium voices
- **AVFoundation** for audio playback (background mode required)
- **HealthKit** read sleep stages → auto-stop story when asleep
- **Apple Watch** integration (story controls on wrist)
- **WidgetKit** "tonight's story" widget
- **StoreKit 2** + Superwall

## 6-Week MVP Scope
- W1-2: Story generator + 4 base voices + audio player
- W3: HealthKit sleep detection + auto-pause
- W4: Apple Watch + smart wake
- W5: Subscription + voice clone Pro+
- W6: TestFlight + ship

## Distribution Plan (90 days)
- ASO: target `sleep stories` (top 30, hard), `bedtime stories adults` (top 10)
- Reddit: r/sleep, r/insomnia, r/asmr
- TikTok: AI-generated bedtime story snippets, "the most personalized sleep app"
- Newsletter: Sleep Foundation, Sleep Doctor partnerships
- Influencer: sleep coaches, ASMR creators (50 free codes)
- Press: Sleep Foundation, Self, Bustle
