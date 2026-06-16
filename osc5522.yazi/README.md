# Copy / Paste using OSC 5522

Using the magic of Kitty's OSC 5522 we can copy/paste files beween yazi and gui programs!

## Install

```bash
ya pkg add UnnaturalTwilight/yazi-plugins:osc5522
```

Add to init.lua:
```lua
require("osc5522"):setup()

function Root:clipboard(event)
    require("osc5522"):handle_clipboard_event(event)
end
```
