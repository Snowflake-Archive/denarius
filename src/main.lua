local config = require("config")
local design = require("design")
local krist = require("krist")
local sha256 = require("sha256")
local includes = require("includes")
local strings = require("cc.strings")

local node = config.node
local wsURL
local ws
local stock = {}

local recheckStockTimer = os.startTimer(30)

local origPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

local headerLogoDrawFunc
local headerLogoLines

local pkey = ""

local function warn(...)
  term.setTextColor(colors.yellow)
  print(...)
  term.setTextColor(colors.white)
end

local function success(...)
  term.setTextColor(colors.green)
  print(...)
  term.setTextColor(colors.white)
end

-- Config check: krist
if config.krist.privatekey then
  if config.krist.privatekey:len() < 64 or config.krist.privatekey:len() > 68 then
    error("config error: invalid privatekey (must be rawkey format).")
  end

  pkey = config.krist.privatekey
elseif config.krist.walletpassword then
  pkey = sha256("KRISTWALLET" .. config.krist.walletpassword) .. "-000"
end

-- Config check: peripherals
for i, v in pairs(config.peripherals.chests) do
  if peripheral.wrap(v) == nil then error("config error: chest not found: " .. v) end
end

-- Config check: redstone
if config.heartbeat.side ~= "top" and
   config.heartbeat.side ~= "back" and
   config.heartbeat.side ~= "bottom" and
   config.heartbeat.side ~= "front" and
   config.heartbeat.side ~= "left" and
   config.heartbeat.side ~= "right" then
  error("config error: invalid heartbeat side: " .. config.heartbeat.side)
end

-- Config check: stock
if config.stock.order then
  for i, v in pairs(config.stock.order) do
    if config.stock.items == nil then 
      warn("config warning: " .. v .. " exists in order, but not in items, it will be ignored.")
    end
  end

  for i, v in pairs(config.stock.items) do
    if includes(config.stock.order, i) == false then 
      warn("config warning: " .. i .. " exists in items, but not in order, it will be ignored.")
    end
  end
end

-- Config check: sound effects
if config.soundeffects.enabled and peripheral.wrap(config.soundeffects.speaker) == nil then
  error("config error: speaker not found")
end

local kclient = krist:new({}, pkey, {}, true, config.krist.node, config.debug)

if design.header.logo then
  local f = fs.open(design.header.logo.path, "r")
  local data = f.readAll()
  f.close()

  if design.header.logo.type == "nfp" then
    local img = paintutils.parseImage(data)

    headerLogoLines = #img
    headerLogoDrawFunc = function(x, y)
      paintutils.drawImage(img, x, y)
    end
  elseif design.header.logo.type == "nft" then
    local nft = require("cc.image.nft")
    local img = nft.parse(data)
    headerLogoLines = #img

    headerLogoDrawFunc = function(x, y)
      nft.draw(img, x, y)
    end
  end
end

local function sfx(type)
  if config.soundeffects.enabled == false or config.soundeffects[type] == nil then return end

  local speaker = peripheral.wrap(config.soundeffects.speaker)

  if speaker then
    speaker.playSound(config.soundeffects[type])
  else
    error("A speaker is required for sound effects to work.")
  end
end

local function wsSend(type, message)
  if config.webhook.url and config.webhook.messages[type] then
    http.post(config.webhook.url, textutils.serialiseJSON({
      username = config.display.shopName,
      content = message
    }), { ["content-type"] = "application/json" })
  end
end

local function scan()
  stock = {}

  local function scanChest(side)
    local items = peripheral.call(side, "list")

    for i, v in pairs(items) do
      if v.nbt then 
        if stock[v.name .. "+nbt" .. v.nbt] then
          stock[v.name .. "+nbt" .. v.nbt] = stock[v.name .. "+nbt" .. v.nbt] + v.count
        else
          stock[v.name .. "+nbt" .. v.nbt] = v.count
        end
      else
        if stock[v.name] then
          stock[v.name] = stock[v.name] + v.count
        else
          stock[v.name] = v.count
        end
      end
    end
  end

  for i, v in pairs(config.peripherals.chests) do
    scanChest(v)
  end
end

local function draw(state)
  local m = peripheral.wrap(config.peripherals.monitorSide)
  m.setTextScale(design.textScale)
  local w, h = m.getSize()

  -- Main shop draw
  for pallete, color in pairs(design.colours) do
    m.setPaletteColour(pallete, color)  
  end

  -- Basic States
  if state and state.connecting == true then
    m.setBackgroundColor(colors.gray)
    m.clear()
    m.setTextColor(colors.lightGray)
    local text = "Starting..."
    m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), math.floor(h / 2 + 0.5))
    m.write(text)
  elseif state and state.maintenance == true then
    m.setBackgroundColor(colors.gray)
    m.clear()
    m.setTextColor(colors.lightGray)
    local text = "Denarius is in maintenance..."
    m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), math.floor(h / 2 + 0.5))
    m.write(text)
  elseif state and state.error == true then
    m.setBackgroundColor(colors.red)
    m.clear()
    m.setTextColor(colors.white)
    m.setCursorPos(1, 1)
    local native = term.current()
    term.redirect(m)
    print("Denarius encountered an error!!!")
    print()
    print(state.message)
    print()
    print(state.traceback)
    print()
    print("Please report this error to the shop's owner.")
    print("The computer will restart in " .. state.seconds .. " seconds...")
    term.redirect(native)
  else
    m.setBackgroundColor(design.background)
    m.clear()

    local y = 1

    -- header

    if design.header.logo then
      for i = 1, 1 + headerLogoLines + 2 * design.header.padding do
        m.setCursorPos(1, i)
        m.setBackgroundColor(design.header.background)
        m.clearLine()
      end

      local n = term.current()
      term.redirect(m)
      headerLogoDrawFunc(design.header.padding + 1, design.header.padding + 1)
      term.redirect(n)
      y = y + headerLogoLines + 2 * design.header.padding
    else
      for i = 1, 1 + design.header.padding * 2 do
        m.setCursorPos(1, i)
        m.setBackgroundColor(design.header.background)
        m.clearLine()
      end

      m.setCursorPos(1, 2)
      m.setTextColor(design.header.text)
      local text = design.header.title == "!inherit" and config.display.shopName or design.header.title
      if design.header.textAlign == "left" then
        m.setCursorPos(design.header.padding + 1, 1 + design.header.padding)
      elseif design.header.textAlign == "center" then
        m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), 1 + design.header.padding)
      elseif design.header.textAlign == "right" then
        m.setCursorPos(w - #text - design.header.padding + 1, 1 + design.header.padding)
      end
      m.write(text)

      y = y + design.header.padding * 2 + 1
    end

    -- Table Header
    m.setBackgroundColor(design.table.header.background)
    m.setTextColor(design.table.header.text)

    for i = 1, 1 + design.table.header.padding * 2 do
      m.setCursorPos(1, i + y - 1)
      m.setBackgroundColor(design.table.header.background)
      m.clearLine()
    end

    m.setCursorPos(2, y + design.table.header.padding)
    m.clearLine()
    m.write("Stock")

    m.setCursorPos(9, y + design.table.header.padding)
    m.write("Item")

    m.setCursorPos(w - 5, y + design.table.header.padding)
    m.write("Price")

    local maxw = 0
    for i, v in pairs(config.stock.items) do
      maxw = math.max(maxw, #config.krist.name + #i + 2)
    end

    m.setCursorPos(w - 5 - maxw, y + design.table.header.padding)
    m.write("Pay To")

    y = y + (2 * design.table.header.padding) + 1

    local rowA = design.table.rowA
    local rowB = design.table.rowB or design.table.rowA

    local idx = 1
    local order = config.stock.order

    if not order then
      order = {}
      for i, v in pairs(config.stock.items) do
        table.insert(order, i)
      end
    end

    for _, i in ipairs(order) do
      local v = config.stock.items[i]

      if v then
        m.setCursorPos(2, y)
        local stockValue = 0
        if v.nbt then
          stockValue = stock[v.name .. "+nbt" .. v.nbt] or 0
        else
          stockValue = stock[v.name] or 0
        end

        if stockValue > 0 or config.display.showOutOfStockItems then
          local rowType = idx % 2 == 0 and rowB or rowA

          for i = 1, 1 + rowType.padding * 2 do
            m.setCursorPos(1, i + y - 1)
            m.setBackgroundColor(rowType.background)
            m.clearLine()
          end

          if stockValue == 0 then m.setTextColor(rowType.stockEmpty)
          elseif stockValue <= 10 then m.setTextColor(rowType.stockCritical)
          elseif stockValue <= 20 then m.setTextColor(rowType.stockLow)
          else m.setTextColor(rowType.stock) end

          m.setCursorPos(2, y + rowType.padding)
          m.write(tostring(stockValue))

          m.setTextColor(colors.gray)
          m.setCursorPos(9, y + rowType.padding)
          m.write(v.title)

          m.setCursorPos(w - 5, y + rowType.padding)
          m.write("K" .. tostring(v.price))

          m.setCursorPos(w - 5 - maxw, y + rowType.padding)
          m.write(i .. "@" .. config.krist.name)

          y = y + (2 * rowType.padding) + 1

          idx = idx + 1
        end
      end
    end

    -- footer
    m.setTextColor(design.footer.color)

    local lines = strings.wrap(design.footer.content, w - 2)
    local footerHeight = #lines + 2 * design.footer.padding
    local footerTop = h - footerHeight + 1

    for i = 1, footerHeight do
      m.setCursorPos(1, h - i + 1)
      m.setBackgroundColor(design.footer.background)
      m.clearLine()
    end

    for i, line in pairs(lines) do
      m.setCursorPos(2, footerTop + i)
      m.write(line)
    end
  end
end

local function executeTransaction(e)
  local tx = e[2]

  local reader = kclient.kristmeta:new(tx.metadata)
  local value = tx.value

  if tx.to ~= kclient.address or reader:get("name") ~= config.krist.name:gsub(".kst", "") then return end

  local slug = reader:get("target")
  local returnaddr = tx.from
  local item = config.stock.items[slug]

  if reader:get("return") then returnaddr = reader:get("return") end

  -- Check if item is valid
  if item == nil then
    sfx("purchaseFailed")
    print(slug .. " requested, but does not exist. Refunding player.")
    wsSend("refund", (":arrows_counterclockwise: Refunding %s %d Krist, item does not exist"):format(returnaddr, value))

    return nil, returnaddr, value, returnaddr .. ";message=" .. config.messages.nonExistant:format(item)
  end

  -- Check if item is in stock
  if stock[item.name] == nil then
    sfx("purchaseFailed")
    print(slug .. " requested, out of stock")
    wsSend("refund", (":warning: Refunding %s %d Krist, %s is out of stock"):format(returnaddr, value, item.title))

    return nil, returnaddr, value, returnaddr .. ";message=" .. config.messages.notInStock:format(item.title)
  end

  print("Purchase received!", returnaddr, "purchasing", slug, "for", value)
    
  -- Purchase successful!
  sfx("purchaseSuccess")

  local amount = math.floor(value / item.price) -- Amount of items that the player requested
  local available = stock[item.name] -- Amount of items the player requested
  local dispense = amount -- Amount of items to dispense
  local returnAmount = math.floor(value - amount * item.price) -- Amount of money to return to player
  local returnMessage = ""
  local remainingToDispense = dispense

  wsSend("sale", (":moneybag: %s purchased %d %s for %d Krist. Stock of this item is now %d."):format(returnaddr, remainingToDispense, item.name, value, available - dispense))

  -- Dispense items
  for _, c in pairs(config.peripherals.chests) do
    for s, v in pairs(peripheral.call(c, "list")) do
      if v.name == item.name then
        peripheral.call(c, "pushItems", config.peripherals.networkName, s, math.min(v.count, remainingToDispense), 1)
        turtle.select(1)
        turtle.drop(64)

        sfx("dispensedItems")
        remainingToDispense = remainingToDispense - v.count
        if remainingToDispense <= 0 then break end
      end
    end

    if remainingToDispense <= 0 then break end
  end

  sfx("allItemsDispensed")
  scan()
  draw()
  success("Dispensed all " .. dispense .. " items")

  -- If items are reamaining, then we refund the player
  if remainingToDispense >= 1 then
    returnAmount = returnAmount + math.floor(remainingToDispense * item.price)
    returnMessage = config.messages.notEnoughInStock:format(returnAmount)
    print("Issuing refund of " .. returnAmount .. ", ran out of stock")
    wsSend("refund", (":arrows_counterclockwise: Refunding %s %d Krist, ran out of stock"):format(returnaddr, returnAmount))
  elseif returnAmount >= 1 then
    returnMessage = config.messages.overpaid:format(returnAmount)
    print("Issuing refund of " .. returnAmount .. ", user overpaid")
    wsSend("refund", (":arrows_counterclockwise: Refunding %s %d Krist, user overpaid"):format(returnaddr, returnAmount))
  end

  if returnAmount >= 1 then
    return value - returnAmount, returnaddr, returnAmount, returnaddr .. ";message=" .. returnMessage
  end

  return value
end

xpcall(function()
  scan()
  draw{connecting = true}
  kclient:websocketStart()
  draw()

  local function startWebsocket()
    wsSend("startup", (":white_check_mark: %s has started up!"):format(config.display.shopName))
    success("Connected to websocket!")
    print("Address is " .. kclient.address)
    term.setTextColor(colors.lightGray)
    print("MOTD:", kclient.misc:getMotd().motd)
    term.setTextColor(colors.white)
    kclient:start()
  end

  local function events()
    while true do
      local e = {os.pullEventRaw()}

      if e[1] == "krist_transaction" and e[2] and e[2].metadata then
        local spent, returnAddr, returnAmount, meta = executeTransaction(e)
        
        if spent and spent > 0 then
          for address, data in pairs(config.profitSharing) do
            local percent = data.percent / 100
            local sendAmount = math.floor(spent * percent)

            kclient.transactions:make(address, sendAmount, data.meta)
          end
        end

        if returnAddr and returnAmount and meta then
          local ok, err = kclient.transactions:make(returnAddr, returnAmount, meta)
          if not ok then
            wsSend(
              "error", 
              (":warning: Refund Error <@%s>!\nRefunding: %s, Amount: %d, Metadata: %s\n```%s\n%s```"):format(
                config.webhook.ownerUserId,
                returnAddr, returnAmount, meta,
                textutils.serialise(err)
              )
            )
          end
        end
      elseif e[1] == "terminate" then
        printError("Terminated")
        draw{maintenance = true}
        os.pullEvent = origPullEvent
        kclient:destroy()
        print("Goodbye!")
        break
      elseif e[1] == "timer" and e[2] == recheckStockTimer then
        scan()
        draw()
        recheckStockTimer = os.startTimer(30)
      end
    end
  end

  local function heartbeat()
    while true do
      redstone.setOutput(config.heartbeat.side, true)
      sleep(config.heartbeat.interval)
      redstone.setOutput(config.heartbeat.side, false)
      sleep(config.heartbeat.interval)
    end
  end 

  if config.heartbeat.enable == true then 
    parallel.waitForAny(startWebsocket, events, heartbeat)
  else
    parallel.waitForAny(startWebsocket, events)
  end
end, function(err)
  kclient:destroy()
  os.pullEvent = origPullEvent
  local traceback = debug.traceback()
  wsSend("error", (":x: Shop Crashed <@%s>!\n```%s\n%s```"):format(config.webhook.ownerUserID, err, traceback))

  for i = 30, 1, -1 do
    draw{error = true, message = err, traceback = traceback, seconds = i}
    sleep(1)
  end
  os.reboot()
end)