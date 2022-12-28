return {
  display = {
    -- The name of your shop. This will appear at the top of your shop's screen.
    -- If webhooks are enabled, this will be the name of the webhook bot
    shopName = "A Denarius Shop",

    -- Set to true if you'd like items out of stock to be visible.
    showOutOfStockItems = true,
  },

  krist = {
    -- The name you would like to use for this shop.
    name = "junk.kst",

    -- The private key for the address above. This MUST be in raw-key format.
    privatekey = "",

    -- Advanced: Krist node URL. Requires trailing /
    node = "https://krist.dev/",
  },

  peripherals = {
    -- Chests to search for items
    chests = {""},

    -- The network name of the turtle
    networkName = "",

    -- The network name of the monitor to display the shop information on
    monitorSide = "left",
  },

  heartbeat = {
    -- Enable heartbeat
    enable = true,

    -- The side that the redstone lamp (or other) is on.
    side = "top",

    -- How often the "heart beats"
    interval = 2
  },

  stock = {
    -- The order that items will be rendered in. If you don't want to fiddle with this, you can comment out this line.
    order = {"dia", "pc", "oak", "stone"},

    -- Items you're selling
    items = {
      -- The slug for the item (where players pay to)
      dia = {
        -- The title of the item to display.
        title = "Diamond",
        -- The ID of the item
        name = "minecraft:diamond",
        -- Price of the item
        price = 3
      },
      oak = {
        title = "Oak Log",
        name = "minecraft:oak_log",
        price = 0.1
      },
      pc = {
        title = "Advanced Computer",
        name = "computercraft:computer_advanced",
        price = 5
      },
      stone = {
        title = "Stone",
        name = "minecraft:stone",
        price = 1
      }
    },
  },

  webhook = {
    -- A url to a Discord webhook to send logs.
    url = "",

    -- Your Discord ID. This will be pinged when an error occurs.
    ownerUserID = "",

    -- Toggle individual messages
    messages = {
      startup = true,
      sale = true,
      refund = true,
      error = true,
    }
  },

  -- Messages that will be used when a refund is issued
  messages = {
    nonExistant = "The requested item, %s, does not exist. Please try another item.",
    notInStock = "Sorry, the item \"%s\" is not in stock.",
    overpaid = "You overpaid for your purchase. You have been refunded %d Krist.",
    notEnoughInStock = "You ordered too many items, and not enough were in stock. You have been refunded %d Krist."
  },

  -- Advanced: Sound effects to be played when purchases commence
  soundeffects = {
    enabled = true,
    speaker = "speaker_0",
    purchaseFailed = "minecraft:entity.villager.no",
    purchaseSuccess = "minecraft:entity.villager.yes",
    dispensedItems = "minecraft:entity.item.pickup",
    allItemsDispensed = "minecraft:entity.player.levelup",
  },

  -- Profit sharing
  profitSharing = {
    -- The address to send
    ["k000000000"] = {
      -- Percentage
      percent = 0,
      -- Metadata (for donate meta requirements)
      meta = "cool=awesome"
    }
  },

  -- Advanced: Krist API debug
  debug = false
}
