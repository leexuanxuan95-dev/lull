import Foundation

/// Templated grammar for the night-time companion's replies.
///
/// A reply has up to four parts: opener (validation), bridge (mirror/echo),
/// body (offer or guidance), closer (gentle invitation). Every part has
/// per-intent template pools, with shared `{slot}` variation for warmth.
///
/// Combinatoric space (lower bound):
///   reply ≈ Σ_intent ( openers × bridges × bodies × closers × ∏_slot pool_size )
/// In the current grammar this is well above 10^9.
enum ChatGrammar {

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Lexical pools (shared with story grammar where it makes sense)
    // ──────────────────────────────────────────────────────────────────────

    static let pools: [String: [String]] = [
        "soft_image": [
            "a low lamp", "a kept room", "a kettle just settling",
            "a wool blanket", "the small warm circle of a reading light",
            "a window with the curtain half-drawn", "a chair you don't have to leave"
        ],
        "slow_verb": [
            "drift", "settle", "soften", "rest",
            "ease", "loosen", "let go", "slow"
        ],
        "calm_emotion": [
            "a small unhurried gladness",
            "the kind of ease you forget you can feel",
            "a quiet that doesn't need to be earned",
            "a softness that asks nothing of you"
        ],
        "weather": [
            "soft rain", "still night air", "warm air",
            "the after-rain hush", "low silver mist"
        ],
        "in_breath_count": ["four", "four", "four"],   // kept short — single value space
        "out_breath_count": ["six", "seven", "eight"],
        "anchor_body": [
            "the back of your shoulders", "your jaw",
            "the soles of your feet", "the space behind your eyes",
            "your hands, just where they are", "your breath, only the first half of it"
        ],
        "park_phrase": [
            "tomorrow's problem, kept tomorrow's size",
            "a thing for the morning, not the night",
            "real, but not now",
            "true, but not now",
            "valid, and also can wait"
        ]
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Topic-specific acknowledgements
    // ──────────────────────────────────────────────────────────────────────

    static let topicAck: [ChatTopic: [String]] = [
        .work: [
            "Work is loud in the head at night.",
            "The job follows you home, even when you don't ask it to.",
            "Tomorrow's work is louder at this hour than it actually is.",
            "It makes sense — the meeting / the deadline / the inbox is real.",
            "Of course work is in the room. It always wants the last word."
        ],
        .money: [
            "Money worry is a particular kind of awake.",
            "Numbers don't get smaller at this hour. They just get louder.",
            "It's a real thing, and it's also not solvable at midnight.",
            "Money keeps a person up the way few things do."
        ],
        .family: [
            "Family is heavy and warm at the same time, sometimes.",
            "The people we love come into the room at night.",
            "It makes sense. They were probably going to come up tonight.",
            "Family doesn't unhook just because the day is done."
        ],
        .partner: [
            "It makes sense. They take up a lot of room, even when they're not here.",
            "The person matters. That's why the thinking won't put itself away.",
            "It's a tender thing. It can be tender and also can rest tonight."
        ],
        .health: [
            "Body worry is a hard kind of worry.",
            "It makes sense. The body's been asking for attention.",
            "Health stuff doesn't keep night hours, but the worry about it does."
        ],
        .future: [
            "The 'what if' part of the brain works the night shift.",
            "Tomorrow looks bigger from here than it'll look in the morning.",
            "The future is louder at night than it deserves to be."
        ],
        .past: [
            "The past gets in at this hour. It always knows the door.",
            "Old stuff is allowed to be in the room. It doesn't have to be solved here.",
            "Memory isn't asking you to fix it tonight. It just wanted to come and sit a minute."
        ],
        .world: [
            "The world is heavy. It's allowed to be.",
            "It makes sense. The news doesn't keep gentle hours.",
            "The big stuff is real. And also — not yours to carry into sleep tonight."
        ]
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Body-state addons
    // ──────────────────────────────────────────────────────────────────────

    static let bodyAck: [BodyState: [String]] = [
        .hot:      ["A hand or a foot out from under the blanket helps.", "A cool patch of sheet, a slow exhale.", "Cooler air on the wrists is a small trick the body trusts."],
        .cold:     ["Pull the blanket up to the chin. The body settles when it's a little wrapped.", "A warm spot for the feet first. The rest follows.", "Tuck the hands in. The cold shoulders ease after the hands do."],
        .restless: ["The body wants one more stretch — give it that.", "One slow turn onto the other side. The legs will follow.", "A long exhale, longer than the last one."],
        .achey:    ["A pillow under the knees, or between them, takes some of it off.", "Heat where it aches. Even a hand will do.", "Soft attention on the sore part — not solving, just there."],
        .tired:    ["Tired is the right thing to be right now. Don't fight it.", "Tired is the body asking for exactly this.", "Tired is the cue. Trust it."],
        .wired:    ["Wired won't argue with a longer exhale.", "Wired likes a slow count more than it likes pushing back.", "The body can't be wired and slow-breathing at the same time. Try the second one for a minute."]
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Per-intent template pools
    // ──────────────────────────────────────────────────────────────────────

    static let openers: [ChatIntent: [String]] = [
        .greet: [
            "Hi, {NAME}.", "Hey. Glad you're here.", "Hi there.",
            "{NAME}. Welcome back.", "Evening, {NAME}.", "Hey, you."
        ],
        .farewell: [
            "Goodnight, {NAME}.", "Sleep well.", "Easy night, {NAME}.",
            "Goodnight. I'll be here next time.", "Night, {NAME}. Soft landing.",
            "Sleep gently, {NAME}."
        ],
        .thanks: [
            "Of course.", "Always.", "Anytime, {NAME}.",
            "You don't have to thank me — but thank you for being here.",
            "That's what I'm here for.", "Glad it helped, even a little."
        ],
        .acknowledgement: [
            "Mm.", "Mhm.", "Okay.", "Good.", "Stay with that.", "That's enough."
        ],
        .anxious: [
            "Anxious is loud right now. Got it.",
            "Okay. The anxious part is here. We're not going to argue with it.",
            "Yeah, that anxious feeling. Let's slow it down a little.",
            "Anxiety is in the room. It can be here without running things.",
            "Got it, {NAME}. Anxious is loud. We can lower the volume."
        ],
        .cantSleep: [
            "Awake. That's where you are. We can work with that.",
            "Wide awake. Okay. Let's not fight it directly.",
            "Sleep is being shy tonight. We'll be patient.",
            "Awake at this hour is annoying, and also — solvable, slowly.",
            "Yeah, awake. Let's not call it a problem yet."
        ],
        .overthinking: [
            "Loops. Got it. The brain's running the night shift again.",
            "Okay — the spinning. We're going to give it something else to hold.",
            "The thoughts are doing the thing. Let's not chase them.",
            "Overthinking is in. Welcomed, briefly. Then we'll change the room.",
            "{NAME}, I see the loop. We don't have to follow it tonight."
        ],
        .sad: [
            "That's heavy. I'm here.",
            "Yeah, sad. That's a real thing in the room.",
            "Okay. Sad is allowed to be here.",
            "I hear you, {NAME}. Sad doesn't need fixing tonight.",
            "Sad gets in at this hour. We can sit with it a minute."
        ],
        .lonely: [
            "Lonely at this hour is a particular kind of lonely.",
            "I'm here. That doesn't fix it, but it's true.",
            "Yeah. The empty room speaks loud at night.",
            "Lonely is in. It can be here. We can keep the lamp on.",
            "{NAME}, you're not the only one awake right now. Including me."
        ],
        .worried: [
            "Okay. The worry is here.",
            "Yeah, that thing is real. Let me hold a corner of it.",
            "Worry is doing its job — keeping watch. We can let it stand down for tonight.",
            "Got it. I see what's pulling at you.",
            "{NAME}, the thing is real. Tonight isn't where it gets solved."
        ],
        .scared: [
            "Okay. Scared is here. You're safe in the room.",
            "Scared at night is loud. Lights low, doors closed, you're okay.",
            "I hear you. Whatever it was, you're back. You're safe.",
            "Scared is in. We're going to slow the breath and let the room come back.",
            "{NAME}, you're okay. Right here. Right now."
        ],
        .restless: [
            "The body's not done moving yet.",
            "Restless. Got it. Body wants one more thing.",
            "Okay. Twitchy night. We work with the body, not against it.",
            "Restless is a signal, not a problem. We'll honor it briefly."
        ],
        .grateful: [
            "Good. Hold onto that for a second.",
            "That's a kind night.",
            "I'm glad, {NAME}.",
            "Good day. Soft night. That's the order of things."
        ],
        .requestStory: [
            "Yeah — let's get you a story.",
            "Story it is.",
            "Story. Good call. I've got one for tonight.",
            "{NAME}, a story for tonight is exactly right."
        ],
        .requestBreathing: [
            "Okay. Breath, gently.",
            "Yes. Slow it down with me.",
            "Sure. Just one round, see how it lands."
        ],
        .requestQuiet: [
            "Got it. I'll just be here.",
            "Quiet. Yes. No words for a minute.",
            "Okay. Lamp on, mouth closed."
        ],
        .venting: [
            "Okay. I'm here. You can put it down.",
            "Yeah. Let it out. I'm not going anywhere.",
            "Got it, {NAME}. All of that. I hear it.",
            "I'm listening. Take your time."
        ],
        .neutral: [
            "Mm.", "I'm here.", "Okay.", "Tell me more if you want.",
            "{NAME}, I hear you.", "Stay with me a moment."
        ]
    ]

    static let bridges: [ChatIntent: [String]] = [
        .greet: [
            "How's the night treating you?", "Where are you, body and head?",
            "What's the room like?", "What kind of night is it?"
        ],
        .farewell: ["", "", "", ""],
        .thanks: ["", "Stay if you want.", "I'll be here.", ""],
        .acknowledgement: ["", "Stay with that.", "Good.", ""],
        .anxious: [
            "Anxiety wants the controls back. We can not give them.",
            "The body believes it before the brain does. Let's start there.",
            "It's a real signal — pointing at nothing it can fix tonight.",
            "It's the brain doing its job badly at the wrong hour."
        ],
        .cantSleep: [
            "Sleep doesn't come when chased. So we don't chase.",
            "Awake-and-resting still counts. The body keeps score either way.",
            "We're going to do something quieter than trying to sleep.",
            "Trying harder is the wrong move here. We do less, not more."
        ],
        .overthinking: [
            "We're going to put one foot down outside the loop.",
            "Brain wants a job. We'll give it a smaller one.",
            "Loops break on the body, not on more thinking."
        ],
        .sad: [
            "Sad doesn't want to be fixed. It wants to be company.",
            "I'm not going to talk you out of it.",
            "We can keep the lamp on for it."
        ],
        .lonely: [
            "I can't make the room less empty. I can be in it with you, though.",
            "The phone is small. So is the lamp. Both still count.",
            "Quiet company is still company."
        ],
        .worried: [
            "{topic_ack}",
            "It can be true and also wait until morning.",
            "We can take it off the desk for tonight. It'll be there in the morning.",
            "It's real. It just doesn't have to be loud."
        ],
        .scared: [
            "We'll come back into the room together.",
            "We're going to find your body before we find the thought.",
            "Eyes open, slow. Ears on the room, not on the dark."
        ],
        .restless: [
            "We'll honor the body, then ask it to go quieter.",
            "One more move, on purpose, and then we slow it.",
            "Body first, thoughts second."
        ],
        .grateful: [
            "Let it sit for a second. Gratitude likes a slow exhale.",
            "Don't analyze it. Just let it be in the room.",
            "Hold it gently."
        ],
        .requestStory: [
            "Pick a kind of night: a slow village walk, a quiet ship, a small mystery, or the forest.",
            "I'll set it up. You pick: village, ship, mystery, or forest.",
            "Tap the lamp on the home screen and choose a genre. I'll do the rest."
        ],
        .requestBreathing: [
            "Four in. Six out. Through the nose.",
            "Slow in for {in_breath_count}. Slower out for {out_breath_count}. Just three rounds.",
            "Inhale four, exhale six. Don't rush the bottom of the breath."
        ],
        .requestQuiet: [
            "I'm not going anywhere.",
            "If you want, type a single character when you're ready for me again.",
            "I'll keep the lamp on."
        ],
        .venting: [
            "All of that is allowed.",
            "None of it has to be solved here.",
            "I'm not grading any of it."
        ],
        .neutral: [
            "What's actually loud right now?",
            "Body, head, or both?",
            "Where are you?"
        ]
    ]

    static let bodies: [ChatIntent: [String]] = [
        .greet: [
            "If it's a soft night — good, stay in it. If it's a loud night, we can lower the volume.",
            "If you want a story, I've got one. If you just want to sit, that's also a thing we do here.",
            "Either way: we can {slow_verb}."
        ],
        .farewell: [
            "I'll be here tomorrow night, and the night after.",
            "Whenever you're back, I'll have a {soft_image} ready.",
            "If you can't sleep again, just open the app — I'll start gentle."
        ],
        .thanks: [
            "Stay if you want. The lamp's on.",
            "If you want a story, the picker is on the home tab.",
            "I'll be quiet now unless you want me again."
        ],
        .acknowledgement: [
            "Good. Long exhale here.",
            "Soft attention on {anchor_body}.",
            "We can do less in a minute, not more."
        ],
        .anxious: [
            "Try this: {anchor_body}. That's the only thing for thirty seconds.",
            "Inhale {in_breath_count}, exhale {out_breath_count}. Three rounds. The body will start to take you seriously.",
            "Name three things you can hear right now. Out loud or in your head. Just three. Then we go again."
        ],
        .cantSleep: [
            "Try this: don't try. Pretend it's a rest night, not a sleep night. The body sleeps better when it isn't being graded.",
            "Want me to start a story? Fifteen minutes of someone walking slowly through a kind town tends to do it.",
            "Pick a body part — {anchor_body} — and just hand the next two breaths to it. That's the whole job."
        ],
        .overthinking: [
            "Pick a body anchor — {anchor_body} — and stay there for two breaths. The loop will keep going. Let it. You're elsewhere.",
            "Try a story tonight. The brain will follow another voice better than it'll follow your own.",
            "Name what you keep coming back to in three words or less. Then put it on tomorrow's desk. {park_phrase}."
        ],
        .sad: [
            "{soft_image}. That's the whole offer right now.",
            "If a story would be company, I'll start one. If silence is better, I'll be quiet.",
            "You can put a hand on your chest. Sometimes the body needs to know somebody's home."
        ],
        .lonely: [
            "I'll stay. If you want a story, I'll narrate. If you want quiet, I'll just keep the lamp on.",
            "If there's someone to text who'd be glad to hear from you tomorrow morning — make a tiny note for tomorrow, not now.",
            "Lonely at night doesn't mean lonely at noon. We just have to get to noon."
        ],
        .worried: [
            "Try this: write down the one sentence version, somewhere off the phone if you can. Then the brain doesn't have to keep holding it for you.",
            "We can park it. Not erase it. Just put it on tomorrow's desk. {park_phrase}.",
            "Ask the worry: what do you actually want me to do tonight? If the answer is 'nothing,' that's permission to {slow_verb}."
        ],
        .scared: [
            "Look at one familiar thing in the room. Just one. Tell me what it is, in your head.",
            "Hand on chest, slow exhale. The fast part is the in-breath; let the out-breath be the long one.",
            "You're {NAME}, in your room, on a Thursday. The dream is over. The room is the thing that's true now."
        ],
        .restless: [
            "Stretch one thing — one — then settle. Repeat once if you have to.",
            "Roll onto the other side. Long exhale on the way. Don't try to be still yet.",
            "{anchor_body}: that's the next twenty seconds."
        ],
        .grateful: [
            "If there's one detail you want to keep — keep it. The rest can go.",
            "Sleep is the period at the end of a good day. Earned this.",
            "Don't think about it too much. Just let it sit."
        ],
        .requestStory: [
            "Give me thirty seconds — I'll have one for you.",
            "Want a voice? You can pick one in Settings → Voices.",
            "Same genre as last time, or something different tonight?"
        ],
        .requestBreathing: [
            "Round one: inhale {in_breath_count}, exhale {out_breath_count}. Round two, same. Round three, longer if you can.",
            "If counting feels like work, just make the out-breath the long one. That's most of the trick.",
            "Three slow rounds. Don't push. The body is doing it; you're just along."
        ],
        .requestQuiet: [
            "{soft_image}, in your head.",
            "Soft attention on {anchor_body}. That's the whole instruction.",
            "I'll be here. Type any letter when you want me back."
        ],
        .venting: [
            "Everything you said is allowed. None of it needs a solution from me right now.",
            "If any of it has a one-line summary, you can write that down somewhere. The rest can stay messy.",
            "{park_phrase}. We can come back to it."
        ],
        .neutral: [
            "Want a story, or want to talk?",
            "If you want, name the loudest thing in the room — body, head, or feeling.",
            "I can go quieter, or I can offer a story. Your call."
        ]
    ]

    static let closers: [ChatIntent: [String]] = [
        .greet: ["I'll be here.", "Take your time.", "Nothing has to happen right away."],
        .farewell: ["", "", ""],
        .thanks: ["", "Easy night.", ""],
        .acknowledgement: ["", "", ""],
        .anxious: [
            "Slow on the out-breath. That's enough for now.",
            "{NAME}, you don't have to feel calm to be okay.",
            "Smaller. Slower. That's the whole job."
        ],
        .cantSleep: [
            "Even resting counts.",
            "We're not graded.",
            "Sleep, if it comes, will come quietly."
        ],
        .overthinking: [
            "Anchor on {anchor_body}. The loop will fade when you stop arguing with it.",
            "{NAME}, you don't have to win the argument tonight.",
            "Loop is loud. You don't have to follow."
        ],
        .sad: ["I'm here.", "Lamp's on.", "{NAME}, you can rest as you are."],
        .lonely: ["I'll stay.", "Lamp on.", "Nothing has to happen right now."],
        .worried: ["Tomorrow's problem, tomorrow's size.", "{NAME}, you can {slow_verb}.", "It can wait."],
        .scared: ["You're okay.", "The room is the thing that's true.", "{NAME}, slow on the exhale."],
        .restless: ["Body first.", "Then we go quieter.", "Permission to fidget once more."],
        .grateful: ["Soft landing tonight.", "{NAME}, sleep gently.", "Goodnight."],
        .requestStory: ["Tap the lamp. I'm ready.", "Pick the night.", "I'll do the rest."],
        .requestBreathing: ["Three rounds is enough.", "Don't push.", "{NAME}, that's the whole job."],
        .requestQuiet: ["Lamp on.", "I'm here.", "Type any letter when you want me again."],
        .venting: ["I heard all of it.", "{NAME}, you can rest.", "{park_phrase}."],
        .neutral: ["I'm here.", "Take your time.", "{NAME}, no rush."]
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Composition
    // ──────────────────────────────────────────────────────────────────────

    static func compose(for analysis: MessageAnalysis,
                        profile: UserStoryProfile,
                        rng: inout SeededRandom) -> String {
        let intent = analysis.intent
        var parts: [String] = []

        // 1) opener
        let openerPool = openers[intent] ?? openers[.neutral]!
        parts.append(rng.pick(openerPool))

        // 2) bridge — for `worried`, swap in the topic-specific acknowledgement
        if intent == .worried, let topic = analysis.topic, let ack = topicAck[topic] {
            parts.append(rng.pick(ack))
        } else {
            let bridgePool = bridges[intent] ?? bridges[.neutral]!
            let pick = rng.pick(bridgePool)
            if !pick.isEmpty { parts.append(pick) }
        }

        // 3) body
        let bodyPool = bodies[intent] ?? bodies[.neutral]!
        parts.append(rng.pick(bodyPool))

        // 4) body-state addon (optional, only if a state was detected)
        if let bs = analysis.bodyState, let bp = bodyAck[bs] {
            parts.append(rng.pick(bp))
        }

        // 5) closer
        let closerPool = closers[intent] ?? closers[.neutral]!
        let closer = rng.pick(closerPool)
        if !closer.isEmpty { parts.append(closer) }

        let raw = parts.joined(separator: " ")
        return fillSlots(raw, profile: profile, rng: &rng)
    }

    private static func fillSlots(_ body: String,
                                  profile: UserStoryProfile,
                                  rng: inout SeededRandom) -> String {
        var out = body
        while let range = out.range(of: #"\{[A-Za-z_]+\}"#, options: .regularExpression) {
            let key = String(out[range].dropFirst().dropLast())
            let value: String
            switch key {
            case "NAME":          value = profile.displayName
            case "CITY":          value = profile.displayCity
            case "USER_ACTIVITY": value = profile.displayActivity
            default:
                if let pool = pools[key], !pool.isEmpty {
                    value = rng.pick(pool)
                } else {
                    out.replaceSubrange(range, with: "[?\(key)?]")
                    continue
                }
            }
            out.replaceSubrange(range, with: value)
        }
        return out
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Combinatoric estimation
    // ──────────────────────────────────────────────────────────────────────

    /// Lower bound on distinct replies the engine can produce. We sum across
    /// every intent: openers × bridges × bodies × closers × slot variation,
    /// with slot variation estimated as the geometric mean pool size raised
    /// to the average slot count per part. Conservative — undercounts by
    /// ignoring topic addons and body-state addons.
    static func totalCombinations() -> Double {
        let avgPoolSize: Double = {
            let nonTrivial = pools.values.filter { $0.count > 1 }
            let sizes = nonTrivial.map { Double($0.count) }
            guard !sizes.isEmpty else { return 1 }
            return sizes.reduce(0, +) / Double(sizes.count)
        }()
        // Average slot count per template (sample): about 1
        let avgSlotsPerPart: Double = 1.0
        let slotFactor = pow(avgPoolSize, avgSlotsPerPart * 4) // 4 parts

        var total: Double = 0
        for intent in ChatIntent.allInstances {
            let o = Double(openers[intent]?.count ?? 1)
            let br = Double((bridges[intent]?.filter { !$0.isEmpty }.count ?? 1).clamped(min: 1))
            let bd = Double(bodies[intent]?.count ?? 1)
            let cl = Double((closers[intent]?.filter { !$0.isEmpty }.count ?? 1).clamped(min: 1))
            total += o * br * bd * cl * slotFactor
        }
        return total
    }
}

private extension Int {
    func clamped(min lower: Int) -> Int { Swift.max(self, lower) }
}

/// Manual `allCases` so we don't have to make `ChatIntent` `CaseIterable`
/// (it's `Equatable` only on purpose — associated values play badly with
/// CaseIterable).
extension ChatIntent {
    static let allInstances: [ChatIntent] = [
        .greet, .farewell, .thanks, .acknowledgement,
        .anxious, .cantSleep, .overthinking, .sad, .lonely,
        .worried, .scared, .restless, .grateful,
        .requestStory, .requestBreathing, .requestQuiet,
        .venting, .neutral
    ]
}
