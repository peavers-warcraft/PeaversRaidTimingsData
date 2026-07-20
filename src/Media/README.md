# src/Media

`Icon.tga` is **missing** and must be added here.

`PeaversRaidTimingsData.toc` already declares:

```
## IconTexture: Interface\AddOns\PeaversRaidTimingsData\src\Media\Icon.tga
```

so the only outstanding work is dropping the art file in at exactly that name and
path — no TOC change is needed. Until then WoW renders the addon with no icon in
the AddOns list, which is cosmetic only and breaks nothing.

Requirements, matching the other Peavers data addons (see `PeaversGetThereData/src/Media/Icon.tga`):

- Format: uncompressed 32-bit TGA
- Dimensions: power of two (the siblings ship 1024x1024)
- Filename: `Icon.tga`, case as written

The master icon lives in this repo; the peavers.io site derives its own downsized
copy at build time, so a large file here is expected and correct.
