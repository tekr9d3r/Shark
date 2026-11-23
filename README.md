# Shark

An open-water warm-up game for Garmin watches. Press START and swim. After
90 seconds a shark is released right behind you, and it hunts a little faster
than you swim. Stay at your easy pace and it catches you in about six
minutes. Build the pace and you can hold it off for ten to fifteen.

## How it plays

- **No setup.** One button: START. There is no distance to pick and no target
  pace to enter.
- **The scent window (first 90 s).** The shark is not in the water yet. It is
  reading your easy pace: the first 30 seconds (wading in, finding a GPS fix
  and a rhythm) are ignored, and the next 60 set the baseline. The screen
  counts down to the release.
- **The release.** Three hard knocks on the wrist. The shark starts 50
  seconds of *your* swimming behind you (about 40 m at 2:00 /100 m), so the
  game feels the same for a fast swimmer and a slow one.
- **The hunt.** The shark swims 17% faster than its read of your pace, and
  that read slowly drifts toward your live pace (10-minute time constant). A
  surge gains you ground for a few minutes, then the shark matches it. Building
  the pace buys time but never buys safety, which is what a warm-up should do.
- **The frenzy.** After 12 minutes the shark gets hungrier every minute, so
  the session always ends as a warm-up rather than turning into a workout.

Roughly when you get caught, whatever your speed:

| After the scent window you… | Caught at |
|---|---|
| ease off 10% | ~4.5 min |
| hold your easy pace | ~6 min |
| swim 5% faster | ~7.5 min |
| swim 10% faster | ~9.5 min |
| swim 15% faster | ~11.5 min |
| swim 20% faster | ~13.5 min |
| swim 30% faster | ~15 min (the frenzy) |

The score is how long you survived after the release. It's on the result
screen and saved to the activity as a custom FIT field.

## Inside the jaws

Every screen is framed by the shark's mouth: a gum ring at the bezel and a
row of fangs pointing in, some tipped with blood that slowly drips toward the
middle. On the swim screen the fangs are the danger meter. They lengthen
continuously as the shark closes and chomp in the last stage, so you can read
how close it is in peripheral vision.

Three stages of danger, cruising, closing and jaws, read the same on screen
and on the wrist:

- the water goes cold teal → murky green → blood red;
- the shark grows and rises until its jaws are open at the surface;
- **SWIM!** blinks at the top.

## Feel, not screens

A swimmer's face is in the water most of the time, so vibration is the real
interface:

| Buzz | Meaning |
|---|---|
| one short pulse | swim started, the shark is picking up your scent |
| three hard knocks | the shark is in the water |
| *silence* | it's far |
| one pulse, repeating | it just took another bite out of the gap |
| heartbeat, quickening | it's on you |
| one long buzz | eaten, swim over |

## Controls

- **SELECT**: START on the home screen; **pause** mid-swim (the shark freezes
  too).
- **UP/DOWN**: move through START / HOW TO / EXIT.
- **MENU or BACK during a swim**: Resume, End Activity, or Delete Activity
  (with a confirmation).

## Why it looks like this

Everything is drawn from `Graphics.Dc` primitives (polygons, ellipses, lines),
with no bitmap art. One codebase renders on round, semi-octagon and
rectangular screens and on AMOLED and 64-colour MIP displays with no
per-device assets. `ScreenMetrics` and `HudLayout` compute every position from
the device's resolution at runtime, and every hero number is fitted at draw
time.

## Supported devices

80 colour-screen devices across the Fenix, Forerunner, Venu, Instinct
(AMOLED), Epix, Enduro, Vivoactive, Marq, D2, Descent and Approach lines. See
[`manifest.xml`](manifest.xml).

## Project structure

```
source/
  SwimController.mc     State machine: home → swim → result
  SwimModel.mc          Pure 1-D hunt simulation (scent window, adaptive shark)
  SwimConstants.mc      Every tuning number for the hunt and danger staging
  DistanceSource.mc     GPS distance, clamped so it never goes backwards
  PaceTracker.mc        Smoothed live pace from bursty swim GPS
  Feedback.mc           Every vibration and tone in one place
  ActivityRecorder.mc   FIT session + custom gap / survived fields
  ui/
    Jaws.mc             The bloody fang frame
    Backdrop.mc         Depth-banded water, rolling surface, bubbles, light shafts
    Figures.mc          Procedural shark and swimmer
    Palette.mc          Abyss and blood
    Hud.mc              Measured text, hero fonts, pills
    *Screen.mc          One draw module per state
```

## Building

Requires the Garmin Connect IQ SDK and a local `keys/developer_key.der`
signing key (not checked in).

```sh
./build.sh                 # the representative device spread
./build.sh fenix7 venu3    # specific devices
```

Run a built `.prg` in the simulator with `monkeydo`, or copy it to
`GARMIN/APPS/` on the watch over USB to sideload it.
