-- Initialize our Ace3 AddOn
Keyed = LibStub("AceAddon-3.0"):NewAddon("Keyed", "AceConsole-3.0", "AceHook-3.0", "AceComm-3.0")

-- Default Profile
local defaults = {
	factionrealm = {
		["*"] = {
			time = 0,
			keystones = {}
		}
	}
}

local KeystoneId = 138019
local prefix = "KEYED_ALPHA"
local KeyedName = "|cffd6266cKeyed|r"
local keystoneRequest = "keystones"

function Keyed:OnInitialize()
	-- Register "/keyed" command
	Keyed:RegisterChatCommand("keyed", "Options")
	Keyed:RegisterComm(prefix, "OnCommReceived")
	KeyedInterface:RegisterForDrag("LeftButton")
	
	-- Load Database
	self.db = LibStub("AceDB-3.0"):New("KeyedDB", defaults)
end

function Keyed:OnEnable()
end

function Keyed:OnDisable()
end

function Keyed:Options(input)
	-- Check...
	if self:isempty(input) then
		-- KeyedInterface:Show()
		print(KeyedName, "Currently the GUI is disabled :(\r\n    However, you can type \"/weighted print db\" to view keystones in database.")
	else
		local Arguments = self:SplitString(input, ' ')
		if Arguments[1] == "get" then
			if Arguments[2] == "all" then
				self:BroadcastKeystoneRequest()
			else
				self:SendKeystoneRequest(Arguments[2])
			end
		elseif Arguments[1] == "print" then
			if Arguments[2] == "db" or Arguments[2] == "database" then
				print(KeyedName, "Keystones in database:")
				for playerName, keystones in pairs(self.db.factionrealm) do
					for i = 1, #keystones.keystones do
						print(KeyedName, playerName, "(" .. i .. "/" .. #keystones.keystones .. ")", keystones.keystones[i])
					end
				end
			end
		end
	end
end

function Keyed:SendResponse(playerName, response)
	Keyed:SendCommMessage(prefix, response, "WHISPER", playerName)
end

function Keyed:BroadcastKeystoneRequest()
	print(KeyedName, "Getting keystones from guild...")
	Keyed:SendCommMessage(prefix, "request;" .. keystoneRequest, "GUILD")
end

function Keyed:SendKeystoneRequest(playerName)
	if playerName then Keyed:SendCommMessage(prefix, "request;" .. keystoneRequest, "WHISPER", playerName) end
end

function Keyed:OnCommReceived (prefix, message, channel, sender)
	-- Prepare
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
	local arguments = self:SplitString(message, ';')
	local keystones = {}
	local time = 0
	
	-- Handle...
	if arguments[1] == "request" then
		if arguments[2] == keystoneRequest then
			self:SendEntries(sender)
			self:SendKeystones(sender)
		end
	elseif arguments[1] == "keystones" then
		time = tonumber(arguments[2])
		for i = 3, #arguments do
			if not self:isempty(arguments[i]) then
				name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(arguments[i])
				if name and link then table.insert(keystones, link) end
			end
		end

		-- Wipe and add...
		if self.db.factionrealm[sender].time < time then
			table.wipe(self.db.factionrealm[sender])
			print(KeyedName, "Updating", sender, "database entry...")
			self.db.factionrealm[sender].time = time
			self.db.factionrealm[sender].keystones = {}
			for i = 1, #keystones do
				table.insert(self.db.factionrealm[sender].keystones, keystones[i])
			end
		end
	end
end

function Keyed:SendEntries(target)
	-- Prepare
	local message = keystoneRequest .. ";" 
	for playerName, entry in pairs(self.db.factionrealm) do
		if playerName ~= UnitName('player') then
			message = message .. tostring(entry.time) .. ";"
			for i = 1, #entry.keystones do message = message .. entry.keystones[i] .. ";" end
			self:SendResponse(target, message)
		end
	end
end

function Keyed:SendKeystones(target)
	-- Prepare
	local message = keystoneRequest .. ";" .. tostring(GetServerTime()) .. ";"
	local keystones = self:FindKeystones()
	for i = 1, #keystones do
		message = message .. keystones[i] .. ";"
	end
	self:SendResponse(target, message)
end

function Keyed:FindKeystones()
	-- Prepare...
	local texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemId
	local keystones = {}
	local slots = {}
	slots[1] = GetContainerNumSlots(0)
	slots[2] = GetContainerNumSlots(1)
	slots[3] = GetContainerNumSlots(2)
	slots[4] = GetContainerNumSlots(3)
	slots[5] = GetContainerNumSlots(5)

	-- Loop through every bag slot...
	for i = 1, #slots do
		for j = 1, slots[i] do
			-- Load Item info...
			texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemId = GetContainerItemInfo(i - 1, j)

			-- Check...
			if itemId and itemId == KeystoneId then
				table.insert(keystones, link)
			end
		end
	end

	-- Return
	return keystones
end

function Keyed:SplitString(input, separator)
	local parts = {}
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find(input, separator, theStart)
	while theSplitStart do
		table.insert( parts, string.sub(input, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find(input, separator, theStart )
	end
	table.insert(parts, string.sub(input, theStart))
	return parts
end

function Keyed:isempty(s)
	return s == nil or s == ''
end