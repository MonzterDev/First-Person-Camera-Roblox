---------------------------------------------------------------------------------------------

-- EasyFirstPerson by yellowfats 2021.
-- Place in StarterCharacterScripts

---------------------------------------------------------------------------------------------
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Helper = require(script:WaitForChild("Helper"))
local Settings = require(script:WaitForChild("Settings"))

local Player = Players.LocalPlayer
local Character = Player.Character or Player:WaitForChild("Character")
local Humanoid = Character:WaitForChild("Humanoid")

repeat task.wait() until Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")

Helper.CreateFakes()
Helper.Setup()

if Player.CameraMode == Enum.CameraMode.LockFirstPerson then
	Helper.Enable()
end

Humanoid.Running:Connect(function(speed)
	Helper.isRunning = speed ~= 0
end)

-- listen for jumping and landing and apply sway and camera mvoement to the viewmodel
Humanoid.StateChanged:Connect(function(oldstate, newstate)
	if Helper.isFirstPerson and Settings.INCLUDE_JUMP_SWAY then -- dont apply camera/viewmodel changes if we aren't in first person
		if newstate == Enum.HumanoidStateType.Landed then
			Helper.LandingAnimation()
		elseif newstate == Enum.HumanoidStateType.Freefall then -- animate jump sway when the character is falling or jumping
			Helper.JumpAnimation()
		end
	end
end)

-- detect if they lock first person mode during a live game
Player.Changed:Connect(function(property)
	if property == "CameraMaxZoomDistance" or property == "CameraMode" then
		if Player.CameraMaxZoomDistance <= 0.5 or Player.CameraMode == Enum.CameraMode.LockFirstPerson then
			Helper.Enable()
		end
	end
end)

Humanoid.Died:Connect(function()
	Helper.Disable()
end)

Helper.RenderConnection = RunService.RenderStepped:Connect(Helper.Update)
