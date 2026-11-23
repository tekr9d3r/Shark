# Shark

An open-water warm-up game for Garmin watches.

Press START and swim. After 90 seconds a shark is released behind you. It
learns your pace and hunts a little faster than you. Swim easy and it catches
you in about 6 minutes. Build the pace and you can hold it off for 10–15.

The watch buzzes as the shark closes in, so you don't need to look.

## Build

Needs the Garmin Connect IQ SDK and your own signing key at
`keys/developer_key.der`.

```sh
./build.sh fenix7
```

Copy the `.prg` from `dist/` to `GARMIN/APPS/` on the watch.
