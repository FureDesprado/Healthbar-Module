-- HealthBarModule.lua
local HealthBarModule = {}

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local healthBars = {}

local function createBillboard(humanoid:Humanoid)
	local character = humanoid.Parent
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local root = character.HumanoidRootPart

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HP_Bar"
	billboard.Size = UDim2.new(0.2, 0, 4, 0)
	billboard.StudsOffset = Vector3.new(1.5, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 10000
	billboard.Adornee = root
	billboard.Parent = root

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	background.BorderSizePixel = 0
	background.Parent = billboard
	background.Rotation = 180
	local ui = Instance.new('UIStroke')
	ui.Parent = background
	ui.Transparency = 0
	ui.Color = Color3.fromRGB(176, 255, 167)
	ui.Thickness = 1.5
	local healthBarRED = Instance.new("Frame")
	healthBarRED.Name = "HealthBarRED"
	healthBarRED.Size = UDim2.new(1, 0, 1, 0)
	healthBarRED.BackgroundColor3 = Color3.new(0.564706, 0, 0.00784314)
	healthBarRED.BorderSizePixel = 0
	healthBarRED.ZIndex = 1
	healthBarRED.Parent = background
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.new(1, 1, 1)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = background
	healthBar.ZIndex = 2
	local grad = Instance.new('UIGradient')
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.new(0, 0.701961, 0.317647)),
		ColorSequenceKeypoint.new(1,Color3.new(0, 1, 0.45098)),
	}
	)
	grad.Parent = healthBar
	grad.Rotation = 25
	
	local label = Instance.new('TextLabel')
	label.Name = 'HP'
	label.Parent = background
	label.Position = UDim2.new(-0.5,0,0,0)
	label.Size = UDim2.new(2,0,1,0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Highway
	label.Rotation = 180
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.ZIndex = 4
	label.Text = 'H: '..math.round(humanoid.Health)..' MAX: '..math.round(humanoid.MaxHealth)
	
	table.insert(healthBars, {
		humanoid = humanoid,
		bar = healthBar,
		gui = billboard,
	})
	
	task.spawn(function()
		humanoid.HealthChanged:Connect(function(helt)
			--healthBar.Size = UDim2.new(humanoid.Health/humanoid.MaxHealth,0,1,0)
			label.Text = 'H: '..math.round(humanoid.Health)..' MAX: '..math.round(humanoid.MaxHealth)
			game.TweenService:Create(healthBar, TweenInfo.new(0.5,Enum.EasingStyle.Sine),{Size = UDim2.new(1,0,humanoid.Health/humanoid.MaxHealth,0)}):Play()
			task.wait(0.12)
			game.TweenService:Create(healthBarRED, TweenInfo.new(0.5,Enum.EasingStyle.Sine),{Size = UDim2.new(1,0,humanoid.Health/humanoid.MaxHealth,0)}):Play()
		end)
	end)
	
end

local function clearBars()
	for _, entry in pairs(healthBars) do
		if entry.gui then
			entry.gui:Destroy()
		end
	end
	healthBars = {}
end

function HealthBarModule.Start()
	clearBars()
	for _, model in pairs(workspace:GetDescendants()) do
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			createBillboard(hum)
		end
	end
	
	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA('Humanoid') then
			createBillboard(desc)
		end
	end)
	
end

return HealthBarModule
