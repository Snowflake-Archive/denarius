-- bundle created using crunch
-- https://github.com/apemanzilla/crunch

local sources = {
	["main.lua"] = "--- Core module, contains utils and websocket related things\
-- @module core\
\
local krist = {}\
\
local userAgent = \"Krist Client on \" .. _HOST\
local jsonEncode = textutils.serialiseJSON\
local jsonDecode = textutils.unserialiseJSON\
\
--- TODO: blocks, lookup, names, transactions, docs, more util functions\
\
--- Utility Functions ---\
function krist:requireAuth()\
  if self.key == nil then error(\"This function requires logging in!\") end\
end\
\
function krist:dbug(...)\
  if self.debug then\
    print(\"[KRIST DEBUG] \", ...)\
  end\
end\
\
-- Utility function to handle a HTTP response.\
function krist:handleHTTP(h, err, errH)\
  if err then\
    error(err)\
    return\
  end\
\
  local data = h.readAll()\
  h.close()\
  return data\
end\
\
-- Utility function to GET data.\
function krist:get(url, auth, headers)\
  if auth then self:requireAuth() end\
  local headers = headers or {}\
  headers[\"User-Agent\"] = userAgent\
\
  self:dbug(\"GETting\", url)\
\
  return self:handleHTTP(http.get(self.endpoint .. url, headers))\
end\
\
-- Utility function to POST data.\
function krist:post(url, data, auth, headers)\
  if auth then self:requireAuth() end\
  local body = data or {}\
  local headers = headers or {}\
  headers[\"user-agent\"] = userAgent\
  headers[\"content-type\"] = \"application/json\"\
\
  if auth == true then\
    body.privatekey = self.key\
  end\
\
  self:dbug(\"POSTing\", url, \"with body\\n\", jsonEncode(body))\
\
  return self:handleHTTP(http.post(self.endpoint .. url, jsonEncode(body), headers))\
end\
\
-- Utility function to run a function if websockets are enabled.\
function krist:httpOrWebsocket(http, ws)\
  if self.ws then\
    return ws()\
  end\
\
  return http()\
end\
\
function krist:wsSend(type, body, cb)\
  if self.ws then\
    body.type = type\
    body.id = self.id\
\
    self.pendingCallbacks[self.id] = function(...) \
      if cb then cb(...) end \
    end\
    self.ws.send(jsonEncode(body))\
\
    self.id = self.id + 1\
\
    return self.id - 1\
  end\
\
  error(\"No websocket connected!\")\
end\
\
-- TODO\
function krist:parseTime(time)\
  local year, month, day, hour, min, sec, ms = time:match(\"(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)%.(%d%d%d)Z\")\
  return {\
    year = year,\
    month = month,\
    day = day,\
    hour = hour,\
    min = min,\
    sec = sec,\
    ms = ms\
  }\
end\
\
function krist:createUrlQuery(data)\
  local str = \"\"\
\
  local idx = 1\
  for i, v in pairs(data) do\
    if v ~= nil then\
      if idx == 1 then\
        str = (\"?%s=%s\"):format(i, v)\
      else\
        str = str .. (\"&%s=%s\"):format(i, v)\
      end\
\
      idx = idx + 1\
    end\
  end\
  \
  return str\
end\
\
---- Main Class ----\
function krist:new(o, key, events, noWS, endpoint, debug)\
  o = o or {}\
  setmetatable(o, self)\
  self.__index = self\
  self.key = key\
  self.endpoint = endpoint or \"https://krist.dev/\"\
  self.id = 0\
  self.debug = debug\
  self.pendingCallbacks = {}\
\
  self.misc = require(\"misc\"):new({}, self)\
  self.addresses = require(\"addresses\"):new({}, self)\
  self.transactions = require(\"transactions\"):new({}, self)\
  self.kristmeta = require(\"kristmeta\")\
\
  krist:dbug(\"Starting Krist API...\")\
  \
  if key then\
    self.address = self.misc:getV2Address()\
    self:dbug(\"Address is\", self.address)\
  end\
\
  if noWS then return o end\
  if events == nil then error(\"An array of events to subscribe to is required to use a WS. If you don't want to subscribe to any events, enter an empty array.\") end\
  krist:websocketStart()\
\
  for i, v in pairs(events) do\
    krist:wsSend(\"subscribe\", { event = v })\
  end\
\
  return o\
end\
\
-- Websocket Handling & Callbacks\
\
--- Logs in to Krist. This is done automaticly, unless `noWS` was set to true when initalizing the client.\
-- @return boolean True if logging in was successful, false if not, with an error describing why. \
function krist:websocketStart()\
  local response = self:post(\"ws/start\", nil, self.key ~= nil)\
\
  if response then\
    local data = jsonDecode(response)\
\
    local ws, err = http.websocket(data.url)\
    if ws then\
      self.wsURL = data.url\
      self.ws = ws\
      self:dbug(\"Websocket connected, waiting for hello\")\
\
      repeat\
        local _, url, m = os.pullEvent(\"websocket_message\")\
        local data = jsonDecode(m)\
\
        if url == self.wsURL and data then\
          if data.type == \"hello\" then\
            self.motd = data.motd\
            self:dbug(\"Hello!\", m)\
            return true\
          end\
        end\
      until ready\
\
    end\
\
    return false, err\
  end\
end\
\
function krist:onTransaction(f)\
  self.onTransactionF = f\
end\
\
function krist:onNameChange(f)\
  self.onNameChangeF = f\
end\
\
function krist:onBlock(f)\
  self.onBlockF = f\
end\
\
function krist:awaitCallback(id)\
  local done = false\
\
  while true do\
    local _, wid, data = os.pullEvent(\"krist_callback\")\
    if id == wid then return data end\
  end\
end \
\
-- Websocket Events\
local events = {\
  transaction = function(self, data)\
    os.queueEvent(\"krist_transaction\", data.transaction)\
    if self.onTransactionF then self.onTransactionF(data.transaction) end\
  end,\
  block = function(self, data)\
    os.queueEvent(\"krist_block\", data)\
    if self.onBlockF then self.onTransactionF(data.onBlockF) end\
  end,\
  name = function(self, data)\
    os.queueEvent(\"krist_name\", data.transaction)\
    if self.onNameChangeF then self.onTransactionF(data.onNameChangeF) end\
  end,\
  response = function(self, data)\
    if self.pendingCallbacks[data.id] then\
      os.queueEvent(\"krist_callback\", data.id, data)\
      self:dbug(\"Executing pending callback\", data.id)\
      self.pendingCallbacks[data.id](data)\
      self.pendingCallbacks[data.id] = nil\
    end\
  end\
}\
\
function krist:start()\
  while true do\
    local e, url, m = os.pullEvent()\
\
    local function check(e, url, m)\
      if url ~= self.wsURL then return end\
      if e ~= \"websocket_message\" then return end\
\
      local data = jsonDecode(m)\
      if data == nil then return end\
      \
      self:dbug(\"Event:\", textutils.serialise(data))\
      if data.event == nil or events[data.event] == nil then return end\
        \
      self:dbug(\"Execute\", data.event)\
      events[data.event](self, data)\
    end\
\
    check(e, url, m)\
  end\
end\
\
function krist:destroy()\
  if self.ws then\
    self:dbug(\"Closing websocket\")\
    self.ws.close()\
  end\
  -- SQL condescending bye\
  self:dbug(\"Bye\")\
end\
\
function krist:startWith(f)\
  parallel.waitForAny(function()\
    self:start()\
  end, f)\
  self:destroy()\
end\
\
return krist",
	["transactions.lua"] = "local transactions = {}\
\
local jsonEncode = textutils.serialiseJSON\
local jsonDecode = textutils.unserialiseJSON\
\
function transactions:new(o, parent)\
  o = o or {}\
  setmetatable(o, self)\
  self.__index = self\
  self.parent = parent\
\
  return o\
end\
\
function transactions:make(to, amount, metadata)\
  self.parent:requireAuth()\
\
  local function http()\
    local endpoint = \"transactions\"\
    local data = self.parent:post(endpoint, { to = to, amount = amount, metadata = metadata }, true)\
    return jsonDecode(data)\
  end\
\
  local function ws()\
    local id = self.parent:wsSend(\"make_transaction\", {to = to, amount = amount, metadata = metadata})\
    local data = self.parent:awaitCallback(id)\
    return data\
  end\
\
  local data = self.parent:httpOrWebsocket(http, ws)\
\
  if data.ok then\
    return data.transaction\
  else\
    return nil, data.error\
  end\
end\
\
function transactions:getAll(excludeMined, limit, offset)\
  local data = jsonDecode(self.parent:get(\"transactions\" .. self.parent:createUrlQuery( { excludeMined = excludeMined, limit = limit, offset = offset } )))\
\
  if data.ok then\
    return {\
      count = data.count,\
      total = data.total,\
      transactions = data.transactions\
    }\
  else\
    return nil, data.error\
  end\
end\
\
function transactions:getRecent(excludeMined, limit, offset)\
  local data = jsonDecode(self.parent:get(\"transactions/latest\" .. self.parent:createUrlQuery( { excludeMined = excludeMined, limit = limit, offset = offset } )))\
\
  if data.ok then\
    return {\
      count = data.count,\
      total = data.total,\
      transactions = data.transactions\
    }\
  else\
    return nil, data.error\
  end\
end\
\
function transactions:get(id)\
  local data = jsonDecode(self.parent:get(\"transactions/\" .. id))\
  \
  if data.ok then\
    return data.transaction\
  else\
    return nil, error\
  end\
end \
\
return transactions\
",
	["misc.lua"] = "--- Provides functions for Krist's miscellaneous endpoints\
-- @module misc \
\
local misc = {}\
\
local jsonEncode = textutils.serialiseJSON\
local jsonDecode = textutils.unserialiseJSON\
\
function misc:new(o, parent)\
  o = o or {}\
  setmetatable(o, self)\
  self.__index = self\
  self.parent = parent\
\
  return o\
end\
\
function misc:getWork()\
  local function http()\
    local data = self.parent:get(\"work\")\
    return jsonDecode(data)\
  end\
\
  local function ws()\
    local id = self.parent:wsSend(\"work\", {})\
    local data = self.parent:awaitCallback(id)\
    return data\
  end\
\
  local data = self.parent:httpOrWebsocket(http, ws)\
\
  if data.ok then\
    return data.work\
  else\
    return nil, data.error\
  end\
end\
\
function misc:getWorkPast24H()\
  local data = self.parent:get(\"work/day\")\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return parsed.work\
  else\
    return nil, parsed.error\
  end\
end\
\
function misc:getDetailedWorkInfo()\
  local data = self.parent:get(\"work/detailed\")\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return {\
      work = parsed.work,\
      unpaid = parsed.unpaid,\
      [\"base_value\"] = parsed[\"base_value\"],\
      [\"block_value\"] = parsed[\"block_value\"],\
      decrease = parsed.decrease\
    }\
  else\
    return nil, parsed.error\
  end\
end\
\
function misc:authAddress(key)\
  if not key then\
    self.parent:requireAuth()\
    key = self.parent.key\
  end\
\
  local data = self.parent:post(\"login\", {privatekey = key})\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return {\
      authed = parsed.auth,\
      address = parsed.address\
    }\
  else\
    return nil, parsed.error\
  end\
end\
\
function misc:getMotd()\
  local data = self.parent:get(\"motd\")\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return {\
      motd = parsed.motd,\
      [\"motd_set\"] = parsed[\"motd_set\"],\
      [\"server_time\"] = parsed[\"server_time\"],\
      [\"public_url\"] = parsed[\"public_url\"],\
      [\"mining_enabled\"] = parsed[\"mining_enabled\"],\
      [\"debug_mode\"] = parsed[\"debug_mode\"],\
      work = parsed.work,\
      [\"last_block\"] = parsed[\"last_block\"],\
      package = parsed.package,\
      constants = parsed.constants,\
      currency = parsed.currency,\
      notice = parsed.notice\
    }\
  else\
    return nil, parsed.error\
  end\
end\
\
\
function misc:getLatestKristWalletVersion()\
  local data = self.parent:get(\"walletversion\")\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return parsed.walletVersion\
  else\
    return nil, parsed.error\
  end\
end\
\
function misc:getRecentChanges()\
  local data = self.parent:get(\"whatsnew\")\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return {\
      commits = data.commits,\
      whatsNew = data.whatsNew\
    }\
  else\
    return nil, parsed.error\
  end\
end \
\
function misc:getMoneySupply()\
  local data = self.parent:get(\"supply\")\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return parsed[\"money_supply\"]\
  else\
    return nil, parsed.error\
  end\
end \
\
function misc:getV2Address()\
  self.parent:requireAuth()\
  local data = self.parent:post(\"v2\", nil, true)\
  local parsed = jsonDecode(data)\
\
  if parsed.ok then\
    return parsed.address\
  else\
    return nil, parsed.error\
  end\
end\
\
return misc",
	["kristmeta.lua"] = "local target = \"([%a%d_]+)@\"\
local name = \"([%a%d]+).kst\"\
local keyvalue = \"^(.+)=(.+)$\"\
local keysplit = \"[^;]+\"\
\
local kristmeta = {}\
\
function kristmeta:new(metastr)\
  local o = {}\
  setmetatable(o, self)\
  self.__index = self\
  self.__tostring = function()\
    local str = \"\"\
\
    if self.target and self.target then\
      str = str .. (\"%s@%s.kst;\"):format(self.target, self.name)\
    end\
\
    local amountOfKeys = #self.meta\
    local read = 0\
    for k, v in pairs(self.meta) do\
      str = str .. (\"%s=%s;\"):format(k, v)\
      read = read + 1\
    end\
\
    return str:sub(1, -2)\
  end\
\
  self.name = \"\"\
  self.target = \"\"\
  self.meta = {}\
  self.str = metastr or \"\"\
\
  self.name = metastr:match(name)\
  self.target = metastr:match(target)\
\
  for str in metastr:gmatch(keysplit) do\
    local key, value = str:match(keyvalue)\
\
    if key and value then\
      self.meta[key] = value\
    end\
  end\
\
  return o\
end\
\
function kristmeta:get(key)\
  if key == \"name\" then\
    return self.name\
  elseif key == \"target\" then\
    return self.target\
  else\
    return self.meta[key]\
  end\
end\
\
function kristmeta:set(key, value)\
  if key == \"name\" then\
    self.name = value\
  elseif key == \"target\" then\
    self.target = value\
  else\
    self.meta[key] = value\
  end\
end\
\
return kristmeta",
	["addresses.lua"] = "--- Provides functions for Krist's address endpoints\
-- @module addresses\
\
local addresses = {}\
\
local jsonEncode = textutils.serialiseJSON\
local jsonDecode = textutils.unserialiseJSON\
\
function addresses:new(o, parent)\
  o = o or {}\
  setmetatable(o, self)\
  self.__index = self\
  self.parent = parent\
\
  return o\
end\
\
function addresses:get(address, fetchNames)\
  local function http()\
    local endpoint = \"addresses/\" + address\
    if fetchNames then endpoint = endpoint .. \"?fetchNames=true\" end\
    local data = self.parent:get(endpoint)\
    return jsonDecode(data)\
  end\
\
  local function ws()\
    local id = self.parent:wsSend(\"address\", {address = address, fetchNames = fetchNames})\
    local data = self.parent:awaitCallback(id)\
    return data\
  end\
\
  local data = self.parent:httpOrWebsocket(http, ws)\
\
  if data.ok then\
    return data.address\
  else\
    return nil, data.error\
  end\
end\
\
function addresses:getAll(limit, offset)\
  local data = jsonDecode(self.parent:get(\"addresses\" .. self.parent:createUrlQuery( { limit = limit, offset = offset } )))\
\
  if data.ok then\
    return {\
      count = data.count,\
      total = data.total,\
      addresses = data.addresses\
    }\
  else\
    return nil, data.error\
  end\
end\
\
function addresses:getRichest(limit, offset)\
  local data = jsonDecode(self.parent:get(\"addresses/rich\" .. self.parent:createUrlQuery( { limit = limit, offset = offset } )))\
\
  if data.ok then\
    return {\
      count = data.count,\
      total = data.total,\
      addresses = data.addresses\
    }\
  else\
    return nil, data.error\
  end\
end\
\
function addresses:getRecentTransactions(address, excludeMined, limit, offset)\
  local data = jsonDecode(\
    self.parent:get(\
      \"addresses/\" .. address .. \"/transactions\" .. \
      self.parent:createUrlQuery({\
        limit = limit, offset = offset, excludeMined = excludeMined\
      })\
    )\
  )\
\
  if data.ok then\
    return {\
      count = data.count,\
      total = data.total,\
      transactions = data.transactions\
    }\
  else\
    return nil, data.error\
  end\
end\
\
function addresses:getNames(address, limit, offset)\
  local data = jsonDecode(\
    self.parent:get(\
      \"addresses/\" .. address .. \"/names\" .. \
      self.parent:createUrlQuery({\
        limit = limit, offset = offset\
      })\
    )\
  )\
\
  if data.ok then\
    return {\
      count = data.count,\
      total = data.total,\
      names = data.names\
    }\
  else\
    return nil, data.error\
  end\
end\
\
return addresses",
}

assert(package, "package API is required")
table.insert(package.loaders, 1, function(name)
	for path in package.path:gmatch("[^;]+") do
		local p = name:gsub("%.", "/")
		local test = path:gsub("%?", p)
		if sources[test] then
			return function(...)
				return load(sources[test], name, nil, _ENV)(...)
			end
		end
	end

	return nil, "no matching embedded file"
end)

return load(sources["main.lua"] or "", "main.lua", nil, _ENV)(...)
