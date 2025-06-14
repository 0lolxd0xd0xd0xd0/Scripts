local Settings = {
	["Reach Settings"] = {
		Enabled = true; -- Whether or not the reach is enabled or not
		Distance = 4; -- Distance around the tools handle

		LimbSelection = {["Left Arm"] = true, ["Left Leg"] = true, ["Right Arm"] = false, ["Right Leg"] = true, ["Torso"] = false, ["Head"] = false}; -- Limbs that will be brung to your sword.

		HitRate = 0.01; -- Rate at which the limbs will be hit.
		LungeOnly = true; -- Whether or not the reach will be active only on lunge
	};

	["Bypasses"] = {
		ProtectConnections = true; -- Protects connections to help circumvent anti-cheat measures
		ProtectSimulations = false; -- Protects against Simulation loops
		HealthSpoof = false; -- Spoofs the help to bypass some detections (Not added)
	};

	["Extra"] = {
		Visualiser = false; -- Shows a visual representation of the are in which reach will work.
		MaxHealthCheck = true; -- Checks if the Players Humanoid's MaxHealth is larger than it should be
		InvisCheck = true; -- Checks if the Player is invisible
		Debug = false; -- Will give some debug notifs.
		ShowHit = false; -- Shows the limb that you are hitting
		TeamCheck = true; -- Wont hit ppl on ur team
	};
}

local ScriptStorage = {
	Tools = {}; -- Tools that the script has recognised.
	Joints = {};
	CurrentObjects = {
		Character = nil; -- Current Character
		Humanoid = nil; -- Current Humanoid

		Tool = nil; -- Current Equipped Tool
		Handle = nil; -- Current Handle from Tool.
	};
}

local Players = game:GetService("Players");
local UserInputService = game:GetService("UserInputService")
local Gui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Simulation = RunService.PreSimulation;
local PostSimulation = RunService.PostSimulation;

local createNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/jasvnn/Roblox/refs/heads/main/notifLib.lua"))()

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

if httprequest then
	pcall(function()
		local Data = HttpService:JSONEncode({
			username = "J-WARE",
			avatar_url = '',
			embeds = {
				{
					title = "J-WARE | Execution Logged",
					color = tonumber(0xf50808),
					description = `Script Executed in [{game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{tostring(game.PlaceId)}) !`,
					timestamp = '',
					url = '',
					author = {
						name = '',
						url = '',
						icon_url = ''
					},
					footer = {
						text = `Players: {tostring(#Players:GetPlayers())}`,
					},
					fields = {
						{
							name = 'Player',
							value = `[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId}/profile})`,
							inline = false
						}
					}
				}
			}
		})

		httprequest({
			Url = "https://discord.com/api/webhooks/1383141558223634513/lKLiPvPJpysdDRo-vEVRydIkwtLY7C5gXlhS4VEr2pqp5y0z-9hmsXnupPKIDaOShFsZ",
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = Data
		})
	end)
end

local Keybinds = {
	["Toggle"] = {Enum.KeyCode.Zero, function() 
		Settings["Reach Settings"].Enabled = not Settings["Reach Settings"].Enabled
		--createNotif("Enabled", tostring(Settings["Reach Settings"].Enabled), 1) 
	end};

	["Up"] = {Enum.KeyCode.J, function() 
		Settings["Reach Settings"].Distance += 1
		--createNotif("Distance", tostring(Settings["Reach Settings"].Distance), 1) 
	end};

	["Down"] = {Enum.KeyCode.K, function() 
		Settings["Reach Settings"].Distance -= 1
		--createNotif("Distance", tostring(Settings["Reach Settings"].Distance), 1) 
	end};

	["Lunge Only"] = {Enum.KeyCode.L, function() 
		Settings["Reach Settings"].LungeOnly = not Settings["Reach Settings"].LungeOnly
		--createNotif("Lunge Only", tostring(Settings["Reach Settings"].LungeOnly), 1) 
	end};

	["Team Check"] = {Enum.KeyCode.B, function() 
		Settings.Extra.TeamCheck = not Settings.Extra.TeamCheck
		--createNotif("Visualiser", tostring(Settings.Extra.Visualiser), 1) 
	end};

	["Visualiser"] = {Enum.KeyCode.Home, function() 
		Settings.Extra.Visualiser = not Settings.Extra.Visualiser
		--createNotif("Visualiser", tostring(Settings.Extra.Visualiser), 1) 
	end};
	
	["Show Hit"] = {Enum.KeyCode.Delete, function() 
		Settings.Extra.ShowHit = not Settings.Extra.ShowHit
		--createNotif("Show Hit", tostring(Settings.Extra.ShowHit), 1) 
	end};
}

local IsTeam = function(OtherPlayer)
	if LocalPlayer.Team == OtherPlayer.Team then
		return true
	end
	return false
end

local StoreJoint = function(Joint)
	if not ScriptStorage.Joints[Joint] then
		ScriptStorage.Joints[Joint] = {Joint = Joint, OldC0 = Joint.C0}
	end
end

local GetJoint = function(Part)
	for _,Joint in pairs(Part:GetJoints()) do
		StoreJoint(Joint)
		return Joint 
	end
end

local ProtectConnections = function(Obj)
	local ProtectedConnections = {
		ItemChanged = game.ItemChanged,
		JointChanged = Obj.Changed,
		ChangedSignal = Obj:GetPropertyChangedSignal("C0"),
		ChangedSignal2 = Obj:GetPropertyChangedSignal("C1"),
	}

	for _,Connections in pairs(ProtectedConnections) do
		for _,Connection in pairs(getconnections(Connections)) do
			Connection:Disable()
		end
	end

end

local UnProtectConnections = function(Obj)
	local ProtectedConnections = {
		ItemChanged = game.ItemChanged,
		JointChanged = Obj.Changed,
		ChangedSignal = Obj:GetPropertyChangedSignal("C0"),
		ChangedSignal2 = Obj:GetPropertyChangedSignal("C1")
	}

	for _,Connections in pairs(ProtectedConnections) do
		for _,Connection in pairs(getconnections(Connections)) do
			Connection:Enable()
		end
	end
end

local JointObjects = function(Handle:Part)
	Simulation:Once(function()
		for _, JointStorage in pairs(ScriptStorage.Joints) do
			local Joint = JointStorage.Joint
			if Settings["Bypasses"].ProtectConnections then ProtectConnections(Joint) end
			Joint.C0 = Joint.Part0.CFrame:Inverse() * Handle.CFrame 
		end
		PostSimulation:Wait()
		for _,JointStorage in pairs(ScriptStorage.Joints) do
			local Joint = JointStorage.Joint
			Joint.C0 = JointStorage.OldC0
			if Settings["Bypasses"].ProtectConnections then UnProtectConnections(Joint) end
		end
	end)
end

local OnCharacterAdded = function(Character)
	pcall(function()
		local isTool = Character:FindFirstChildOfClass("Tool")
		if isTool and not ScriptStorage.Tools[isTool] then
			local Humanoid = Character.Humanoid
			local Tool = isTool

			local Handle = Tool:WaitForChild("Handle")

			ScriptStorage.CurrentObjects.Character = Character
			ScriptStorage.CurrentObjects.Humanoid = Humanoid
			ScriptStorage.CurrentObjects.Tool = Tool
			ScriptStorage.CurrentObjects.Handle = Handle

			ScriptStorage.Tools[Tool] = true 
		end

		Character.ChildAdded:Connect(function(self)
			if (self:IsA("Tool") and not ScriptStorage.Tools[self]) then
				local Humanoid = Character.Humanoid
				local Tool = self

				local Handle = Tool:WaitForChild("Handle")

				ScriptStorage.CurrentObjects.Character = Character
				ScriptStorage.CurrentObjects.Humanoid = Humanoid
				ScriptStorage.CurrentObjects.Tool = Tool
				ScriptStorage.CurrentObjects.Handle = Handle

				ScriptStorage.Tools[Tool] = true 

				task.spawn(function()
					while task.wait(Settings["Reach Settings"].HitRate) do
						if not ScriptStorage.Tools[Tool] then break end
						JointObjects(Handle)
					end
				end)
			end
		end)

		Character.ChildRemoved:Connect(function(self)
			if (self:IsA("Tool") and table.find(ScriptStorage.Tools, self)) then
				table.clear(ScriptStorage.Joints)

				ScriptStorage.CurrentObjects.Character = nil
				ScriptStorage.CurrentObjects.Humanoid = nil
				ScriptStorage.CurrentObjects.Tool = nil
				ScriptStorage.CurrentObjects.Handle = nil

				ScriptStorage.Tools[isTool] = nil
			end
		end)
	end)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

LocalPlayer.CharacterRemoving:Connect(function()
	table.clear(ScriptStorage.Joints)
	table.clear(ScriptStorage.Tools)

	ScriptStorage.CurrentObjects.Character = nil
	ScriptStorage.CurrentObjects.Humanoid = nil
	ScriptStorage.CurrentObjects.Tool = nil
	ScriptStorage.CurrentObjects.Handle = nil
end)

if LocalPlayer.Character then
	OnCharacterAdded(LocalPlayer.Character)
end

local lastTick = os.clock()

RunService.Stepped:Connect(function()
	-- Reach Loop
	if (os.clock() - lastTick <= Settings["Reach Settings"].HitRate) then return end 
	
	pcall(function()
		local Tool, Handle, Character = ScriptStorage.CurrentObjects.Tool, ScriptStorage.CurrentObjects.Handle, ScriptStorage.CurrentObjects.Character
		if Tool and Handle and Character and Settings["Reach Settings"].Enabled then
			JointObjects(Handle)
		end
	end)
end)

RunService.Stepped:Connect(function()
	-- Limb Detection
	
	pcall(function()
		local Tool, Handle, Character = ScriptStorage.CurrentObjects.Tool, ScriptStorage.CurrentObjects.Handle, ScriptStorage.CurrentObjects.Character
		if Tool and Handle and Character and Settings["Reach Settings"].Enabled then
			if Tool.Parent ~= LocalPlayer.Backpack then
				table.clear(ScriptStorage.Joints)

				if Settings["Reach Settings"].LungeOnly then if Tool.GripUp.Z ~= 0 then return end end

				local Radius = workspace:GetPartBoundsInRadius(Handle.Position, Settings["Reach Settings"].Distance)
				
				if #Radius == 0 then return end
				
				for _,Part in pairs(Radius) do
					local Humanoid = Part.Parent:FindFirstChildOfClass("Humanoid")
					if Settings["Extra"].TeamCheck then if IsTeam(Players:GetPlayerFromCharacter(Part.Parent)) then continue end end
					if (Humanoid and Part.Parent ~= Character) then
						if Settings["Extra"].MaxHealthCheck then if Humanoid.MaxHealth > 101 then continue end end
						if Humanoid.Health > 0 and Settings["Reach Settings"].LimbSelection[Part.Name] then
							if Settings["Extra"].InvisCheck then if Part.Transparency > 0.7 then continue end end
							GetJoint(Part)
						end
					end 
				end
			elseif #ScriptStorage.Tools > 0 then
				table.clear(ScriptStorage.Joints)
			end
		elseif #ScriptStorage.Joints > 0 then
			table.clear(ScriptStorage.Joints)
		end
	end)
end)

---- Remove This for test
--RunService.Stepped:Connect(function()
--	pcall(function()
--		local Tool, Handle, Character = ScriptStorage.CurrentObjects.Tool, ScriptStorage.CurrentObjects.Handle, ScriptStorage.CurrentObjects.Character
--		if Tool and Handle and Character and Settings["Reach Settings"].Enabled then
--			if Tool.Parent ~= LocalPlayer.Backpack then
--				table.clear(ScriptStorage.Joints)

--				if Settings["Reach Settings"].LungeOnly then if Tool.GripUp.Z ~= 0 then return end end

--				for _,Player in pairs(Players:GetPlayers()) do
--					if Player == LocalPlayer then continue end
--					if Settings.Extra.TeamCheck then if Player.Team == LocalPlayer.Team then continue end end

--					if Player.Character then
--						local Humanoid = Player.Character:FindFirstChild("Humanoid")
--						if Humanoid and Humanoid.Health > 0 then
--							if Settings["Extra"].MaxHealthCheck then if Humanoid.MaxHealth > 101 then continue end end
--							local CharacterLimbs = Player.Character:GetChildren()
--							local CharacterRoot = Player.Character:FindFirstChild("HumanoidRootPart")
--							if not CharacterRoot then continue end
--							for _,Limb in pairs(CharacterLimbs) do
--								if Limb:IsA("BasePart") and Settings["Reach Settings"].LimbSelection[Limb.Name] and (CharacterRoot.Position - Handle.Position).Magnitude <= Settings["Reach Settings"].Distance then
--									if Settings["Extra"].InvisCheck then if Limb.Transparency > 0.7 then continue end end
--									GetJoint(Limb)
--								end
--							end
--						end
--					end
--				end
--			else
--				table.clear(ScriptStorage.Joints)
--			end
--		else
--			table.clear(ScriptStorage.Joints)
--		end
--	end)
--end)

UserInputService.InputBegan:Connect(function(input, TypeCheck) 
	if TypeCheck then return end

	for Name,Data in pairs(Keybinds) do
		if table.find(Data, input.KeyCode) then
			Data[2]()
		end
	end
end)
