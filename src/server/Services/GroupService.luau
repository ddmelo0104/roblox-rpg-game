--!strict
--[[
	GroupService.luau
	The minimal group of the M1 (US-046). Every character carries a prompt (Config/Interface's
	INVITE_KEY) to invite its player; the invited player accepts or declines (RequestGroupAnswer)
	within Config/Groups.INVITE_TIME, and anyone can leave (RequestGroupLeave). A group has up to
	MAX_MEMBERS players and lasts while they play (nothing is saved). The members within SHARE_RANGE
	of a kill share its fame, with the group bonus, and its loot bag (EnemyService); members cannot
	hurt each other (CombatService). Each player gets their group's members and any invite
	(GroupUpdate), and every player's group id is published (the GroupId attribute), so clients can
	tell who is in whose group.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GroupsConfig = require(ReplicatedStorage.Shared.Config.Groups)
local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)

type Group = { id: number, members: { Player } }
type Invite = { from: Player, expiresAt: number }

-- Game text (Portuguese).
local INVITE_TEXT = "Convidar para o grupo"
local GROUP_NAME = "Grupo"

local GroupService = {}

local groupOf: { [Player]: Group } = {}
local nextGroupId = 0
-- Player attribute with the id of the player's group (nil when alone).
local GROUP_ID_ATTRIBUTE = "GroupId"
local invites: { [Player]: Invite } = {}
local updateEvent = Remotes.event("GroupUpdate")

local function notify(player: Player, reason: string)
	Remotes.event("Notice"):FireClient(player, GROUP_NAME, reason)
end

local function send(player: Player)
	local group = groupOf[player]
	player:SetAttribute(GROUP_ID_ATTRIBUTE, if group then group.id else nil)
	local members = {}
	if group then
		for _, member in group.members do
			table.insert(members, { userId = member.UserId, name = member.DisplayName })
		end
	end
	local invite = invites[player]
	updateEvent:FireClient(player, {
		members = members,
		inviteFrom = if invite and os.clock() < invite.expiresAt then invite.from.DisplayName else nil,
		inviteTime = GroupsConfig.INVITE_TIME,
	})
end

local function sendGroup(group: Group)
	for _, member in group.members do
		send(member)
	end
end

local function invite(from: Player, to: Player)
	if from == to then
		return
	end
	local group = groupOf[from]
	if group and #group.members >= GroupsConfig.MAX_MEMBERS then
		notify(from, "GroupFull")
		return
	end
	if groupOf[to] then
		notify(from, "AlreadyInGroup")
		return
	end
	invites[to] = { from = from, expiresAt = os.clock() + GroupsConfig.INVITE_TIME }
	send(to)
	notify(from, "InviteSent")
end

local function leave(player: Player)
	local group = groupOf[player]
	if not group then
		return
	end
	groupOf[player] = nil
	local index = table.find(group.members, player)
	if index then
		table.remove(group.members, index)
	end
	if #group.members == 1 then
		-- A group of one is no group: the last member is alone again.
		groupOf[group.members[1]] = nil
		local last = group.members[1]
		group.members = {}
		send(last)
	else
		sendGroup(group)
	end
	if player.Parent then
		send(player)
	end
end

local function answer(player: Player, accept: boolean)
	local pending = invites[player]
	invites[player] = nil
	if not pending or os.clock() >= pending.expiresAt or not pending.from.Parent then
		send(player)
		return
	end
	if not accept then
		send(player)
		return
	end
	if groupOf[player] then
		leave(player)
	end
	local from = pending.from
	local group = groupOf[from]
	if not group then
		nextGroupId += 1
		group = { id = nextGroupId, members = { from } }
		groupOf[from] = group
	end
	if #group.members >= GroupsConfig.MAX_MEMBERS then
		notify(player, "GroupFull")
		send(player)
		return
	end
	table.insert(group.members, player)
	groupOf[player] = group
	sendGroup(group)
end

local function addPrompt(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GroupInvite"
	prompt.ActionText = INVITE_TEXT
	prompt.ObjectText = player.DisplayName
	prompt.KeyboardKeyCode = InterfaceConfig.INVITE_KEY
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(by)
		invite(by, player)
	end)
end

-- Whether two players are in the same group.
function GroupService.sameGroup(a: Player, b: Player): boolean
	local group = groupOf[a]
	return group ~= nil and group == groupOf[b]
end

-- The player and the members of their group whose characters are within `range` of `position`
-- (the player is always included).
function GroupService.membersNear(player: Player, position: Vector3, range: number): { Player }
	local group = groupOf[player]
	if not group then
		return { player }
	end
	local list: { Player } = { player }
	for _, member in group.members do
		if member ~= player then
			local character = member.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if root and root:IsA("BasePart") and (root.Position - position).Magnitude <= range then
				table.insert(list, member)
			end
		end
	end
	return list
end

function GroupService:Start()
	Network.onReceive("RequestGroupAnswer", Validate.boolean, answer)
	Network.onReceive("RequestGroupLeave", function()
		return true, nil
	end, leave)
	updateEvent.OnServerEvent:Connect(function() end) -- a server notice only

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			addPrompt(player, character)
		end)
		if player.Character then
			task.spawn(addPrompt, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		leave(player)
		invites[player] = nil
	end)
end

return GroupService
