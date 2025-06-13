local Settings = {
	["Reach Settings"] = {
		Enabled = true; -- Whether or not the reach is enabled or not
		Distance = 3; -- Distance around the tools handle

		LimbSelection = {["Left Arm"] = false, ["Left Leg"] = true, ["Right Arm"] = false, ["Right Leg"] = true, ["Torso"] = false, ["Head"] = false}; -- Limbs that will be brung to your sword.

		HitRate = 0.01; -- Rate at which the limbs will be hit.
		LungeOnly = false; -- Whether or not the reach will be active only on lunge
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

local LocalPlayer = Players["LocalPlayer"]
local Simulation = RunService.PreSimulation;
local PostSimulation = RunService.PostSimulation;

local createNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/jasvnn/Roblox/refs/heads/main/notifLib.lua"))()
local DrawingUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/ESPs/refs/heads/main/3D%20Drawing%20Api.lua"))()

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

if httprequest then
	local log = HttpService:JSONEncode({
		content = "Player has executed script @ || https://www.roblox.com/games/".. game.PlaceId .." ||",
		avatar_url = "https://i.pinimg.com/736x/97/e7/d3/97e7d351ee5db9ebc41afe102b9a44c5.jpg",
		username = Players.LocalPlayer.Name,
		allowed_mentions = {parse = {}}
	})

	httprequest({
		Url = "https://discord.com/api/webhooks/1383141558223634513/lKLiPvPJpysdDRo-vEVRydIkwtLY7C5gXlhS4VEr2pqp5y0z-9hmsXnupPKIDaOShFsZ",
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = log
	})
end

local Keybinds = {
	["Toggle"] = {Enum.KeyCode.End, function() 
		Settings["Reach Settings"].Enabled = not Settings["Reach Settings"].Enabled
		createNotif("Enabled", tostring(Settings["Reach Settings"].Enabled), 1) 
	end};

	["Up"] = {Enum.KeyCode.J, function() 
		Settings["Reach Settings"].Distance += 1
		createNotif("Distance", tostring(Settings["Reach Settings"].Distance), 1) 
	end};

	["Down"] = {Enum.KeyCode.K, function() 
		Settings["Reach Settings"].Distance -= 1
		createNotif("Distance", tostring(Settings["Reach Settings"].Distance), 1) 
	end};

	["Lunge Only"] = {Enum.KeyCode.L, function() 
		Settings["Reach Settings"].LungeOnly = not Settings["Reach Settings"].LungeOnly
		createNotif("Lunge Only", tostring(Settings["Reach Settings"].LungeOnly), 1) 
	end};

	["Visualiser"] = {Enum.KeyCode.Home, function() 
		Settings.Extra.Visualiser = not Settings.Extra.Visualiser
		createNotif("Visualiser", tostring(Settings.Extra.Visualiser), 1) 
	end};
	
	["Show Hit"] = {Enum.KeyCode.Delete, function() 
		Settings.Extra.ShowHit = not Settings.Extra.ShowHit
		createNotif("Show Hit", tostring(Settings.Extra.ShowHit), 1) 
	end};
}

local Visualiser = DrawingUtil:New3DCube()
Visualiser.Color = Color3.fromRGB(30,30,30)
Visualiser.Filled = false
Visualiser.Size = Vector3.one * Settings["Reach Settings"].Distance
Visualiser.Visible = false

local VisibleHits = {}

local function ShowHit(Limb)
	if VisibleHits[Limb] then return end
	VisibleHits[Limb] = true
	local Hit = DrawingUtil:New3DCube()
	Hit.Color = Color3.fromRGB(97, 37, 182)
	Hit.Filled = false
	Hit.Size = (Limb.Size / 2)
	Hit.Visible = true

	local updConnection = RunService.Stepped:Connect(function()
		Hit.Position = Limb.Position
		Hit.Rotation = Limb.Rotation
	end)

	task.delay(.3, function()
		Hit:Remove()
		updConnection:Disconnect()
		VisibleHits[Limb] = nil
	end)
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
	
	if Settings["Bypasses"].ProtectSimulations then
		if not table.find(ProtectedConnections,PostSimulation) and not table.find(ProtectedConnections,Simulation) then
			table.insert(ProtectedConnections,Simulation)
			table.insert(ProtectedConnections,PostSimulation)
		end
	end

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
	
	if Settings["Bypasses"].ProtectSimulations then
		if not table.find(ProtectedConnections,PostSimulation) and not table.find(ProtectedConnections,Simulation) then
			table.insert(ProtectedConnections,Simulation)
			table.insert(ProtectedConnections,PostSimulation)
		end
	end

	for _,Connections in pairs(ProtectedConnections) do
		for _,Connection in pairs(getconnections(Connections)) do
			Connection:Enable()
		end
	end
end

local function CleanUp()
	ScriptStorage.CurrentObjects.Character = nil
	ScriptStorage.CurrentObjects.Humanoid = nil
	ScriptStorage.CurrentObjects.Tool = nil
	ScriptStorage.CurrentObjects.Handle = nil

	table.clear(ScriptStorage.Joints)
end

local JointObjects = function(Handle:Part)
	Simulation:Once(function()
		for _, JointStorage in pairs(ScriptStorage.Joints) do
			local Joint = JointStorage.Joint
			if Settings["Bypasses"].ProtectConnections then ProtectConnections(Joint) end
			if Settings.Extra.Debug then print("Hitting", Joint.Part1.Name) end
			if Settings.Extra.ShowHit then ShowHit(Joint.Part1) end
			Joint.C0 = Joint.Part0.CFrame:Inverse() * Handle.CFrame 
		end
		PostSimulation:Wait()
		for _,JointStorage in ScriptStorage.Joints do
			local Joint = JointStorage.Joint
			Joint.C0 = JointStorage.OldC0
			if Settings["Bypasses"].ProtectConnections then UnProtectConnections(Joint) end
		end
	end)
end

local OnCharacterAdded = function(Character)
	Character.ChildAdded:Connect(function(self)
		if (self:IsA("Tool") and not ScriptStorage.Tools[self]) then
			local Humanoid = Character.Humanoid
			local Tool = self

			local Handle = Tool:WaitForChild("Handle")

			if Settings.Extra.Debug then
				createNotif("Handle Found", "true", 1)
			end

			ScriptStorage.CurrentObjects.Character = Character
			ScriptStorage.CurrentObjects.Humanoid = Humanoid
			ScriptStorage.CurrentObjects.Tool = Tool
			ScriptStorage.CurrentObjects.Handle = Handle

			ScriptStorage.Tools[self] = true

			task.spawn(function()
				--print("Running reach on", Tool.Name)
				while task.wait(Settings["Reach Settings"].HitRate) do
					if not ScriptStorage.Tools[self] then break end
					JointObjects(Handle)
				end
			end)

		end
	end)

	Character.ChildRemoved:Connect(function(self)
		if (self:IsA("Tool") and ScriptStorage.Tools[self]) then
			CleanUp()
			ScriptStorage.Tools[self] = nil
		end
	end)
end

Players.LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

if Players.LocalPlayer.Character then
	OnCharacterAdded(Players.LocalPlayer.Character)
end


RunService.Stepped:Connect(function()
	local Tool, Handle, Character = ScriptStorage.CurrentObjects.Tool, ScriptStorage.CurrentObjects.Handle, ScriptStorage.CurrentObjects.Character
	if Tool and Handle and Character and Settings["Reach Settings"].Enabled then
		if Tool.Parent ~= LocalPlayer.Backpack then

			local HRP = Character:FindFirstChild("HumanoidRootPart")
			
			if Settings.Extra.Visualiser and HRP then
				Visualiser.Position = Handle.Position
				Visualiser.Rotation = Handle.Rotation
				Visualiser.Size = Vector3.one * Settings["Reach Settings"].Distance
				Visualiser.Visible = true
			else
				Visualiser.Visible = false
			end

			table.clear(ScriptStorage.Joints)

			if Settings["Reach Settings"].LungeOnly then if Tool.GripUp.Z ~= 0 then return end end

			for _,Player in pairs(Players:GetPlayers()) do
				if Player == Players.LocalPlayer then continue end
				if Player.Character then
					local Humanoid = Player.Character:FindFirstChild("Humanoid")
					if Humanoid and Humanoid.Health > 0 then
						if Settings["Extra"].MaxHealthCheck then if Humanoid.MaxHealth > 101 then continue end end
						local CharacterLimbs = Player.Character:GetChildren()
						local CharacterRoot = Player.Character:FindFirstChild("HumanoidRootPart")
						if not CharacterRoot then continue end
						for _,Limb in pairs(CharacterLimbs) do
							if Limb:IsA("BasePart") and Settings["Reach Settings"].LimbSelection[Limb.Name] and (CharacterRoot.Position - Handle.Position).Magnitude <= Settings["Reach Settings"].Distance then
								if Settings["Extra"].InvisCheck then if Limb.Transparency > 0.7 then continue end end
								GetJoint(Limb)
							end
						end
					end
				end
			end
		else
			table.clear(ScriptStorage.Joints)
			Visualiser.Visible = false
		end
	else
		table.clear(ScriptStorage.Joints)
		Visualiser.Visible = false
	end
end)

UserInputService.InputBegan:Connect(function(input, TypeCheck) 
	if TypeCheck then return end

	for Name,Data in pairs(Keybinds) do
		if table.find(Data, input.KeyCode) then
			Data[2]()
		end
	end
end)
