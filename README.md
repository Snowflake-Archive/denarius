# Denarius

Denarius is a highly-configurable Krist-based shop for modern ComputerCraft. It allows you to easily set up your own shop to sell items in modern ComputerCraft.

## Setup

Download the `denarius.lua`, `design.lua` and `config.lua` files:

```
wget https://raw.githubusercontent.com/Snowflake-Software/denarius/main/denarius.lua startup.lua
wget https://raw.githubusercontent.com/Snowflake-Software/denarius/main/config.lua config.lua
wget https://raw.githubusercontent.com/Snowflake-Software/denarius/main/design.lua design.lua
```

In the `config.lua` file, enter in your shop's name, the shops owner, your Krist credentials, and the items you will be selling. The config file should easily help you get started on making your shop.  
  
`design.lua` can be customized to personalize your shop. This file should also help you through it's process as well. 

## Config Parameters
### display
This section defines basic display parameters.
- `shopName`: The name of your shop. This will be displayed on the top of your shop with the default design, as well as Discord webhooks.
- `showOutOfStockItems`: If true, out of stock items will be shown on the monitor.

### krist
The information for where to send payments.
- `name`: The name for your shop to use, e.g. `snowflake.kst`
- `privatekey` OR `walletpassword`: The one that is uncommented will be which you use. `privatekey` is a standard Krist privatekey, and `walletpassword` is a KristWallet password. See https://docs.krist.dev/docs/wallet-formats.html for more about privatekeys and passwords.
- `node`: The Krist node to connect to. For most users, this should be `https://krist.dev`. Note that this should not include a trailing `/`

### peripherals
Where items are stored, the turtle is and the monitor side.
- `chests`: An array of connected storage mediums.
- `networkName`: The name of the turtle when connected to a wired modem.
- `monitorSide`: The side of the monitor that shop information will be displayed on.

### heartbeat
Enables a "heartbeat" to show the shop is operational.
- `enable`: If true, a redstone pulse will be emitted how ever often is specified in `heartbeat.interval`.
- `side`: The side to emit redstone signals on.
- `interval`: How often to pulse redstone (on/off interval)

### stock
Items for sale!
- `order` (optional): An array of slugs (where players pay to). If not defined, the order will be defined somehow.
- `items`: The array containing all of the items the shop is selling. See below for information on each entry.
  - The index of the item is the slug (where players pay to, e.g. `gold@snowflake.kst`)
  - `title`: The name that will be displayed on the screen.
  - `name`: The ID of the item, e.g. `minecraft:diamond`
  - `price`: The price of the item.
  - `nbt` (optional): The NBT hash of the item.

### webhook
A discord webhook where shop information will be sent to.
- `url` (optional): The webhook URL. If not defined, webhooks will not operate.
- `ownerUserId` (optional): Preferably your Discord ID, this will be pinged when the shop crashes.
- `messages` (optional): A table containing a list of messages to enable / disable.
  - `startup`: True to send messages when the shop starts up, false if not.
  - `sale`: True to send messages when a sale is made, false if not.
  - `refund`: True to send messages when a refund is issued, false if not.
  - `error`: True to send messages when the shop crashes OR an item is out of stock, false if not.

### messages
Customizable messages that will be sent when a user overpays, an item is out of stock, or it doesn't exist.
- `nonExistant`: The message sent when an item doesn't exist in the store's database
- `notInStock`: The message sent when an item is not in stock.
- `overpaid`: The message sent when a user overpays.
- `notEnoughInStock`: The message sent when not enough items are in stock.

### soundEffects
Sounds that will be played when things happen in the shop.
- `enabled` (optional): True to enable sound effects
- `speaker`: The side the speaker is on
- `purchaseFailed`: The sound that will be played when a purchase fails.
- `purchaseSuccess`: The sound that will be played when a purchase succedes.
- `dispensedItems`: The sound that will be played when a single item is dispensed.
- `allItemsDispensed`: The sound that will be played when all items have been dispensed.

### profitSharing
Share profits with different addresses
Indexes are the address to send to (e.g. kxxx...)
- `percent`: The integer percentage to send (0-100)
- `meta`: The metadata to send accompanying the payment

- `debug`: If set to true, extra information will be displayed.

## Building
Download the latest version of [mittere](https://github.com/Snowflake-Software/mittere), and run `mittere build`. An output file will be created in `denarius.lua`.

## Krist API
Denarius uses a currently work-in-progress Krist wrapped written by me. As stated, it is currently work-in-progress and not yet public. It will be as soon as it is fully complete!

## Notice

This program is currently in beta, and problems may arise. If any do, please contact znepb#1234 on Discord.

## Attributions
[sha256 by GravityScore](https://www.computercraft.info/forums2/index.php?/topic/8169-sha-256-in-pure-lua/)