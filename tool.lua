-- A simple command-line tool to add items to Denarius.

print("Select an option:")
print(" 1. Add item")
print(" 2. Exit")

local function includes(tbl, value)
  for i, v in pairs(tbl) do
    if v == value then return true end
  end
  return false
end

local ignoreLevel = { "minecraft:aqua_affinity", "minecraft:channeling", "minecraft:curse_of_binding", "minecraft:curse_of_vanishing", "minecraft:flame", "minecraft:infinity", "minecraft:mending", "minecraft:sulk_touch",  }

local _, key = os.pullEvent("char")

if key == "1" then
  print("Reading config...")
  local config = require("config")
  local f = fs.open("config.lua", "r")
  local content = textutils.unserialise(f.readAll():match("({.+});?$"))
  f.close()

  print("OK")
  print("Place item into first turtle slot, then press ENTER...")
  local key
  repeat _, key = os.pullEvent("key") until key == keys.enter

  if turtle.getItemDetail(1, true) == nil then error("No item") end

  local detail = turtle.getItemDetail(1, true)
  local nbt = detail.nbt

  turtle.drop()

  local suggestedName = detail.displayName
  local suggestedAddy = detail.displayName:lower():sub(1, 4)

  if detail.enchantments and #detail.enchantments > 1 then error("Only 1 enchant supported") end
  if detail.enchantments then
    print("Detected enchantment book!")
    suggestedName = ("%s Book"):format(detail.enchantments[1].displayName)

    if includes(ignoreLevel, detail.enchantments[1].name) then
      suggestedAddy = ("%s"):format(detail.enchantments[1].displayName:lower():sub(1, 4))
    else
      suggestedAddy = ("%s%d"):format(detail.enchantments[1].displayName:lower():sub(1, 4), detail.enchantments[1].level)
    end
  end

  write(("Enter name (%s): "):format(suggestedName))
  local nameread = read()
  name = nameread == "" and suggestedName or nameread

  write(("Enter addy (%s): "):format(suggestedAddy))
  local addyread = read()
  addy = addyread == "" and suggestedAddy or addyread

  write("Enter price: ")
  local price = tonumber(read())

  local tableToWrite = {
    title = name,
    name = detail.name,
    price = price,
    nbt = nbt
  }

  print("Write OK?")
  print(addy .. " = " .. textutils.serialise(tableToWrite))

  if config.stock.order then
    print("Detected order")
    for i, v in pairs(config.stock.order) do
      write(i .. " " ..  v ..  ", ")
    end

    write("\nWrite number to add at: ")
    local n = tonumber(read())
    table.insert(config.stock.order, n, addy)
    content.stock.order = config.stock.order
  end

  content.stock.items[addy] = tableToWrite

  local f = fs.open("config.lua", "w")
  f.write("return " .. textutils.serialise(content))
  f.close()
  print("Done!")
end