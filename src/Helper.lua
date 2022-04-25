local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')

local Settings = require(script.Parent:WaitForChild("Settings"))

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character = Player.Character or Player:WaitForChild("Character")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local AimOffset = script.Parent:WaitForChild("AimOffset") -- a property for other scripts to use to influence the viewmodel offset (such as a gun aim system)
local Waist
local UpperTorso
local LowerTorso
local RootHip
local LeftShoulder
local RightShoulder
local LeftArm
local RightArm
local ArmParts = {}

local Helper = {}

local isR15 = Humanoid.RigType == Enum.HumanoidRigType.R15
Helper.isRunning = false
local armsVisible = Settings.ARM_TRANSPARENCY ~= 1
local sway = Vector3.new(0,0,0)
local walkSway = CFrame.new(0,0,0)
local strafeSway = CFrame.Angles(0,0,0)
local jumpSway = CFrame.new(0,0,0)
local jumpSwayGoal = Instance.new("CFrameValue")


local viewModel: Model
local fHumanoidRootPart: Part
local fUpperTorso: Part
local fLowerTorso: Part
local fWaist -- Clone of Player's waist
local fLeftShoulder
local fRightShoulder
local fRootHip

Helper.RenderConnection = nil


function Helper.CreateFakes()
    viewModel = Instance.new("Model")
    viewModel.Name = "ViewModel"

    fHumanoidRootPart = Instance.new("Part")
    fHumanoidRootPart.Name = "HumanoidRootPart"
    fHumanoidRootPart.CanCollide = false
    fHumanoidRootPart.CanTouch = false
    fHumanoidRootPart.Anchored = true
    fHumanoidRootPart.Transparency = 1
    fHumanoidRootPart.Parent = viewModel

    viewModel.PrimaryPart = fHumanoidRootPart
    viewModel.WorldPivot = fHumanoidRootPart.CFrame+fHumanoidRootPart.CFrame.UpVector*5

    fUpperTorso = Instance.new("Part")
    fUpperTorso.Name = "UpperTorso"
    fUpperTorso.CanCollide = false
    fUpperTorso.CanTouch = false
    fUpperTorso.Transparency = 1
    fUpperTorso.Parent = viewModel

    fLowerTorso = Instance.new("Part")
	fLowerTorso.Name = "LowerTorso"
	fLowerTorso.CanCollide = false
	fLowerTorso.Anchored = false
	fLowerTorso.CanTouch = false
	fLowerTorso.Transparency = 1
	--flowertorso.Massless = true
	fLowerTorso.Parent = viewModel
end

function Helper.CreateArmPartList(character: Model)
    if isR15 then
        table.insert(ArmParts, character:WaitForChild("RightLowerArm"))
        table.insert(ArmParts, character:WaitForChild("LeftUpperArm"))
        table.insert(ArmParts, character:WaitForChild("RightUpperArm"))
        table.insert(ArmParts, character:WaitForChild("LeftLowerArm"))
        table.insert(ArmParts, character:WaitForChild("RightLowerArm"))
        table.insert(ArmParts, character:WaitForChild("LeftHand"))
        table.insert(ArmParts, character:WaitForChild("RightHand"))
    else
        table.insert(ArmParts, Character:WaitForChild("Right Arm"))
	    table.insert(ArmParts, Character:WaitForChild("Left Arm"))
    end
end

-- R6 left | R15 right -- UNLESS nil
local function setParts()
    UpperTorso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
    LowerTorso = Character:FindFirstChild("LowerTorso") or nil
    Waist = UpperTorso:FindFirstChild("Waist") or nil
    RootHip = HumanoidRootPart:FindFirstChildOfClass("Motor6D") or nil
    LeftShoulder = UpperTorso:FindFirstChild("Left Shoulder") or Character:FindFirstChild("LeftUpperArm"):FindFirstChild("LeftShoulder")
    RightShoulder = UpperTorso:FindFirstChild("Right Shoulder") or Character:FindFirstChild("RightUpperArm"):FindFirstChild("RightShoulder")
    LeftArm = Character:FindFirstChild("Left Arm") or Character:FindFirstChild("LeftUpperArm")
    RightArm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightUpperArm")
end

function Helper.Setup()
    setParts()

    fLeftShoulder = LeftShoulder:Clone()
    fLeftShoulder.Name = "LeftShoulderClone"
    fLeftShoulder.Parent = if isR15 then fUpperTorso else UpperTorso
    fLeftShoulder.Part0 = if isR15 then LeftArm else UpperTorso

    fRightShoulder = RightShoulder:Clone()
	fRightShoulder.Name = "RightShoulderClone"
	fRightShoulder.Parent = if isR15 then fUpperTorso else UpperTorso
	fRightShoulder.Part0 = if isR15 then RightArm else UpperTorso

    Helper.CreateArmPartList(Character)

    fUpperTorso.Size = UpperTorso.Size
    fUpperTorso.CFrame = fHumanoidRootPart.CFrame

    print(isR15)
    fRootHip = if isR15 then LowerTorso:FindFirstChild("Root"):Clone() else RootHip:Clone()
    fRootHip.Parent = if isR15 then fLowerTorso else fHumanoidRootPart
    fRootHip.Part0 = fHumanoidRootPart
    fRootHip.Part1 = if isR15 then fLowerTorso else fUpperTorso

    fHumanoidRootPart.Size = HumanoidRootPart.Size

    if isR15 then
        fWaist = if Settings.WAIST_MOVEMENTS then Waist:Clone() else Instance.new("Weld")
        fWaist.Parent = fUpperTorso
        fWaist.Part0 = fLowerTorso
        fWaist.Part1 = fUpperTorso

        if not Settings.WAIST_MOVEMENTS then
            fWaist.C0 = Waist.C0
            fWaist.C1 = Waist.C1
        end

        if isR15 then
            fLowerTorso.Size = LowerTorso.Size
        end
    end


end

function Helper.SetArmTransparency(visible: boolean)
    if armsVisible then
        for _, part in ipairs(ArmParts) do
            part.LocalTransparencyModifier = if not visible then 1 else Settings.ARM_TRANSPARENCY
            part.CastShadow = not visible
        end
    end
end

function Helper.Enable()
    viewModel.Parent = Workspace.CurrentCamera
    Camera.CameraSubject = Workspace[Player.Name].Humanoid -- Fixes Bug: Respawn when not in 1st person, locks First Person Camera to death location

    -- disable character joints, enable viewmodel joints
    fRightShoulder.Enabled = true
    fLeftShoulder.Enabled = true
    -- disable real shoulders
    LeftShoulder.Enabled = false
    RightShoulder.Enabled = false

    fRightShoulder.Part1 = RightArm
    fRightShoulder.Part0 = fUpperTorso
    fRightShoulder.Parent = fUpperTorso

    fLeftShoulder.Part1 = LeftArm
    fLeftShoulder.Part0 = fUpperTorso
    fLeftShoulder.Parent = fUpperTorso
end

function Helper.Disable()
    viewModel.Parent = nil

    -- disable viewmodel joints, enable real character joints
    fRightShoulder.Enabled = false
    fLeftShoulder.Enabled = false

    LeftShoulder.Parent = if isR15 then LeftArm else UpperTorso
    LeftShoulder.Part0 = UpperTorso
    LeftShoulder.Part1 = LeftArm

    RightShoulder.Parent = if isR15 then RightArm else UpperTorso
    RightShoulder.Part0 = UpperTorso
    RightShoulder.Part1 = RightArm

    LeftShoulder.Enabled = true
    RightShoulder.Enabled = true

    Helper.SetArmTransparency(true)
end

function Helper.isFirstPerson()
    return Player.CameraMode == Enum.CameraMode.LockFirstPerson
end

local function tween(instance: CFrameValue, info: TweenInfo, properties: table): Tween
    return TweenService:Create(instance, info, properties)
end

function Helper.LandingAnimation()
    -- animate the camera's landing "thump"
    --
    -- tween a dummy cframe value for camera recoil
    local camEdit = Instance.new("CFrameValue")
    camEdit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(-0.75)*Settings.SWAY_SIZE,0,0)

    local tweenInfo = TweenInfo.new((0.03*6)/Settings.SENSITIVITY, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local landedRecoil = tween(camEdit, tweenInfo, {Value = CFrame.new(0,0,0)})
    landedRecoil:Play()
    Debris:AddItem(landedRecoil, 2)

    landedRecoil.Completed:Connect(function()
        camEdit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(0.225)*Settings.SWAY_SIZE,0,0)

        local tweenInfo = TweenInfo.new((0.03*24)/Settings.SENSITIVITY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local landRecovery = tween(camEdit, tweenInfo, {Value = CFrame.new(0,0,0)})
        landRecovery:Play()
        Debris:AddItem(landRecovery, 3)
    end)

    -- apply the camera adjustments
    task.spawn(function()
        for i = 1,60 do
            Camera.CFrame = Camera.CFrame*camEdit.Value
            RunService.Heartbeat:Wait()
        end
    end)

    -- animate the jump sway to make the viewmodel thump down on landing
    local tweenInfo = TweenInfo.new(0.15/Settings.SENSITIVITY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local viewModelRecoil = tween(jumpSwayGoal, tweenInfo, {Value = CFrame.new(0,0,0)*CFrame.Angles(-math.rad(5)*Settings.SWAY_SIZE,0,0)})
    viewModelRecoil:Play()
    Debris:AddItem(viewModelRecoil, 2)

    viewModelRecoil.Completed:Connect(function()
        local tweenInfo = TweenInfo.new(0.7/Settings.SENSITIVITY, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local viewModelRecovery = tween(jumpSwayGoal, tweenInfo, {Value = CFrame.new(0,0,0)})
        viewModelRecovery:Play()
        Debris:AddItem(viewModelRecovery, 2)
    end)
end

function Helper.JumpAnimation()
    local tweenInfo = TweenInfo.new(0.5/Settings.SENSITIVITY, Enum.EasingStyle.Sine)
    local viewModelJump = tween(jumpSwayGoal, tweenInfo, {Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(7.5)*Settings.SWAY_SIZE,0,0)})
    viewModelJump:Play()
    Debris:AddItem(viewModelJump, 2)
end

function Helper.Reset()
    Helper.RenderConnection:Disconnect()
    fLeftShoulder:Destroy()
    fRightShoulder:Destroy()
    viewModel:Destroy()

    -- R15
    if UpperTorso:FindFirstChild("Waist") then
        UpperTorso.Waist.Enabled = true
        UpperTorso.Anchored = false
    end
    -- R6
    if RightShoulder then
        RightShoulder.Enabled = true
        RightArm.Anchored = false
    end
    if LeftShoulder then
        LeftShoulder.Enabled = true
        LeftArm.Anchored = false
    end

    print("Reset")
    Helper.SetArmTransparency(true)
end

local enabled = false

-- perform the update loop
function Helper.Update()
	if Helper.isFirstPerson() then
        if not enabled then
            Helper.Enable()
		    Helper.SetArmTransparency(true)
        end

		if Helper.isRunning and Settings.INCLUDE_WALK_SWAY and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Humanoid:GetState() ~= Enum.HumanoidStateType.Landed then -- update walk sway if we are walking
            walkSway = if isR15 then
                walkSway:Lerp(
                CFrame.new(
                    (0.1 * Settings.SWAY_SIZE) * math.sin(tick() * (2 * Humanoid.WalkSpeed/4)),
                    (0.1  *Settings.SWAY_SIZE) * math.cos(tick() * (4 * Humanoid.WalkSpeed/4)),
                    0) * CFrame.Angles(0, 0, (-.05 * Settings.SWAY_SIZE) * math.sin(tick() * (2 * Humanoid.WalkSpeed/4)))
                , 0.1 * Settings.SENSITIVITY)
            else
                walkSway:Lerp(
					CFrame.new(
						(0.07*Settings.SWAY_SIZE) * math.sin(tick() * (2 * Humanoid.WalkSpeed/4)),
						(0.07*Settings.SWAY_SIZE) * math.cos(tick() * (4 * Humanoid.WalkSpeed/4)),
						0) * CFrame.Angles(0, 0, (-.03 * Settings.SWAY_SIZE) * math.sin(tick() * (2 * Humanoid.WalkSpeed/4)))
					,0.2 * Settings.SENSITIVITY)
        else
            walkSway = walkSway:Lerp(CFrame.new(), 0.05*Settings.SENSITIVITY)
		end

        local delta = UserInputService:GetMouseDelta()
        if Settings.INCLUDE_CAMERA_SWAY then
            sway = sway:Lerp(Vector3.new(delta.X,delta.Y,delta.X/2), 0.1*Settings.SENSITIVITY)
        end

        if Settings.INCLUDE_STRAFE then
            local rz = if isR15 then HumanoidRootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(10/Settings.SWAY_SIZE) else HumanoidRootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(20/Settings.SWAY_SIZE)
            strafeSway = strafeSway:Lerp(CFrame.Angles(0, 0, -rz), 0.1 * Settings.SENSITIVITY)
        end

        if Helper.INCLUDE_JUMP_SWAY then
            jumpSway = jumpSwayGoal.Value
        end

        -- update animation transform for viewmodel
        fRightShoulder.Transform = RightShoulder.Transform
        fLeftShoulder.Transform = LeftShoulder.Transform
        if Settings.WAIST_MOVEMENTS and isR15 then
            fWaist.Transform = Waist.Transform
        end

        -- cframe the viewmodel
        local completedCFrame = (Camera.CFrame*walkSway*jumpSway*strafeSway*CFrame.Angles(math.rad(sway.Y*Settings.SWAY_SIZE),math.rad(sway.X*Settings.SWAY_SIZE)/10,math.rad(sway.Z*Settings.SWAY_SIZE)/2))+(Camera.CFrame.UpVector*(-1.7-(Settings.HEAD_OFFSET.Y+(AimOffset.Value.Y))))+(Camera.CFrame.LookVector*(Settings.HEAD_OFFSET.Z+(AimOffset.Value.Z)))+(Camera.CFrame.RightVector*(-Settings.HEAD_OFFSET.X-(AimOffset.Value.X)+(-(sway.X*Settings.SWAY_SIZE)/75)))
        viewModel:SetPrimaryPartCFrame(completedCFrame)
    else
        Helper.Disable()
	end
end

return Helper