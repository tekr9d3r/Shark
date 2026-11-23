import Toybox.Graphics;
import Toybox.Lang;

// Dc.setColor() takes a raw 24-bit 0xRRGGBB integer, so these are exact hex
// values. Full-colour AMOLED devices render them as written; the 64-colour
// MIP panels quantize, which is why no signal leans on a near-neighbour hue.
//
// One idea: you are swimming in the abyss, framed by the shark's own jaws.
// The water is near-black at depth and lifts to a cold teal at the surface.
// Bone and blood are the only warm colours on the screen - the teeth on the
// rim and the red that spreads through the water as the shark closes - so
// warmth always means danger.
module Palette {
    const BLACK = 0x000000;
    const INK = 0x04090d;

    // Bone, for teeth, wordmark and hero numbers.
    const BONE = 0xf3ead6;
    const BONE_SHADE = 0xb9ad92;
    const BONE_DIM = 0x8d8471;

    // Blood: gum, fresh, dark.
    const GUM = 0x3d0508;
    const GUM_LIGHT = 0x6e0a10;
    const BLOOD = 0xc4141d;
    const BLOOD_BRIGHT = 0xff2d35;
    const BLOOD_DARK = 0x7a0a10;

    // Cold accents.
    const ICE = 0x6fe6ff;
    const TEAL = 0x1fb5a8;
    const AMBER = 0xffae1f;
    const PALE = 0xa9c1cc;
    const MUTED = 0x5d7684;
    const PANEL = 0x123040;

    // Water by depth band, surface first, per danger stage. Each stage is
    // four bands drawn top to bottom; on MIP they quantize into fewer steps
    // and still read as "deeper is darker".
    const SKY = 0x02080d;
    const WATER_CRUISE = [0x0f5068, 0x0a3a50, 0x06263a, 0x031524];
    const WATER_CLOSING = [0x17474d, 0x10353b, 0x0a2429, 0x051418];
    const WATER_JAWS = [0x8a1016, 0x660b10, 0x46070b, 0x260306];
    const SKY_JAWS = 0x160203;

    const SURFACE_CRUISE = 0x2b8aa6; // the bright lip of the surface wave
    const SURFACE_CLOSING = 0x3a7f7f;
    const SURFACE_JAWS = 0xd8333a;

    const SHAFT = 0x0d4660;    // light shafts, cruise only
    const BUBBLE = 0x5fb6cf;
    const BUBBLE_JAWS = 0xff8a8e;

    // The shark: steel back, pale belly, a black eye with a cold glint.
    const SHARK_BODY = 0x6a8293;
    const SHARK_BODY_CLOSING = 0x4c6273;
    const SHARK_BODY_JAWS = 0x1b262e;
    const SHARK_BACK = 0x3e5262;
    const SHARK_BELLY = 0xdde6ea;
    const SHARK_EYE = 0x05090c;
    const SHARK_EYE_JAWS = 0xff2d35;
    const MOUTH = 0x2a0306;

    // The suit is dark but carries a bright rim, so the figure reads against
    // both the near-black sky and the teal water.
    const SWIM_CAP = 0xffd23f;
    const SWIM_CAP_STRIPE = 0xff7a1a;
    const SWIM_BODY = 0x1c2e3a;
    const SWIM_BODY_LIT = 0x2a4555;
    const SWIM_RIM = 0xc8f1ff;
    const GOGGLE = 0x33e0ff;

    // The fin breaking the surface: a lit face, a shaded face, a foam rim.
    const FIN_LIT = 0x9fb6c6;
    const FIN_SHADE = 0x52697a;
    const FOAM = 0xe6f4f8;

    // Menus.
    const CHIP_FILL = BLOOD;
    const CHIP_LABEL = BONE;
}
