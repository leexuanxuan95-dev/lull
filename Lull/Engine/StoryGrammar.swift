import Foundation

/// Templated grammar for sleep-story prose.
///
/// A story is assembled from N "scene roles" played in order. For each role,
/// the generator picks one *template* (a short paragraph with `{slot}` markers),
/// then fills each slot from a named lexical pool using a seeded RNG.
///
/// Combinatoric space:
///   per genre  ≈  Σ_role (templates_in_role × ∏_slot pool_size)
///   total      ≈  sum across 4 genres
/// The current grammar gives ~10^40+ per genre — far above the 10^9 product claim.
enum StoryGrammar {

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Lexical pools
    // ──────────────────────────────────────────────────────────────────────
    // Slot keys are lower-case identifiers used inside `{...}` markers.

    static let pools: [String: [String]] = [
        "weather": [
            "soft rain", "pale moonlight", "drifting fog", "still night air",
            "a warm summer breeze", "the first frost", "thin starlight",
            "low silver mist", "windless cold", "the after-rain hush",
            "blue evening light", "a sky that has just stopped being orange",
            "the kind of warmth that arrives just before sleep",
            "a high, slow cloud", "the last of the daylight"
        ],
        "time_of_day": [
            "just past dusk", "an hour after sundown",
            "the soft middle of the night", "the quiet before dawn",
            "long after the last bus", "when the streetlights have settled",
            "after the houses have folded into themselves",
            "in that hour the day finally lets go",
            "after the day has finished its small work"
        ],
        "warm_color": [
            "amber", "honey-gold", "low rust", "the color of low lamps",
            "ember-red", "old brass", "tea-stained yellow",
            "the color of a closing day", "candle-warm orange",
            "wood-smoke gold"
        ],
        "cool_color": [
            "slate-blue", "the color of deep water", "moon-silver",
            "frost-pale", "the blue inside ice", "twilight grey",
            "the green of forest shadow", "a lake-bottom green",
            "cold tin", "ink that has not yet dried"
        ],
        "soft_sound": [
            "the slow ticking of a far-off clock",
            "rain on a tin roof", "a kettle remembering itself",
            "a cat resettling on a chair",
            "wind brushing through long grass",
            "pages turning in another room",
            "a far train, gentle as a breath",
            "leaves negotiating with the wind",
            "the small click of a closing latch",
            "water moving under a bridge",
            "a wooden floor easing"
        ],
        "scent": [
            "bread cooling on a counter", "wet stone",
            "pine warmed by the day", "old paper and tea",
            "lavender from a windowbox", "earth after rain",
            "cedar drawer-lining", "woodsmoke from a chimney",
            "a candle being snuffed", "garden mint",
            "linen from a sun-warm cupboard"
        ],
        "texture": [
            "wool blanket softened by years",
            "cotton sheets fresh from the line",
            "the smooth back of a teaspoon",
            "a worn wooden banister",
            "moss along a north wall",
            "river-stones rounded by years",
            "the velvet inside an old book",
            "warm bread under a clean cloth"
        ],
        "slow_verb": [
            "drift", "settle", "soften", "rest",
            "fold", "lean", "ease", "loosen",
            "let go", "slow", "quiet", "still"
        ],
        "calm_emotion": [
            "a small unhurried gladness",
            "the kind of ease you forget you can feel",
            "a quiet that doesn't need to be earned",
            "a softness that asks nothing of you",
            "the slow returning of warmth",
            "a gentleness with no errand",
            "the safety of being unobserved",
            "the comfort of being exactly where you are"
        ],
        "warm_object": [
            "a lit lamp", "a low fire", "a kettle's last steam",
            "a candle in a saucer", "the inside of a kept room",
            "a copper bowl catching light", "an open book under a reading lamp"
        ],
        "small_creature": [
            "a black cat with one slow blink",
            "a sparrow folding into the eaves",
            "a grey moth at a window",
            "a small dog already asleep",
            "a hedgehog on its slow round"
        ],

        // ── villageWalk ───────────────────────────────────────────────────
        "village_building": [
            "a bakery just closing", "a tea shop with warm windows",
            "a stationer with a single lamp left on",
            "a small bookshop returning chairs to their corners",
            "a cobbler's window full of finished work",
            "a green-grocer rolling shutters down halfway",
            "a chapel with the lights low, no bells tonight",
            "a public library finishing its quietest hour"
        ],
        "village_person": [
            "an older man walking a small calm dog",
            "a woman sweeping the last of the day from her stoop",
            "two friends saying goodnight without hurrying",
            "a child being carried home, half-asleep already",
            "a baker carrying a tray past a window",
            "a postman finishing the last quiet street"
        ],
        "village_path": [
            "a stone street worn round in the middle",
            "a cobbled lane where the streetlamps lean",
            "a row of low houses leaning into each other",
            "the small square the town keeps",
            "the bridge with the moss on its undersides",
            "the alley behind the bakery, smelling of flour"
        ],

        // ── cozySciFi ─────────────────────────────────────────────────────
        "ship_part": [
            "the long quiet corridor", "the observation deck",
            "the galley, where someone has left tea steeping",
            "the greenhouse module, lit low for sleep cycle",
            "the reading nook by the cargo hatch",
            "the small library at the end of B-deck",
            "the warm engine room, humming to itself"
        ],
        "ship_view": [
            "a slow nebula like blue cotton",
            "a small green planet half-asleep below",
            "the long arc of a quiet moon",
            "a star field that doesn't move quickly",
            "a faint aurora on the planet's day-side",
            "a comet, kind and unhurried"
        ],
        "ship_crewmate": [
            "the navigator humming the same three notes",
            "the cook still at the galley counter, kind-eyed",
            "the engineer asleep against a warm panel",
            "the medic reading something old",
            "the captain, off-duty, smiling at nothing in particular"
        ],

        // ── gentleMystery ─────────────────────────────────────────────────
        "mystery_clue": [
            "a postcard tucked into a fence",
            "a single chess piece on a low wall",
            "a key on a windowsill, small and clean",
            "a folded map with one ink-circle on it",
            "a library card placed under a stone",
            "a teaspoon left on the bench beside the river"
        ],
        "mystery_setting": [
            "the lane behind the old hotel",
            "the closed end of the harbour",
            "the quiet back garden of the museum",
            "the room above the bookstore",
            "the long bench along the canal",
            "the empty little tea-room at the station"
        ],
        "mystery_companion": [
            "an old detective who never raises her voice",
            "a soft-spoken librarian who knows everyone",
            "a friend who never finishes their tea",
            "a small dog that always finds the path",
            "a kind night-clerk who's seen this before"
        ],

        // ── natureDoc ─────────────────────────────────────────────────────
        "forest_tree": [
            "a tall pine, breathing the day out",
            "an old oak the moss has half-covered",
            "a young birch, pale and quiet",
            "a cedar whose lowest branches make a room",
            "a willow, slow and undecided"
        ],
        "forest_creature": [
            "a heron unmoving at the water's edge",
            "a fox the color of evening",
            "an owl, soft as a held breath",
            "a deer that doesn't run, only watches",
            "a rabbit folded into the long grass",
            "a small woodland mouse putting itself to bed"
        ],
        "forest_water": [
            "a stream the size of a hand",
            "a slow river that knows the way",
            "a black pool reflecting the high branches",
            "a wide lake holding the last light",
            "a waterfall that has been doing this forever"
        ],
        "forest_sound": [
            "the long slow exhale of pines",
            "moss absorbing footstep after footstep",
            "wind threading itself through high needles",
            "the small percussion of fern against fern",
            "an owl's question, asked and not answered"
        ]
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Templates (per genre, per scene role)
    // ──────────────────────────────────────────────────────────────────────

    enum SceneRole: String, CaseIterable {
        case opening, arrival, sensory, companion, action, reflection, closing
    }

    /// Each genre defines an ordered list of (role, templates) tuples.
    /// Roles run in this order to produce a coherent ~7-paragraph story.
    static let scenes: [Genre: [(SceneRole, [String])]] = [

        .villageWalk: [
            (.opening, [
                "{NAME}, you and I are walking the long way home through {CITY}. It's {time_of_day}, and {weather} has settled over the streets. The air carries {scent}, and from somewhere ahead comes {soft_sound}. Nothing here is in a hurry, and we don't have to be either.",
                "Tonight in {CITY}, we take the slow streets. {time_of_day} — the kind of hour {CITY} keeps for itself. {weather}. {NAME}, no one out here needs anything from us. We can {slow_verb} as we walk.",
                "{NAME}, the day has finally agreed to end. {CITY} is closing the way it always does — slowly, kindly. {weather}, {time_of_day}, and {scent} drifting from someone's open window. We have nowhere to be."
            ]),
            (.arrival, [
                "We turn a corner and find {village_path}. There's {village_building} on the left, the lamp inside the color of {warm_color}. {village_person} passes the other way and nods, the small civic kindness of a town at this hour.",
                "The street opens onto {village_path}. {village_building} is just here — you can smell it before you see it. Across from it, {village_person}, going the slow way themselves.",
                "Past the corner, {village_path} runs ahead in a long quiet line. {village_building} sits with its windows {warm_color}. {village_person} is already partway home."
            ]),
            (.sensory, [
                "Notice the {texture} of the wall under your fingertips as we pass. The lamps overhead are {warm_color}; the puddles, where they're left, are {cool_color}. Somewhere — through a window, around a corner — {soft_sound}, almost too soft to follow.",
                "There's so little to attend to: {scent} in one block, {soft_sound} in the next, the {texture} of the railings as you trail a hand along them. The light has gone {warm_color}, the shadows {cool_color}. {NAME}, your shoulders are already lower than they were a minute ago.",
                "The shop windows are {warm_color}, the cobbles {cool_color}. You catch {scent} drifting from a kept kitchen, then {soft_sound} from a room above. Everything is on its quietest setting."
            ]),
            (.companion, [
                "{village_person} stops a moment to greet a neighbor. They've known each other a long time. You don't need to hear what they say — only that it's said gently, the way good evenings are made of small unimportant kindnesses.",
                "{village_person} crosses our way once more, this time with a wave that means nothing more than goodnight. {NAME}, in {CITY}, even the strangers tonight are the friendly kind.",
                "From a doorway, {village_person} watches the street with the relaxed attention of someone who lives here. They look at us the way a town looks at its own."
            ]),
            (.action, [
                "We pause by {village_building}, just long enough to feel the warmth from inside leak out into the street. {NAME}, you used to do this — to {USER_ACTIVITY} at evenings like this. The memory of it is {calm_emotion}.",
                "There's a low bench, and we take it. The bricks behind us are still warm from the day. {NAME}, this is the kind of pause your old habit of {USER_ACTIVITY} would have led to. {calm_emotion} settles in the shoulders.",
                "We walk on, and your steps sync slowly to mine. Each one a little softer. The way they used to during {USER_ACTIVITY}. {calm_emotion} — that, but quieter."
            ]),
            (.reflection, [
                "{NAME}, nothing more is asked of you tonight. You've done everything that needed doing today, and the parts you didn't get to are not actually emergencies. The street agrees. {CITY} agrees.",
                "Whatever was loud in your head a few hours ago, the street has taken some of it. The lamps don't need you to fix anything. They're just on. They'll stay on. {NAME}, you can {slow_verb} now.",
                "Whatever you were carrying, the slow streets are holding some of it for you. {NAME}, you don't have to lift it again until tomorrow."
            ]),
            (.closing, [
                "We've reached the last quiet corner. The lamp here is {warm_color}, and the air is {weather}. {soft_sound} from somewhere small and warm. {NAME}, you can {slow_verb} now. Nothing else has to happen tonight.",
                "We stop at the small square. {warm_object} in a window across the way. {NAME}, your day is over. {CITY} has put itself away, and you can do the same. {calm_emotion} — let it stay.",
                "{NAME}, this is where the walk ends. {weather}, {soft_sound}, and the kept warmth of a closed-up town. You can {slow_verb} from here. There's nothing more."
            ])
        ],

        .cozySciFi: [
            (.opening, [
                "{NAME}, the ship is on its sleep cycle. Lights have eased to {warm_color}, and from somewhere two decks down, {soft_sound}. Outside, {ship_view}. We have a long quiet shift, and nothing pressing.",
                "It's {time_of_day} ship-time. The corridors are at {warm_color} half-light, the way they keep them when the crew is meant to rest. {NAME}, {ship_view} drifts past the windows of {ship_part}.",
                "{NAME}, our small ship is between systems. The hum is gentle — barely there. {ship_view} is unhurried out the long windows. There's tea somewhere. We're not on shift tonight."
            ]),
            (.arrival, [
                "We take the slow route to {ship_part}. The bulkheads are {cool_color}, the lamps {warm_color}. Someone has left a blanket on the bench by the viewport — that's the kind of crew this is.",
                "We drift toward {ship_part}. The carpet here is older than most of the crew, soft underfoot. The view at the end of the corridor is {ship_view}.",
                "{ship_part} is the warmest room tonight. {NAME}, when we arrive, {ship_crewmate} has already pulled out a second cup."
            ]),
            (.sensory, [
                "The hum here is at the frequency you fall asleep in. The light is {warm_color}, the metal {cool_color}, and the air is gently warm — old crew habit, that. From the corridor, {soft_sound}, then nothing. {NAME}, you can {slow_verb} into the bench.",
                "Notice the {texture} of the bench-cushion, the way the warm air moves slowly across the back of your hand. The console is at {warm_color}, the floor at {cool_color}. {soft_sound} from the galley — that's just the kettle.",
                "The whole deck is set to half-light. {scent} drifts in from the galley. The viewport shows {ship_view}, very slow."
            ]),
            (.companion, [
                "{ship_crewmate} arrives without saying much. That's the rule on the night-watch — talk only if there's something worth saying, and there usually isn't. They sit. We sit. {NAME}, that's enough.",
                "{ship_crewmate} stops by, hands you something warm, doesn't ask how you are because we don't do that on this ship at this hour. They go on their slow rounds.",
                "{ship_crewmate} is in the next bay, doing very little, very well. They lift a hand. We lift one back. {calm_emotion}."
            ]),
            (.action, [
                "{NAME}, this used to be the part of the day you'd {USER_ACTIVITY}. The ship doesn't have your old kitchen, but it has its own version of warm and small and yours. You can let it count.",
                "We take the long way through {ship_part}. {NAME}, the way you'd take the long way during {USER_ACTIVITY} when you were younger. The body remembers the rhythm, even out here.",
                "There's a panel of warm yellow lights — old, kept just because the crew likes them. We watch them the way you'd watch a candle while you {USER_ACTIVITY}. {calm_emotion}."
            ]),
            (.reflection, [
                "Nothing on the bridge needs anyone tonight. The ship is doing its quiet competent thing. {NAME}, that goes for you too. You can {slow_verb}.",
                "The galaxy is mostly asleep out there. So are most of our crew. The ship is small and warm and {NAME}, you don't have to keep watch.",
                "{NAME}, this is one of those nights the ship gives back. No alarms. No course corrections. {calm_emotion}."
            ]),
            (.closing, [
                "{ship_view} keeps moving very slowly. The lights here are {warm_color}. {soft_sound} from somewhere familiar. {NAME}, you can {slow_verb} into the cushion. The ship has us.",
                "We stay in {ship_part} until our eyes start to do that thing they do. {NAME}, that's the cue. {calm_emotion}. Goodnight, traveler.",
                "The viewport is {ship_view} and the ship is {warm_color}-lit and warm. {NAME}, you can let go now. We're somewhere safe."
            ])
        ],

        .gentleMystery: [
            (.opening, [
                "{NAME}, in {CITY}, there's a small odd thing nobody can quite explain — and tonight, very gently, we go and look at it. It's {time_of_day}, {weather}, and we have all the time in the world. We will not solve it tonight. That's the rule.",
                "Tonight's mystery, {NAME}, is the kind that doesn't want to be hurried. {time_of_day} in {CITY}, {weather}, and {soft_sound} from somewhere along the canal. Bring your slow attention.",
                "{NAME}, there's a quiet little puzzle in {CITY} that nobody minds being unsolved. We're going to walk to it, look at it carefully, and leave it to keep being a puzzle a little longer."
            ]),
            (.arrival, [
                "We arrive at {mystery_setting}. The light is {warm_color}, and the shadows are {cool_color}, and there — yes — there it is. {mystery_clue}. Just where the rumor said it would be.",
                "{mystery_setting} is exactly the kind of place this would be left. {weather} above, {scent} in the air, and on the bench, {mystery_clue}.",
                "We walk in past {mystery_setting}'s quiet entrance. The lamps are {warm_color}; the windows are {cool_color}. {mystery_clue} is here, of course. We'd half expected it."
            ]),
            (.sensory, [
                "Pick it up — gently. The {texture} of it, the slight weight, the way it's been kept clean. Around us, {soft_sound}, then nothing. {NAME}, this thing has been waiting calmly to be noticed.",
                "Notice the small things: the {texture}, the marking, the way it has been placed and not dropped. {scent} from a window above. {soft_sound} from the lane beyond.",
                "It's smaller than you'd think. The {texture} is gentler than you'd think. The mystery, like all the kind ones, is patient with us."
            ]),
            (.companion, [
                "{mystery_companion} arrives without rushing. They look at it. They smile. They've seen this kind of thing before, in {CITY}, more than once. They don't tell us what it means. They never do.",
                "{mystery_companion} is already there, hands in pockets. \"It's the third one this season,\" they say — and that's the whole conversation. We stand together, looking at it.",
                "{mystery_companion} comes to stand beside us, the way they always do. They tilt their head. They are good at not being in a hurry."
            ]),
            (.action, [
                "We replace it carefully — exactly where it was. The mystery isn't ours to take. {NAME}, this part is the part you'd recognize: a quiet handling, the kind of attention you used to give to {USER_ACTIVITY}. The same hands. The same care.",
                "We leave it for the next person. That's the etiquette in {CITY}. {NAME}, the hands you put it back with are the same hands that {USER_ACTIVITY}. They remember how to be careful.",
                "We make a small note — only for ourselves — and let it be. Tomorrow it'll be someone else's quiet turn."
            ]),
            (.reflection, [
                "The unsolved is, sometimes, kind. It keeps a town interesting without ever asking anything of it. {NAME}, tonight you don't have to figure anything out either.",
                "Some questions are nicer kept than answered. {NAME}, tonight is one of those.",
                "Whatever this little clue is — it's not yours to fix. {calm_emotion}, that's what comes when you stop trying."
            ]),
            (.closing, [
                "{mystery_companion} walks part of the way back with us. We say goodnight at the corner. {weather}, {soft_sound}, {warm_object} in a window. {NAME}, you can {slow_verb} now.",
                "We leave {mystery_setting} the way we came. {NAME}, the case stays open and the night closes anyway. {calm_emotion}.",
                "We turn for home. {weather} above, {warm_color} lamps along the way. {NAME}, the puzzle is still patient. So can you be."
            ])
        ],

        .natureDoc: [
            (.opening, [
                "{NAME}, the forest at the edge of {CITY} is on its sleep cycle, the same as you. {time_of_day}. {weather}. The trees are easing themselves down for the night, and we are going to watch — quietly, the way the forest prefers.",
                "It's {time_of_day} on the slow side of the woods. {weather}. {NAME}, the forest doesn't mind us as long as we move at its pace. We move at its pace.",
                "{NAME}, tonight we're somewhere green. {weather}, {scent}, {soft_sound}. The forest is settling in for its long nightly stillness, and we are guests."
            ]),
            (.arrival, [
                "We come to a clearing. {forest_tree} stands at the far edge. The ground here is {texture}, and the air is {scent}. From somewhere down-slope, {forest_sound}.",
                "The path opens. {forest_tree} marks the clearing. {forest_water} is just past the rise — you can hear it before you see it.",
                "We arrive at the meeting of two paths. {forest_tree} is to your left, slow-breathing. {forest_water} is somewhere ahead. {weather} above the canopy."
            ]),
            (.sensory, [
                "Listen: {forest_sound}. Then a pause. Then {soft_sound} that's smaller still. The light filtering down is {warm_color}, the shadows {cool_color}, and the air carries {scent}. {NAME}, your breathing has already lengthened.",
                "Notice the {texture} of moss against your palm if you reach down. The light is {warm_color} where it gets through, {cool_color} where it doesn't. {forest_sound}.",
                "All of it is on its quietest setting: {forest_sound}, {scent}, the {texture} of bark. The forest is doing what it always does, very well."
            ]),
            (.companion, [
                "{forest_creature} is here. We don't move. They don't move. We agree, without needing to, that nothing about this moment needs to change.",
                "{forest_creature} watches us a moment, decides we're not the kind of trouble worth moving for, and goes back to whatever evening business they were on.",
                "{forest_creature} passes through the clearing the way only wild things do — without hurrying, without stopping. They are home."
            ]),
            (.action, [
                "{NAME}, you used to walk in places like this — slow, attentive, a bit like {USER_ACTIVITY}. The forest is a generous version of that. The body remembers.",
                "We take the long way past {forest_water}. The pace is the same one your hands used to keep when you would {USER_ACTIVITY}. The forest knows that pace too.",
                "{NAME}, we sit. The clearing is doing all the work. The way {USER_ACTIVITY} used to do all the work, when you were younger and quieter. {calm_emotion}."
            ]),
            (.reflection, [
                "The forest has done this every night for longer than anyone alive can remember. Tonight it's doing it for you, too. {NAME}, you don't have to do anything with that — just be in it.",
                "Nothing in this clearing is in a hurry. The pines aren't. The river isn't. {NAME}, you don't have to be either.",
                "The forest's whole job, tonight, is to be quietly itself. {NAME}, that's your job too. {calm_emotion}."
            ]),
            (.closing, [
                "The clearing keeps {forest_sound}. {weather} above the canopy. {NAME}, you can {slow_verb} into the moss. The forest knows the way home from here.",
                "We stop. The forest goes on without us. {NAME}, that's the kindest thing it does. {calm_emotion}. Goodnight.",
                "{forest_creature} is gone now, into wherever they sleep. {forest_sound}. {NAME}, you can {slow_verb}. We're already most of the way to morning."
            ])
        ]
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Title generation
    // ──────────────────────────────────────────────────────────────────────

    private static let titlesByGenre: [Genre: [String]] = [
        .villageWalk: [
            "The Long Way Home", "Lamp Streets", "After the Rain in {CITY}",
            "The Bakery's Last Light", "Slow Streets, {CITY}",
            "The Quiet Side of Town", "A Walk Past Closing Time",
            "{CITY}, Folded Up for the Night"
        ],
        .cozySciFi: [
            "The Night Watch, Off-Duty", "Two Decks Down",
            "The Galley After Hours", "A Slow Nebula",
            "Between Systems", "Lights at Half",
            "The Library at the End of B-Deck", "Crew on Sleep Cycle"
        ],
        .gentleMystery: [
            "The Postcard on the Fence", "A Key on a Sill",
            "Three This Season", "The Bench by the Canal",
            "An Unsolved Tuesday", "The Quiet Case",
            "Some Questions Keep Better", "The Lane Behind the Hotel"
        ],
        .natureDoc: [
            "The Forest, on Its Sleep Cycle", "A Heron, Unmoving",
            "The Slow Side of the Woods", "Moss and the Owl's Question",
            "Where the Pines Exhale", "The Clearing Keeps the Hour",
            "Two Paths, One Quiet One", "The River Knows the Way"
        ]
    ]

    static func title(for genre: Genre, profile: UserStoryProfile, rng: inout SeededRandom) -> String {
        let pool = titlesByGenre[genre] ?? ["Tonight's Story"]
        let raw = rng.pick(pool)
        return fill(raw, profile: profile, rng: &rng)
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Preview line (one-liner shown on the genre card)
    // ──────────────────────────────────────────────────────────────────────

    private static let previewByGenre: [Genre: [String]] = [
        .villageWalk: [
            "walking {CITY}'s oldest streets, the kind of evening you remember from {USER_ACTIVITY}…",
            "{NAME}, the long way home through {CITY}, with {weather} settling in…",
            "{CITY} after closing time, lamps still {warm_color}, no one in a hurry…"
        ],
        .cozySciFi: [
            "the ship is on its sleep cycle, {ship_view} drifting past the viewport…",
            "{NAME}, two decks down, {ship_crewmate} already poured a second cup…",
            "the long quiet corridor, lights at {warm_color}, nothing on the bridge tonight…"
        ],
        .gentleMystery: [
            "{NAME}, a small odd thing in {CITY} we won't solve tonight on purpose…",
            "{mystery_clue} on a bench, {weather} above, all the time in the world…",
            "the kind of case you keep instead of close. {CITY}, {time_of_day}…"
        ],
        .natureDoc: [
            "the forest at the edge of {CITY}, on its sleep cycle, the same as you…",
            "{forest_tree}, {forest_sound}, {weather}, no need to do anything with any of it…",
            "{NAME}, slow attention, like {USER_ACTIVITY} but greener…"
        ]
    ]

    static func previewLine(for genre: Genre, profile: UserStoryProfile, rng: inout SeededRandom) -> String {
        let pool = previewByGenre[genre] ?? ["a story for tonight…"]
        let raw = rng.pick(pool)
        return fill(raw, profile: profile, rng: &rng)
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Slot fill
    // ──────────────────────────────────────────────────────────────────────

    /// Replaces every `{slot}` in the body with a value drawn either from
    /// the user profile (for `NAME`/`CITY`/`USER_ACTIVITY`) or from a pool.
    /// Unknown slots are left intact so they're easy to spot in tests.
    static func fill(_ body: String, profile: UserStoryProfile, rng: inout SeededRandom) -> String {
        var out = body
        // greedy non-nested slot replace
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
                    // Leave unknown slot untouched but break the loop
                    // by replacing with the literal `[?key?]` so the regex
                    // no longer matches it.
                    out.replaceSubrange(range, with: "[?\(key)?]")
                    continue
                }
            }
            out.replaceSubrange(range, with: value)
        }
        return out
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Story assembly
    // ──────────────────────────────────────────────────────────────────────

    static func assembleStory(genre: Genre, profile: UserStoryProfile, rng: inout SeededRandom) -> [String] {
        guard let plan = scenes[genre] else { return [] }
        return plan.map { (_, templates) in
            let raw = rng.pick(templates)
            return fill(raw, profile: profile, rng: &rng)
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Combinatoric estimation
    // ──────────────────────────────────────────────────────────────────────

    /// Lower-bound count of distinct stories the grammar can produce for `genre`,
    /// counting template choice per role × pool size for every `{slot}` in
    /// the chosen templates. Multiplied across all roles. Conservative — we
    /// don't credit per-genre title and preview lines.
    static func combinations(for genre: Genre) -> Double {
        guard let plan = scenes[genre] else { return 0 }
        var total: Double = 1
        for (_, templates) in plan {
            // For each role we pick one template, then fill its slots.
            // Sum across templates is a lower bound on the role's contribution.
            var roleSum: Double = 0
            for tmpl in templates {
                roleSum += slotProduct(in: tmpl)
            }
            total *= max(roleSum, 1)
        }
        return total
    }

    private static func slotProduct(in body: String) -> Double {
        var product: Double = 1
        let pattern = try! NSRegularExpression(pattern: #"\{([A-Za-z_]+)\}"#)
        let ns = body as NSString
        let matches = pattern.matches(in: body, range: NSRange(location: 0, length: ns.length))
        for m in matches {
            let key = ns.substring(with: m.range(at: 1))
            switch key {
            case "NAME", "CITY", "USER_ACTIVITY":
                continue // user-provided, doesn't contribute to combinatoric space
            default:
                if let pool = pools[key], !pool.isEmpty {
                    product *= Double(pool.count)
                }
            }
        }
        return product
    }
}

/// Lightweight bag of profile values used during slot fill. Keeps the fill
/// function unit-testable without dragging the whole AppStore in.
struct UserStoryProfile: Equatable {
    let displayName: String
    let displayCity: String
    let displayActivity: String

    static let placeholder = UserStoryProfile(
        displayName: "friend",
        displayCity: "this city",
        displayActivity: "your slow evening habit"
    )
}
