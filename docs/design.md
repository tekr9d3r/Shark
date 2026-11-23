# Shark — design notes

Reference for the decisions that aren't obvious from the code, and the
platform limits they were made against.

## The hunt, exactly

No distance, no target pace. Two phases:

**Scent (0-90 s).** No shark. The model ignores the first 30 s (wading in,
GPS fix, finding a rhythm) and takes the average speed over the next 60 as
your easy pace `v0`, clamped to 0.5-2.0 m/s so a missing fix can't produce
a shark that barely moves.

**Hunt.** The shark is released `50 s x v0` behind you and each second:

```
paceRead  += (liveSpeed - paceRead) x dt / 600      (clamped 0.5..2.0)
margin     = 0.17 + max(0, t - 720) / 60 x 0.08     (the frenzy after 12 min)
sharkSpeed = paceRead x (1 + margin)
gap        = yourDistance - sharkDistance           (caught at 2 m)
```

Why this shape:

- **Pace-free.** Head start and speed are both multiples of *your* pace, so
  the catch time depends only on how your pace changes relative to your
  own easy pace, not on whether you swim 1:40 or 3:00 per 100 m.
- **Build-up is rewarded, never permanently.** Swim 10% faster and the shark,
  still reading your old pace, is barely gaining. Over ~10 minutes it
  re-reads you and the margin is back. That pushes a warm-up toward a
  steady build, which is the whole point.
- **It always ends.** The frenzy term guarantees a catch by about 15
  minutes even for a swimmer who keeps accelerating.

Simulated (constant pace after the scent window; `liveSpeed` through the same
25 s EMA the app uses):

| pace vs. easy | caught at |
|---|---|
| 0.9x | 4.6 min |
| 1.0x | 6.2 min |
| 1.05x | 7.5 min |
| 1.1x | 9.3 min |
| 1.15x | 11.4 min |
| 1.2x | 13.3 min |
| 1.3x | 15.2 min |

All of these numbers live in `SwimConstants`.

### Danger staging

`dangerFraction` maps the gap from the head start (0.0) down to the catch
threshold (1.0), and `dangerStage` cuts it at 0.5 and 0.82. Both are read by
`SwimScreen` (fang length, water, shark) and `Feedback` alike, so the picture
and the buzz never disagree. A gap larger than the head start (you surged)
reads as 0.

## Distance

`Activity.getActivityInfo().elapsedDistance` off an open-water recording
session (GPS). It is **monotonically clamped**: a wrist under water loses the
fix constantly and can revise distance downward when it returns, and distance
may stall but never go backwards, which would hand metres to the shark.

Pace is an exponential moving average over ~25 s (`PaceTracker`), because
open-water GPS arrives in ragged clumps whenever the wrist clears the surface.

## The look

- **Jaws frame** (`Jaws.mc`): gum ring + radial fangs (rows along each edge
  on rectangles). Fang length = `14 + 38 x bite` baseline px; on the swim
  screen `bite = 0.15 + 0.85 x danger`, plus a chomp in the jaws stage. A
  deterministic hash picks which teeth are bloody (`blood` of every ten) and
  half of those drip on their own phase.
- **Water** (`Backdrop.mc`): four depth bands per stage fake a gradient on
  AMOLED and collapse to fewer steps on MIP; a sine surface with a bright lip;
  light shafts only in calm water; bubbles rising.
- Bone and blood are the only warm colours, so warmth always means danger.

## Platform constraints worth remembering

**Three screen shapes, ~2.2x resolution span.** Round, semi-octagon
(flattened edges) and rectangle, from 208 px to 454 px. Nothing is positioned
in absolute pixels; everything goes through `ScreenMetrics.px()` against a
416 px baseline, and every hero number is measured with `fitNumberFont` at
draw time — the same font enum member is a wildly different size across the
range.

**Nine arguments per method** on the low-end devices (this bit
`drawNumberWithUnit`, which had ten). Keep signatures short; pass state as
object properties where it gets tight.

**No `private` on module-level functions** — only on class members.

**64-colour MIP panels** on much of the lineup: no usable gradients or alpha.
Selection is never signalled by colour alone — the selected pill is also the
only filled shape and is drawn larger.

**No clipping region** in `Dc`. The shark's pale belly is a flattened ellipse
tucked inside the body rather than a clipped half.

**Non-ASCII glyphs are a risk.** A middot separator draws as a tofu box on a
device whose font lacks it, so separators are plain spacing.

**No speaker on any target device.** `Attention.playTone` plays from a fixed
system enum, identical in every app, and is inaudible under water regardless.
Vibration is the only authored channel.

**Battery.** The app runs continuously over a whole workout, so animation is
a separate 5 fps clock that is stopped outright while paused. Menus, cards
and the result screen animate (the fang drips): no swim is running on the
first two, and the session is already saved by the result.

## Flow

```
Home ─┬─ How To (3 cards) ─→ Home
      └─ START
             ↓
           Swim: scent 90 s → hunt  ⇄ Paused
             ↓  (eaten / ended from menu)
           Result ─→ Home
```

BACK during a swim opens the in-activity menu rather than quitting, because
the default root-view behaviour would silently abandon the recording.
