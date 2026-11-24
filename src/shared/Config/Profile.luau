--!strict
--[[
	Config/Profile.luau
	Saving the player profile (EP-006, ADR-005): where, how often, and how long to wait for a session
	lock. Provisional numbers, decided by the dev.
]]

return table.freeze({
	-- Data store of the profiles and the key of each player. A data format that cannot be migrated
	-- goes to a new store name.
	STORE_NAME = "PlayerProfiles_v1",
	KEY_PREFIX = "Player_",

	-- Version of the data inside a profile. Older profiles are migrated up to it when they load.
	DATA_VERSION = 1,

	-- Seconds between two saves of a profile while its player is in the game.
	AUTOSAVE_INTERVAL = 60,

	-- A lock whose server has not saved for this many seconds belongs to a dead server (a crash), and
	-- another server may take it.
	SESSION_TIMEOUT = 300,

	-- Loading: attempts, and seconds between them (another server may still be releasing the
	-- profile of a player who just moved). After the last one the player is kicked.
	LOAD_ATTEMPTS = 6,
	LOAD_RETRY_WAIT = 5,

	-- Saving: attempts per save, and seconds between them.
	SAVE_ATTEMPTS = 3,
	SAVE_RETRY_WAIT = 2,

	-- When the server closes, how long (seconds) it waits for the last saves. Roblox allows 30.
	CLOSE_SAVE_TIME = 25,
})
