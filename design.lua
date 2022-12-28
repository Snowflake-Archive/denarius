return {
  -- Monitor text scale
  textScale = 0.5,
  -- Background color
  background = colors.white,
  colours = {
    -- Header
    [colors.blue] = 0x99b2f2,
    -- Header Text, Main Background, Table A
    [colors.white] = 0xededed,
    -- Table Header
    [colors.gray] = 0x4c4c4c,
    -- Table B
    [colors.lightGray] = 0x999999,
    -- Table Text
    [colors.black] = 0x111111,
    -- Stock Low
    [colors.yellow] = 0xdede6c,
    -- Stock Critical
    [colors.orange] = 0xf2b233,
    -- Stock Empty
    [colors.red] = 0xcc4c4c,
  },
  header = {
    -- If set to !inherit, the config's shop name will be used.
    title = "!inherit",

    -- Logo and file. If used, title will not be displayed.
    -- Keep in mind the logo may not be 100% accurate if pallete colors are changed.
    -- logo = {
    --   -- Accepts either nfp or nft.
    --   type = "nft",
    --   path = "test.nft"
    -- },

    background = colors.blue,
    text = colors.gray,
    textAlign = "center",
    -- Padding, in pixels. This applys horizontally and vertically
    padding = 1
  },
  table = {
    header = {
      background = colors.gray,
      text = colors.white,
      padding = 1,
    },
    rowA = {
      background = colors.white,
      text = colors.black,
      padding = 1,
      stock = colors.lightGray,
      stockLow = colors.yellow,
      stockCritical = colors.orange,
      stockEmpty = colors.red
    },
    -- IF rowB is absent, rowA will be used.
    rowB = {
      background = colors.lightGray,
      text = colors.black,
      padding = 1,
      stock = colors.gray,
      stockLow = colors.yellow,
      stockCritical = colors.orange,
      stockEmpty = colors.red
    }
  },
  footer = {
    background = colors.blue,
    color = colors.gray,
    padding = 1,
    content = "Welcome to this shop! To make payments, send money using /pay, or KristWeb, to the item's Pay To address. This shop uses Denarius by znepb."
  }
}