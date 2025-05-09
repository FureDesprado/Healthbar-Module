-- DebugConsoleModule.lua

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local currentGui

local function destroyOld()
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end
end

local function makeDraggable(frame)
	local dragging = false
	local offset = Vector2.zero

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local pos = input.Position
			offset = Vector2.new(pos.X, pos.Y) - frame.AbsolutePosition
		end
	end)


	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			frame.Position = UDim2.new(0, input.Position.X - offset.X, 0, input.Position.Y - offset.Y)
		end
	end)
end

local function getObjectFromPath(path)
	local parts = path:split(".")
	warn(parts)
	local current = game
	for _, part in ipairs(parts) do
		if typeof(current) ~= "Instance" then return nil end
		current = current:FindFirstChild(part)
		if not current then return nil end
	end
	print(current)
	return current
end



local function describeObject(obj: Model)
	local lines = {}
	table.insert(lines, "Class: " .. obj.ClassName)
	table.insert(lines, "Name: " .. obj.Name)

	local attributes = obj:GetAttributes()
	if next(attributes) then
		table.insert(lines, "Attributes:")
		for k,v in pairs(attributes) do
			table.insert(lines, "  - " .. k .. ": " .. tostring(v))
		end
	end
	local tags = obj:GetTags()
	if next(tags) then
		table.insert(lines, "Tags:")
		for k,v in pairs(tags) do
			table.insert(lines, "  - " .. k .. ": " .. tostring(v))
		end
	end

	local children = obj:GetChildren()
	if #children > 0 then
		table.insert(lines, "Children:")
		for _, child in pairs(children) do
			table.insert(lines, "  - " .. child.Name .. " [" .. child.ClassName .. "]")
		end
	end

	return table.concat(lines, "\n")
end

local function getHierarchy(obj, depth)
	depth = depth or 0
	local indent = string.rep("  ", depth)
	local lines = {indent .. obj.Name .. " [" .. obj.ClassName .. "]"}
	for _, child in ipairs(obj:GetChildren()) do
		for _, l in ipairs(getHierarchy(child, depth + 1)) do
			table.insert(lines, l)
		end
	end
	return lines
end

local function getSuggestions(path)
	local lastDot = path:match(".*()%.")
	local basePath = lastDot and path:sub(1, lastDot - 1) or ""
	local prefix = lastDot and path:sub(lastDot + 1) or path

	local baseObj = getObjectFromPath(basePath ~= "" and basePath or "game")
	local suggestions = {}

	if baseObj then
		for _, child in ipairs(baseObj:GetChildren()) do
			if string.find(string.lower(child.Name), string.lower(prefix)) == 1 then
				table.insert(suggestions, basePath ~= "" and basePath .. "." .. child.Name or child.Name)
			end
		end
	end

	return suggestions
end

local function start()
	destroyOld()

	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugConsole"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	currentGui = gui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 500, 0, 400)
	frame.Position = UDim2.new(0, 200, 0, 200)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	makeDraggable(frame)

	local textbox = Instance.new("TextBox")
	textbox.Size = UDim2.new(1, -20, 0, 30)
	textbox.Position = UDim2.new(0, 10, 0, 10)
	textbox.TextColor3 = Color3.new(1,1,1)
	textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)
	textbox.ClearTextOnFocus = false
	textbox.TextXAlignment = Enum.TextXAlignment.Left
	textbox.Font = Enum.Font.Code
	textbox.TextSize = 16
	textbox.PlaceholderText = "Введите путь к объекту (например: workspace.Part)"
	textbox.Parent = frame

	local suggestionBox = Instance.new("Frame")
	suggestionBox.Size = UDim2.new(1, -20, 0, 100)
	suggestionBox.Position = UDim2.new(0, 10, 0, 45)
	suggestionBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	suggestionBox.BorderSizePixel = 0
	suggestionBox.Parent = frame

	local suggestionLayout = Instance.new("UIListLayout", suggestionBox)
	suggestionLayout.Padding = UDim.new(0, 2)
	suggestionLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -160)
	scrollFrame.Position = UDim2.new(0, 10, 0, 150)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = frame

	local outputLabel = Instance.new("TextLabel")
	outputLabel.Size = UDim2.new(1, -10, 0, 0)
	outputLabel.Position = UDim2.new(0, 5, 0, 0)
	outputLabel.TextColor3 = Color3.fromRGB(230,230,230)
	outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	outputLabel.TextYAlignment = Enum.TextYAlignment.Top
	outputLabel.Font = Enum.Font.Code
	outputLabel.TextWrapped = false
	outputLabel.TextSize = 14
	outputLabel.Text = ""
	outputLabel.BackgroundTransparency = 1
	outputLabel.TextScaled = false
	outputLabel.Parent = scrollFrame

	local mode = "info"

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 150, 0, 25)
	toggle.Position = UDim2.new(1, -160, 0, -20)
	toggle.Text = "Mode: Info"
	toggle.Font = Enum.Font.Code
	toggle.TextSize = 14
	toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.Parent = frame

	toggle.MouseButton1Click:Connect(function()
		mode = (mode == "info") and "hierarchy" or "info"
		toggle.Text = "Mode: " .. (mode == "info" and "Info" or "Hierarchy")
	end)

	local function updateSuggestions()
		for _, child in ipairs(suggestionBox:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local suggestions = getSuggestions(textbox.Text)
		for _, suggestion in ipairs(suggestions) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 20)
			btn.Text = suggestion
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Font = Enum.Font.Code
			btn.TextSize = 14
			btn.Parent = suggestionBox

			btn.MouseButton1Click:Connect(function()
				textbox.Text = suggestion
				updateSuggestions()
			end)
		end
	end

	textbox:GetPropertyChangedSignal("Text"):Connect(updateSuggestions)

	textbox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local obj = getObjectFromPath(textbox.Text)
			outputLabel:ClearAllChildren()

			if obj then
				if mode == "info" then
					local out = describeObject(obj)
					outputLabel.Text = out
					outputLabel.Size = UDim2.new(1, -10, 0, #out:split("\n") * 18)
				else
					outputLabel.Text = ""
					local function renderEntry(parent, object, depth)
						local line = Instance.new("Frame")
						line.Size = UDim2.new(1, 0, 0, 20)
						line.BackgroundTransparency = 1
						line.LayoutOrder = depth
						line.Parent = parent

						local indent = Instance.new("TextLabel")
						indent.Size = UDim2.new(0, depth * 14, 1, 0)
						indent.BackgroundTransparency = 1
						indent.Text = ""
						indent.Parent = line

						local toggle = Instance.new("TextButton")
						toggle.Size = UDim2.new(0, 14, 1, 0)
						toggle.Position = UDim2.new(0, depth * 14, 0, 0)
						toggle.Text = object:IsA("Folder") or #object:GetChildren() > 0 and "->" or ""
						toggle.BackgroundTransparency = 1
						toggle.TextColor3 = Color3.fromRGB(180, 180, 180)
						toggle.Font = Enum.Font.Code
						toggle.TextSize = 14
						toggle.Parent = line

						local label = Instance.new("TextLabel")
						label.Size = UDim2.new(1, -depth * 14 - 14, 1, 0)
						label.Position = UDim2.new(0, depth * 14 + 14, 0, 0)
						label.BackgroundTransparency = 1
						label.TextXAlignment = Enum.TextXAlignment.Left
						label.Text = object.Name .. " [" .. object.ClassName .. "]"
						label.Font = Enum.Font.Code
						label.TextSize = 14
						label.TextColor3 = Color3.fromRGB(220, 220, 220)
						label.Parent = line

						local childrenFrame = Instance.new("Frame")
						childrenFrame.Size = UDim2.new(1, 0, 0, 0)
						childrenFrame.BackgroundTransparency = 1
						childrenFrame.AutomaticSize = Enum.AutomaticSize.Y
						childrenFrame.LayoutOrder = depth + 0.1
						childrenFrame.Visible = false
						childrenFrame.Parent = parent

						local layout = Instance.new("UIListLayout")
						layout.SortOrder = Enum.SortOrder.LayoutOrder
						layout.Parent = childrenFrame

						local expanded = false
						toggle.MouseButton1Click:Connect(function()
							expanded = not expanded
							toggle.Text = expanded and "#" or "->"
							childrenFrame.Visible = expanded
							if expanded and #childrenFrame:GetChildren() <= 1 then
								for _, child in ipairs(object:GetChildren()) do
									renderEntry(childrenFrame, child, depth + 1)
								end
							end
						end)
					end

					local layout = Instance.new("UIListLayout")
					layout.SortOrder = Enum.SortOrder.LayoutOrder
					layout.Parent = outputLabel

					renderEntry(outputLabel, obj, 0)
				end
			else
				outputLabel.Text = "Объект не найден или недоступен."
			end
		end
	end)


	UIS.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab and textbox:IsFocused() then
			local suggestions = getSuggestions(textbox.Text)
			if #suggestions > 0 then
				textbox.Text = suggestions[1]
				updateSuggestions()
			end
		end
	end)
end

start()
