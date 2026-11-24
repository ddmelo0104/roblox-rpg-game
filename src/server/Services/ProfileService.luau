--!strict
--[[
	ProfileService.luau
	The saved profile of each player (EP-006, ADR-005): what the services keep between sessions, in a
	DataStore with a session lock, so a profile is never open in two servers at once and an item can
	never exist twice (rule 6).
	- Sections: each service that keeps something registers a section in its Init with
	  `addSection(name, load, save, release)`. `load(player, saved)` gets what was saved (nil for a
	  new player), `save(player)` returns what to save and `release(player)` lets the player's data
	  go. None may yield. A service never drops a player's data on its own (PlayerRemoving listeners
	  run in no set order): this service copies the data for the last save and only then releases.
	- Loading, when a player joins: one UpdateAsync takes the lock if it is free, already this
	  server's, or dead (no save for Config/Profile.SESSION_TIMEOUT). If another live server holds it
	  (the player is still leaving it), it tries again a few times, and kicks the player if it never
	  gets it.
	- Saving, every AUTOSAVE_INTERVAL, when the player leaves and when the server closes: one
	  UpdateAsync writes only if the lock is still this server's; leaving also releases it. A server
	  that lost the lock never writes, and kicks the player.
	- Studio without access to API services: profiles live only in memory, with a warning.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileConfig = require(ReplicatedStorage.Shared.Config.Profile)

type Section = {
	name: string,
	load: (player: Player, saved: any) -> (),
	save: (player: Player) -> any,
	release: (player: Player) -> (),
}

-- Who holds a profile: this server's id, for debugging the job and place, and the last save time.
type Lock = { id: string, jobId: string, placeId: number, savedAt: number }

-- What is stored under each player's key.
type Stored = { version: number, data: { [string]: any }, lock: Lock? }

-- This server's hold on one player's profile.
type Session = {
	-- This server took the lock in the store.
	locked: boolean,
	-- Every section loaded: only then is the data worth writing.
	loaded: boolean,
	-- A save is running (saves of one key never overlap).
	busy: boolean,
	-- Leaving or closing: no more autosaves.
	finishing: boolean,
}

-- Player-facing messages (Portuguese).
local LOAD_FAILED_MESSAGE = "Não foi possível carregar o seu perfil agora. Entre de novo em alguns instantes."
local LOCK_LOST_MESSAGE = "O seu perfil foi aberto em outro servidor."

local ProfileService = {}

-- A fresh id for this server: unique even in Studio, where every JobId is empty.
local SERVER_ID = HttpService:GenerateGUID(false)

local sections: { Section } = {}
local sessions: { [Player]: Session } = {}
-- Players (by UserId) whose profile this server is still writing after they left.
local leaving: { [number]: boolean } = {}
local store: DataStore? = nil
-- Studio without API access: profiles saved only here, for the length of the test.
local memory: { [number]: any } = {}

local function keyOf(player: Player): string
	return ProfileConfig.KEY_PREFIX .. tostring(player.UserId)
end

local function newLock(): Lock
	return { id = SERVER_ID, jobId = game.JobId, placeId = game.PlaceId, savedAt = os.time() }
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in value do
		copy[key] = deepCopy(item)
	end
	return copy
end

-- Whether a lock found in the store belongs to another server that is still alive.
local function heldElsewhere(lock: Lock?): boolean
	if not lock or lock.id == SERVER_ID then
		return false
	end
	if os.time() - lock.savedAt >= ProfileConfig.SESSION_TIMEOUT then
		return false -- its server stopped saving: dead
	end
	-- A Studio test that did not release (Studio crashed or was stopped hard) does not block the next
	-- Studio test; live servers never have an empty JobId.
	return not (RunService:IsStudio() and lock.jobId == "")
end

-- Older data formats go up to DATA_VERSION here, one version at a time.
local function migrate(stored: Stored): Stored
	stored.version = ProfileConfig.DATA_VERSION
	return stored
end

-- One attempt to take the player's profile. Returns it, or nil (held by another live server, or the
-- request failed).
local function tryLoad(player: Player): Stored?
	local taken: Stored? = nil
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(keyOf(player), function(current: any): any
			taken = nil -- the transform can run more than once: only the last run counts
			local stored: Stored = if type(current) == "table"
				then current
				else { version = ProfileConfig.DATA_VERSION, data = {}, lock = nil }
			if heldElsewhere(stored.lock) then
				return nil -- write nothing: another live server has it
			end
			stored.lock = newLock()
			taken = stored
			return stored
		end)
	end)
	if not ok then
		warn(`[Profile] loading {player.Name} failed: {err}`)
		return nil
	end
	return taken
end

-- What the sections want to save right now, copied, so the write is the state of one moment.
local function collect(player: Player): { [string]: any }
	local data: { [string]: any } = {}
	for _, section in sections do
		data[section.name] = deepCopy(section.save(player))
	end
	return data
end

-- Writes `data` (nil keeps what is stored) if the lock is still this server's; `release` also
-- frees it. Returns false if the lock was lost, true otherwise (also when every attempt failed: the
-- lock is still ours and the next save tries again).
local function write(player: Player, data: { [string]: any }?, release: boolean): boolean
	for attempt = 1, ProfileConfig.SAVE_ATTEMPTS do
		local lost = false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyOf(player), function(current: any): any
				lost = false
				if type(current) ~= "table" or not current.lock or current.lock.id ~= SERVER_ID then
					lost = true
					return nil -- never write over a profile this server does not hold
				end
				if data then
					current.data = data
					current.version = ProfileConfig.DATA_VERSION
				end
				current.lock = if release then nil else newLock()
				return current
			end)
		end)
		if ok then
			if lost then
				warn(`[Profile] {player.Name}'s profile is held by another server: not saved`)
			end
			return not lost
		end
		warn(`[Profile] saving {player.Name} failed (attempt {attempt}): {err}`)
		if attempt < ProfileConfig.SAVE_ATTEMPTS then
			task.wait(ProfileConfig.SAVE_RETRY_WAIT)
		end
	end
	return true
end

-- Gives each section its saved part. Returns false if any section failed (nothing will be saved
-- over the stored profile then).
local function apply(player: Player, data: { [string]: any })
	for _, section in sections do
		local ok, err = pcall(section.load, player, data[section.name])
		if not ok then
			warn(`[Profile] section {section.name} failed to load for {player.Name}: {err}`)
			return false
		end
	end
	return true
end

local function load(player: Player)
	while leaving[player.UserId] do
		task.wait(0.5) -- this server is still writing this player's last session
	end
	if not player.Parent then
		return
	end
	local session: Session = { locked = false, loaded = false, busy = true, finishing = false }
	sessions[player] = session

	if not store then
		session.loaded = apply(player, deepCopy(memory[player.UserId]) or {})
		session.busy = false
		if not session.loaded then
			player:Kick(LOAD_FAILED_MESSAGE)
		end
		return
	end

	for attempt = 1, ProfileConfig.LOAD_ATTEMPTS do
		local stored = tryLoad(player)
		if stored then
			session.locked = true
			-- A player who left while it loaded gets nothing; `finish` releases the lock.
			if player.Parent then
				session.loaded = apply(player, migrate(stored).data or {})
			end
			session.busy = false
			if player.Parent and not session.loaded then
				-- Playing on would save nothing: better to say so than to lose the session.
				player:Kick(LOAD_FAILED_MESSAGE)
			end
			return
		end
		if not player.Parent then
			break
		end
		if attempt < ProfileConfig.LOAD_ATTEMPTS then
			task.wait(ProfileConfig.LOAD_RETRY_WAIT)
		end
	end
	session.busy = false
	if player.Parent then
		player:Kick(LOAD_FAILED_MESSAGE)
	end
end

-- The last save of a player who left (or of everyone, when the server closes): copy the data at
-- once, let the sections release it, then write and release the lock.
local function finish(player: Player)
	local session = sessions[player]
	if not session or session.finishing then
		return
	end
	session.finishing = true
	leaving[player.UserId] = true
	-- A load still running ends first (it may be the one that takes the lock).
	while session.busy and not session.loaded do
		task.wait(0.1)
	end
	local data = if session.loaded then collect(player) else nil
	for _, section in sections do
		local ok, err = pcall(section.release, player)
		if not ok then
			warn(`[Profile] section {section.name} failed to release {player.Name}: {err}`)
		end
	end
	while session.busy do
		task.wait(0.1) -- an autosave of this profile is still writing
	end
	session.busy = true
	if not store then
		if data then
			memory[player.UserId] = data
		end
	elseif session.locked then
		write(player, data, true)
	end
	session.busy = false
	sessions[player] = nil
	leaving[player.UserId] = nil
end

local function autosave(player: Player, session: Session)
	if session.busy or session.finishing or not session.loaded or not store then
		return
	end
	session.busy = true
	local stillOurs = write(player, collect(player), false)
	session.busy = false
	if not stillOurs and not session.finishing then
		-- Another server holds the profile now: never write it again. `finish` still releases the
		-- sections when the player leaves.
		session.locked = false
		session.loaded = false
		if player.Parent then
			player:Kick(LOCK_LOST_MESSAGE)
		end
	end
end

-- Registers what a service keeps in the profile. Call it in Init, before any player loads.
function ProfileService.addSection(
	name: string,
	loadSection: (player: Player, saved: any) -> (),
	saveSection: (player: Player) -> any,
	releaseSection: (player: Player) -> ()
)
	table.insert(sections, { name = name, load = loadSection, save = saveSection, release = releaseSection })
end

function ProfileService:Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(ProfileConfig.STORE_NAME)
	end)
	if ok and RunService:IsStudio() then
		-- In Studio the store only works with "Enable Studio Access to API Services" on, in a
		-- published place: a first read tells.
		ok = pcall(function()
			result:GetAsync("__studio_probe")
		end)
	end
	if ok then
		store = result
	else
		warn(
			"[Profile] DataStore unavailable (in Studio: publish the place and enable Studio Access to API Services). Profiles are kept only in memory and are not saved."
		)
	end
end

function ProfileService:Start()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(finish)

	task.spawn(function()
		while true do
			task.wait(ProfileConfig.AUTOSAVE_INTERVAL)
			for player, session in sessions do
				task.spawn(autosave, player, session)
			end
		end
	end)

	game:BindToClose(function()
		for player in sessions do
			task.spawn(finish, player)
		end
		local started = os.clock()
		while next(sessions) and os.clock() - started < ProfileConfig.CLOSE_SAVE_TIME do
			task.wait(0.1)
		end
	end)
end

return ProfileService
