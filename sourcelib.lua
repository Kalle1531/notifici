-- RobloxMenuLib.lua
-- A custom Roblox Menu GUI library
-- Author: Cody (Sourcegraph AI)

local RobloxMenuLib = {}
RobloxMenuLib.__index = RobloxMenuLib

-- Constants
local TWEEN_SERVICE = game:GetService("TweenService")
local PLAYERS = game:GetService("Players")
local LOCAL_PLAYER = PLAYERS.LocalPlayer
local SCREEN_GUI_NAME = "RobloxMenuLibGUI"

-- Default settings
local DEFAULT_SETTINGS = {
    MenuWidth = 300,
    MenuHeight = 400,
    BackgroundColor = Color3.fromRGB(40, 40, 40),
    BorderColor = Color3.fromRGB(60, 60, 60),
    TextColor = Color3.fromRGB(255, 255, 255),
    ButtonColor = Color3.fromRGB(60, 60, 60),
    ButtonHoverColor = Color3.fromRGB(80, 80, 80),
    HeaderColor = Color3.fromRGB(30, 30, 30),
    Font = Enum.Font.SourceSansBold,
    CornerRadius = UDim.new(0, 6),
    TweenSpeed = 0.3,
    TweenStyle = Enum.EasingStyle.Quint,
    CloseOnUnfocus = true,
}

-- Create a new menu instance
function RobloxMenuLib.new(title, settings)
    local self = setmetatable({}, RobloxMenuLib)
    
    -- Merge default settings with provided settings
    self.settings = {}
    for key, value in pairs(DEFAULT_SETTINGS) do
        self.settings[key] = (settings and settings[key] ~= nil) and settings[key] or value
    end
    
    self.title = title or "Menu"
    self.elements = {}
    self.visible = false
    self.dragging = false
    self.dragStart = nil
    self.startPos = nil
    
    -- Create the GUI
    self:_createGui()
    
    return self
end

-- Create the base GUI elements
function RobloxMenuLib:_createGui()
    -- Find or create ScreenGui
    local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")
    self.screenGui = playerGui:FindFirstChild(SCREEN_GUI_NAME)
    
    if not self.screenGui then
        self.screenGui = Instance.new("ScreenGui")
        self.screenGui.Name = SCREEN_GUI_NAME
        self.screenGui.ResetOnSpawn = false
        self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        self.screenGui.Parent = playerGui
    end
    
    -- Create main frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "Menu_" .. self.title
    self.mainFrame.Size = UDim2.new(0, self.settings.MenuWidth, 0, self.settings.MenuHeight)
    self.mainFrame.Position = UDim2.new(0.5, -self.settings.MenuWidth/2, 0.5, -self.settings.MenuHeight/2)
    self.mainFrame.BackgroundColor3 = self.settings.BackgroundColor
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Visible = false
    self.mainFrame.Parent = self.screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.settings.CornerRadius
    corner.Parent = self.mainFrame
    
    -- Create header
    self.header = Instance.new("Frame")
    self.header.Name = "Header"
    self.header.Size = UDim2.new(1, 0, 0, 30)
    self.header.BackgroundColor3 = self.settings.HeaderColor
    self.header.BorderSizePixel = 0
    self.header.Parent = self.mainFrame
    
    -- Add corner radius to header
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = self.settings.CornerRadius
    headerCorner.Parent = self.header
    
    -- Create title
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "Title"
    self.titleLabel.Size = UDim2.new(1, -60, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 10, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = self.title
    self.titleLabel.TextColor3 = self.settings.TextColor
    self.titleLabel.Font = self.settings.Font
    self.titleLabel.TextSize = 18
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Parent = self.header
    
    -- Create close button
    self.closeButton = Instance.new("TextButton")
    self.closeButton.Name = "CloseButton"
    self.closeButton.Size = UDim2.new(0, 30, 0, 30)
    self.closeButton.Position = UDim2.new(1, -30, 0, 0)
    self.closeButton.BackgroundTransparency = 1
    self.closeButton.Text = "X"
    self.closeButton.TextColor3 = self.settings.TextColor
    self.closeButton.Font = self.settings.Font
    self.closeButton.TextSize = 18
    self.closeButton.Parent = self.header
    
    -- Create content frame
    self.contentFrame = Instance.new("ScrollingFrame")
    self.contentFrame.Name = "Content"
    self.contentFrame.Size = UDim2.new(1, -20, 1, -40)
    self.contentFrame.Position = UDim2.new(0, 10, 0, 35)
    self.contentFrame.BackgroundTransparency = 1
    self.contentFrame.BorderSizePixel = 0
    self.contentFrame.ScrollBarThickness = 4
    self.contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.contentFrame.Parent = self.mainFrame
    
    -- Setup auto layout for content
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.contentFrame
    
    -- Setup padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = self.contentFrame
    
    -- Setup events
    self:_setupEvents()
end

-- Setup event handlers
function RobloxMenuLib:_setupEvents()
    -- Close button
    self.closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
    
    -- Dragging functionality
    self.header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.dragging = true
            self.dragStart = input.Position
            self.startPos = self.mainFrame.Position
        end
    end)
    
    self.header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if self.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - self.dragStart
            self.mainFrame.Position = UDim2.new(
                self.startPos.X.Scale,
                self.startPos.X.Offset + delta.X,
                self.startPos.Y.Scale,
                self.startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Auto-update content frame canvas size
    self.contentFrame.ChildAdded:Connect(function()
        self:_updateCanvasSize()
    end)
    
    self.contentFrame.ChildRemoved:Connect(function()
        self:_updateCanvasSize()
    end)
    
    -- Close on unfocus if enabled
    if self.settings.CloseOnUnfocus then
        game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and self.visible then
                local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                local guiObjects = self.screenGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
                
                local isClickingMenu = false
                for _, obj in pairs(guiObjects) do
                    if obj:IsDescendantOf(self.mainFrame) then
                        isClickingMenu = true
                        break
                    end
                end
                
                if not isClickingMenu then
                    self:hide()
                end
            end
        end)
    end
end

-- Update canvas size based on content
function RobloxMenuLib:_updateCanvasSize()
    local contentHeight = self.contentFrame.UIListLayout.AbsoluteContentSize.Y + 10
    self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

-- Show the menu with animation
function RobloxMenuLib:show()
    if self.visible then return end
    
    self.mainFrame.Visible = true
    self.mainFrame.Size = UDim2.new(0, self.settings.MenuWidth, 0, 0)
    self.mainFrame.Position = UDim2.new(0.5, -self.settings.MenuWidth/2, 0.5, 0)
    
    local targetSize = UDim2.new(0, self.settings.MenuWidth, 0, self.settings.MenuHeight)
    local targetPosition = UDim2.new(0.5, -self.settings.MenuWidth/2, 0.5, -self.settings.MenuHeight/2)
    
    local tweenInfo = TweenInfo.new(
        self.settings.TweenSpeed,
        self.settings.TweenStyle,
        Enum.EasingDirection.Out
    )
    
    local sizeTween = TWEEN_SERVICE:Create(self.mainFrame, tweenInfo, {
        Size = targetSize,
        Position = targetPosition
    })
    
    sizeTween:Play()
    self.visible = true
end

-- Hide the menu with animation
function RobloxMenuLib:hide()
    if not self.visible then return end
    
    local targetSize = UDim2.new(0, self.settings.MenuWidth, 0, 0)
    local targetPosition = UDim2.new(0.5, -self.settings.MenuWidth/2, 0.5, 0)
    
    local tweenInfo = TweenInfo.new(
        self.settings.TweenSpeed,
        self.settings.TweenStyle,
        Enum.EasingDirection.In
    )
    
    local sizeTween = TWEEN_SERVICE:Create(self.mainFrame, tweenInfo, {
        Size = targetSize,
        Position = targetPosition
    })
    
    sizeTween.Completed:Connect(function()
        if not self.visible then
            self.mainFrame.Visible = false
        end
    end)
    
    sizeTween:Play()
    self.visible = false
end

-- Toggle menu visibility
function RobloxMenuLib:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

-- Add a button to the menu
function RobloxMenuLib:addButton(text, callback)
    local button = Instance.new("TextButton")
    button.Name = "Button_" .. text
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = self.settings.ButtonColor
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = self.settings.TextColor
    button.Font = self.settings.Font
    button.TextSize = 16
    button.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        TWEEN_SERVICE:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonHoverColor
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TWEEN_SERVICE:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonColor
        }):Play()
    end)
    
    -- Click callback
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    
    self:_updateCanvasSize()
    return button
end

-- Add a label to the menu
function RobloxMenuLib:addLabel(text)
    local label = Instance.new("TextLabel")
    label.Name = "Label_" .. text
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.Parent = self.contentFrame
    
    self:_updateCanvasSize()
    return label
end

-- Add a toggle switch to the menu
function RobloxMenuLib:addToggle(text, initialState, callback)
    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. text
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self.settings.ButtonColor
    container.BorderSizePixel = 0
    container.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Add toggle background
    local toggleBackground = Instance.new("Frame")
    toggleBackground.Name = "ToggleBackground"
    toggleBackground.Size = UDim2.new(0, 40, 0, 20)
    toggleBackground.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBackground.BorderSizePixel = 0
    toggleBackground.Parent = container
    
    -- Add corner radius to toggle background
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBackground
    
    -- Add toggle indicator
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Name = "Indicator"
    toggleIndicator.Size = UDim2.new(0, 16, 0, 16)
    toggleIndicator.Position = UDim2.new(0, 2, 0.5, -8)
    toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleIndicator.BorderSizePixel = 0
    toggleIndicator.Parent = toggleBackground
    
    -- Add corner radius to toggle indicator
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = toggleIndicator
    
    -- Toggle state
    local isToggled = initialState or false
    
    -- Update toggle appearance based on state
    local function updateToggle()
        local targetPosition
        local targetColor
        
        if isToggled then
            targetPosition = UDim2.new(1, -18, 0.5, -8)
            targetColor = Color3.fromRGB(0, 162, 255)
        else
            targetPosition = UDim2.new(0, 2, 0.5, -8)
            targetColor = Color3.fromRGB(60, 60, 60)
        end
        
        TWEEN_SERVICE:Create(toggleIndicator, TweenInfo.new(0.2), {
            Position = targetPosition
        }):Play()
        
        TWEEN_SERVICE:Create(toggleBackground, TweenInfo.new(0.2), {
            BackgroundColor3 = targetColor
        }):Play()
    end
    
    -- Initialize toggle appearance
    updateToggle()
    
    -- Toggle functionality
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isToggled = not isToggled
            updateToggle()
            
            if callback then
                callback(isToggled)
            end
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonHoverColor
        }):Play()
    end)
    
    container.MouseLeave:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonColor
        }):Play()
    end)
    
    self:_updateCanvasSize()
    
    -- Return functions to get/set the toggle state
    return {
        getState = function() return isToggled end,
        setState = function(state)
            isToggled = state
            updateToggle()
            if callback then
                callback(isToggled)
            end
        end,
        toggle = function()
            isToggled = not isToggled
            updateToggle()
            if callback then
                callback(isToggled)
            end
        end,
        instance = container
    }
end

-- Add a slider to the menu
function RobloxMenuLib:addSlider(text, min, max, initial, callback)
    min = min or 0
    max = max or 100
    initial = initial or min
    
    -- Clamp initial value
    initial = math.max(min, math.min(max, initial))
    
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. text
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = self.settings.ButtonColor
    container.BorderSizePixel = 0
    container.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Add value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -60, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(initial)
    valueLabel.TextColor3 = self.settings.TextColor
    valueLabel.Font = self.settings.Font
    valueLabel.TextSize = 16
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    -- Add slider background
    local sliderBackground = Instance.new("Frame")
    sliderBackground.Name = "SliderBackground"
    sliderBackground.Size = UDim2.new(1, -20, 0, 6)
    sliderBackground.Position = UDim2.new(0, 10, 0, 30)
    sliderBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    sliderBackground.BorderSizePixel = 0
    sliderBackground.Parent = container
    
    -- Add corner radius to slider background
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderBackground
    
    -- Add slider fill
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBackground
    
    -- Add corner radius to slider fill
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    -- Add slider knob
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((initial - min) / (max - min), -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.ZIndex = 2
    sliderKnob.Parent = sliderBackground
    
    -- Add corner radius to slider knob
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = sliderKnob
    
    -- Current value
    local currentValue = initial
    
    -- Update slider appearance based on value
    local function updateSlider(value)
        -- Clamp value
        value = math.max(min, math.min(max, value))
        currentValue = value
        
        -- Calculate percentage
        local percent = (value - min) / (max - min)
        
        -- Update UI
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percent, -8, 0.5, -8)
        valueLabel.Text = tostring(math.floor(value * 10) / 10)
        
        -- Call callback
        if callback then
            callback(value)
        end
    end
    
    -- Slider functionality
    local dragging = false
    
    sliderBackground.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            
            -- Calculate value from mouse position
            local mousePos = input.Position.X
            local sliderPos = sliderBackground.AbsolutePosition.X
            local sliderSize = sliderBackground.AbsoluteSize.X
            local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
            local value = min + (max - min) * percent
            
            updateSlider(value)
        end
    end)
    
    sliderBackground.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Calculate value from mouse position
            local mousePos = input.Position.X
            local sliderPos = sliderBackground.AbsolutePosition.X
            local sliderSize = sliderBackground.AbsoluteSize.X
            local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
            local value = min + (max - min) * percent
            
            updateSlider(value)
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonHoverColor
        }):Play()
    end)
    
    container.MouseLeave:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonColor
        }):Play()
    end)
    
    self:_updateCanvasSize()
    
    -- Return functions to get/set the slider value
    return {
        getValue = function() return currentValue end,
        setValue = function(value) updateSlider(value) end,
        instance = container
    }
end

-- Add a dropdown to the menu
function RobloxMenuLib:addDropdown(text, options, initialSelection, callback)
    options = options or {}
    local initialIndex = 1
    
    if initialSelection then
        for i, option in ipairs(options) do
            if option == initialSelection then
                initialIndex = i
                break
            end
        end
    end
    
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. text
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self.settings.ButtonColor
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 36)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Add selected value
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Name = "Selected"
    selectedLabel.Size = UDim2.new(0, 100, 0, 36)
    selectedLabel.Position = UDim2.new(1, -110, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = options[initialIndex] or "Select..."
    selectedLabel.TextColor3 = self.settings.TextColor
    selectedLabel.Font = self.settings.Font
    selectedLabel.TextSize = 16
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
    selectedLabel.Parent = container
    
    -- Add dropdown arrow
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 0, 36)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = self.settings.TextColor
    arrow.Font = self.settings.Font
    arrow.TextSize = 14
    arrow.Parent = container
    
    -- Add dropdown content
    local dropdownContent = Instance.new("Frame")
    dropdownContent.Name = "Content"
    dropdownContent.Size = UDim2.new(1, 0, 0, #options * 30)
    dropdownContent.Position = UDim2.new(0, 0, 0, 36)
    dropdownContent.BackgroundColor3 = self.settings.ButtonColor
    dropdownContent.BorderSizePixel = 0
    dropdownContent.Visible = false
    dropdownContent.Parent = container
    
    -- Add corner radius to dropdown content
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 4)
    contentCorner.Parent = dropdownContent
    
    -- Add options
    local optionButtons = {}
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option_" .. option
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.Position = UDim2.new(0, 0, 0, (i-1) * 30)
        optionButton.BackgroundTransparency = 1
        optionButton.Text = option
        optionButton.TextColor3 = self.settings.TextColor
        optionButton.Font = self.settings.Font
        optionButton.TextSize = 14
        optionButton.Parent = dropdownContent
        
        -- Hover effects
        optionButton.MouseEnter:Connect(function()
            TWEEN_SERVICE:Create(optionButton, TweenInfo.new(0.1), {
                BackgroundTransparency = 0.8,
                BackgroundColor3 = self.settings.ButtonHoverColor
            }):Play()
        end)
        
        optionButton.MouseLeave:Connect(function()
            TWEEN_SERVICE:Create(optionButton, TweenInfo.new(0.1), {
                BackgroundTransparency = 1
            }):Play()
        end)
        
        -- Selection functionality
        optionButton.MouseButton1Click:Connect(function()
            selectedLabel.Text = option
            toggleDropdown(false)
            
            if callback then
                callback(option, i)
            end
        end)
        
        table.insert(optionButtons, optionButton)
    end
    
    -- Dropdown state
    local isOpen = false
    
    -- Toggle dropdown function
    function toggleDropdown(state)
        isOpen = state ~= nil and state or not isOpen
        
        if isOpen then
            container.Size = UDim2.new(1, 0, 0, 36 + dropdownContent.Size.Y.Offset)
            dropdownContent.Visible = true
            TWEEN_SERVICE:Create(arrow, TweenInfo.new(0.2), {
                Rotation = 180
            }):Play()
        else
            TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 36)
            }):Play()
            
            TWEEN_SERVICE:Create(arrow, TweenInfo.new(0.2), {
                Rotation = 0
            }):Play()
            
            task.delay(0.2, function()
                if not isOpen then
                    dropdownContent.Visible = false
                end
            end)
        end
        
        self:_updateCanvasSize()
    end
    
    -- Toggle dropdown on click
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Position.Y <= container.AbsolutePosition.Y + 36 then
            toggleDropdown()
        end
    end)
    
    -- Close dropdown when clicking elsewhere
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            local guiObjects = self.screenGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
            
            local isClickingDropdown = false
            for _, obj in pairs(guiObjects) do
                if obj:IsDescendantOf(container) then
                    isClickingDropdown = true
                    break
                end
            end
            
            if not isClickingDropdown then
                toggleDropdown(false)
            end
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        if not isOpen then
            TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
                BackgroundColor3 = self.settings.ButtonHoverColor
            }):Play()
        end
    end)
    
    container.MouseLeave:Connect(function()
        if not isOpen then
            TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
                BackgroundColor3 = self.settings.ButtonColor
            }):Play()
        end
    end)
    
    self:_updateCanvasSize()
    
    -- Return functions to get/set the dropdown value
    return {
        getValue = function() return selectedLabel.Text end,
        setValue = function(value)
            for i, option in ipairs(options) do
                if option == value then
                    selectedLabel.Text = option
                    if callback then
                        callback(option, i)
                    end
                    break
                end
            end
        end,
        instance = container
    }
end

-- Add a text input field to the menu
function RobloxMenuLib:addTextInput(text, placeholder, initialValue, callback)
    local container = Instance.new("Frame")
    container.Name = "TextInput_" .. text
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = self.settings.ButtonColor
    container.BorderSizePixel = 0
    container.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Add input box
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "Input"
    inputBox.Size = UDim2.new(1, -20, 0, 30)
    inputBox.Position = UDim2.new(0, 10, 0, 25)
    inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    inputBox.BorderSizePixel = 0
    inputBox.Text = initialValue or ""
    inputBox.PlaceholderText = placeholder or "Enter text..."
    inputBox.TextColor3 = self.settings.TextColor
    inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    inputBox.Font = self.settings.Font
    inputBox.TextSize = 14
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = container
    
    -- Add corner radius to input box
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputBox
    
    -- Input functionality
    inputBox.FocusLost:Connect(function(enterPressed)
        if callback then
            callback(inputBox.Text, enterPressed)
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonHoverColor
        }):Play()
    end)
    
    container.MouseLeave:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonColor
        }):Play()
    end)
    
    self:_updateCanvasSize()
    
    -- Return functions to get/set the input value
    return {
        getValue = function() return inputBox.Text end,
        setValue = function(value) inputBox.Text = value or "" end,
        instance = container
    }
end

-- Add a color picker to the menu
function RobloxMenuLib:addColorPicker(text, initialColor, callback)
    initialColor = initialColor or Color3.fromRGB(255, 255, 255)
    
    local container = Instance.new("Frame")
    container.Name = "ColorPicker_" .. text
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self.settings.ButtonColor
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Add color display
    local colorDisplay = Instance.new("Frame")
    colorDisplay.Name = "ColorDisplay"
    colorDisplay.Size = UDim2.new(0, 30, 0, 20)
    colorDisplay.Position = UDim2.new(1, -40, 0.5, -10)
    colorDisplay.BackgroundColor3 = initialColor
    colorDisplay.BorderSizePixel = 0
    colorDisplay.Parent = container
    
    -- Add corner radius to color display
    local displayCorner = Instance.new("UICorner")
    displayCorner.CornerRadius = UDim.new(0, 4)
    displayCorner.Parent = colorDisplay
    
    -- Add color picker panel
    local pickerPanel = Instance.new("Frame")
    pickerPanel.Name = "PickerPanel"
    pickerPanel.Size = UDim2.new(1, 0, 0, 120)
    pickerPanel.Position = UDim2.new(0, 0, 0, 36)
    pickerPanel.BackgroundColor3 = self.settings.ButtonColor
    pickerPanel.BorderSizePixel = 0
    pickerPanel.Visible = false
    pickerPanel.Parent = container
    
    -- Add corner radius to picker panel
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 4)
    panelCorner.Parent = pickerPanel
    
    -- Add RGB sliders
    local sliders = {}
    local colors = {
        {name = "R", color = Color3.fromRGB(255, 0, 0), value = initialColor.R},
        {name = "G", color = Color3.fromRGB(0, 255, 0), value = initialColor.G},
        {name = "B", color = Color3.fromRGB(0, 0, 255), value = initialColor.B}
    }
    
    for i, colorInfo in ipairs(colors) do
        local sliderContainer = Instance.new("Frame")
        sliderContainer.Name = colorInfo.name .. "Container"
        sliderContainer.Size = UDim2.new(1, -20, 0, 30)
        sliderContainer.Position = UDim2.new(0, 10, 0, 10 + (i-1) * 35)
        sliderContainer.BackgroundTransparency = 1
        sliderContainer.Parent = pickerPanel
        
        -- Add label
        local sliderLabel = Instance.new("TextLabel")
        sliderLabel.Name = "Label"
        sliderLabel.Size = UDim2.new(0, 20, 1, 0)
        sliderLabel.BackgroundTransparency = 1
        sliderLabel.Text = colorInfo.name
        sliderLabel.TextColor3 = self.settings.TextColor
        sliderLabel.Font = self.settings.Font
        sliderLabel.TextSize = 14
        sliderLabel.Parent = sliderContainer
        
        -- Add value label
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.Size = UDim2.new(0, 30, 1, 0)
        valueLabel.Position = UDim2.new(1, -30, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(math.floor(colorInfo.value * 255))
        valueLabel.TextColor3 = self.settings.TextColor
        valueLabel.Font = self.settings.Font
        valueLabel.TextSize = 14
        valueLabel.Parent = sliderContainer
        
        -- Add slider background
        local sliderBackground = Instance.new("Frame")
        sliderBackground.Name = "SliderBackground"
        sliderBackground.Size = UDim2.new(1, -60, 0, 6)
        sliderBackground.Position = UDim2.new(0, 25, 0.5, -3)
        sliderBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sliderBackground.BorderSizePixel = 0
        sliderBackground.Parent = sliderContainer
        
        -- Add corner radius to slider background
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(1, 0)
        sliderCorner.Parent = sliderBackground
        
        -- Add slider fill
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.Size = UDim2.new(colorInfo.value, 0, 1, 0)
        sliderFill.BackgroundColor3 = colorInfo.color
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBackground
        
        -- Add corner radius to slider fill
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = sliderFill
        
        -- Add slider knob
        local sliderKnob = Instance.new("Frame")
        sliderKnob.Name = "Knob"
        sliderKnob.Size = UDim2.new(0, 12, 0, 12)
        sliderKnob.Position = UDim2.new(colorInfo.value, -6, 0.5, -6)
        sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderKnob.BorderSizePixel = 0
        sliderKnob.ZIndex = 2
        sliderKnob.Parent = sliderBackground
        
        -- Add corner radius to slider knob
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = sliderKnob
        
        sliders[colorInfo.name] = {
            container = sliderContainer,
            background = sliderBackground,
            fill = sliderFill,
            knob = sliderKnob,
            valueLabel = valueLabel,
            value = colorInfo.value
        }
    end
    
    -- Current color
    local currentColor = initialColor
    
    -- Update color based on RGB values
    local function updateColor()
        currentColor = Color3.fromRGB(
            math.floor(sliders.R.value * 255),
            math.floor(sliders.G.value * 255),
            math.floor(sliders.B.value * 255)
        )
        
        colorDisplay.BackgroundColor3 = currentColor
        
        if callback then
            callback(currentColor)
        end
    end
    
    -- Update slider appearance and value
    local function updateSlider(slider, value)
        -- Clamp value between 0 and 1
        value = math.clamp(value, 0, 1)
        slider.value = value
        
        -- Update UI
        slider.fill.Size = UDim2.new(value, 0, 1, 0)
        slider.knob.Position = UDim2.new(value, -6, 0.5, -6)
        slider.valueLabel.Text = tostring(math.floor(value * 255))
        
        -- Update color
        updateColor()
    end
    
    -- Slider functionality
    for name, slider in pairs(sliders) do
        local dragging = false
        
        slider.background.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                
                -- Calculate value from mouse position
                local mousePos = input.Position.X
                local sliderPos = slider.background.AbsolutePosition.X
                local sliderSize = slider.background.AbsoluteSize.X
                local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
                
                updateSlider(slider, percent)
            end
        end)
        
        slider.background.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                -- Calculate value from mouse position
                local mousePos = input.Position.X
                local sliderPos = slider.background.AbsolutePosition.X
                local sliderSize = slider.background.AbsoluteSize.X
                local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
                
                updateSlider(slider, percent)
            end
        end)
    end
    
    -- Color picker state
    local isOpen = false
    
    -- Toggle color picker function
    local function togglePicker(state)
        isOpen = state ~= nil and state or not isOpen
        
        if isOpen then
            container.Size = UDim2.new(1, 0, 0, 36 + pickerPanel.Size.Y.Offset)
            pickerPanel.Visible = true
        else
            TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 36)
            }):Play()
            
            task.delay(0.2, function()
                if not isOpen then
                    pickerPanel.Visible = false
                end
            end)
        end
        
        self:_updateCanvasSize()
    end
    
    -- Toggle color picker on click
    colorDisplay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            togglePicker()
        end
    end)
    
    -- Close color picker when clicking elsewhere
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            local guiObjects = self.screenGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
            
            local isClickingPicker = false
            for _, obj in pairs(guiObjects) do
                if obj:IsDescendantOf(container) then
                    isClickingPicker = true
                    break
                end
            end
            
            if not isClickingPicker then
                togglePicker(false)
            end
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        if not isOpen then
            TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
                BackgroundColor3 = self.settings.ButtonHoverColor
            }):Play()
        end
    end)
    
    container.MouseLeave:Connect(function()
        if not isOpen then
            TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
                BackgroundColor3 = self.settings.ButtonColor
            }):Play()
        end
    end)
    
    self:_updateCanvasSize()
    
    -- Return functions to get/set the color
    return {
        getColor = function() return currentColor end,
        setColor = function(color)
            if typeof(color) == "Color3" then
                -- Update sliders
                updateSlider(sliders.R, color.R)
                updateSlider(sliders.G, color.G)
                updateSlider(sliders.B, color.B)
                
                -- Update color display
                colorDisplay.BackgroundColor3 = color
                currentColor = color
                
                if callback then
                    callback(color)
                end
            end
        end,
        instance = container
    }
end

-- Add a separator to the menu
function RobloxMenuLib:addSeparator(thickness, padding)
    thickness = thickness or 1
    padding = padding or 5
    
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, thickness + padding * 2)
    separator.BackgroundTransparency = 1
    separator.Parent = self.contentFrame
    
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.Size = UDim2.new(1, 0, 0, thickness)
    line.Position = UDim2.new(0, 0, 0, padding)
    line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    line.BorderSizePixel = 0
    line.Parent = separator
    
    self:_updateCanvasSize()
    return separator
end

-- Add a section header to the menu
function RobloxMenuLib:addSection(text)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. text
    section.Size = UDim2.new(1, 0, 0, 30)
    section.BackgroundTransparency = 1
    section.Parent = self.contentFrame
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.Parent = section
    
    self:_updateCanvasSize()
    return section
end

-- Add a keybind selector to the menu
function RobloxMenuLib:addKeybind(text, initialKey, callback)
    local container = Instance.new("Frame")
    container.Name = "Keybind_" .. text
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self.settings.ButtonColor
    container.BorderSizePixel = 0
    container.Parent = self.contentFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.settings.TextColor
    label.Font = self.settings.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Add keybind button
    local keyButton = Instance.new("TextButton")
    keyButton.Name = "KeyButton"
    keyButton.Size = UDim2.new(0, 60, 0, 24)
    keyButton.Position = UDim2.new(1, -70, 0.5, -12)
    keyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    keyButton.BorderSizePixel = 0
    keyButton.Text = initialKey and initialKey.Name or "None"
    keyButton.TextColor3 = self.settings.TextColor
    keyButton.Font = self.settings.Font
    keyButton.TextSize = 14
    keyButton.Parent = container
    
    -- Add corner radius to key button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = keyButton
    
    -- Current key
    local currentKey = initialKey
    
    -- Listening for key state
    local listening = false
    
    -- Toggle listening state
    local function toggleListening()
        listening = not listening
        
        if listening then
            keyButton.Text = "..."
            keyButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        else
            keyButton.Text = currentKey and currentKey.Name or "None"
            keyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end
    
    -- Key button click
    keyButton.MouseButton1Click:Connect(toggleListening)
    
    -- Key input
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            toggleListening()
            
            if callback then
                callback(currentKey)
            end
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonHoverColor
        }):Play()
    end)
    
    container.MouseLeave:Connect(function()
        TWEEN_SERVICE:Create(container, TweenInfo.new(0.2), {
            BackgroundColor3 = self.settings.ButtonColor
        }):Play()
    end)
    
    self:_updateCanvasSize()
    
    -- Return functions to get/set the keybind
    return {
        getKey = function() return currentKey end,
        setKey = function(key)
            if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
                currentKey = key
                keyButton.Text = key.Name
                
                if callback then
                    callback(key)
                end
            end
        end,
        instance = container
    }
end

-- Clear all elements from the menu
function RobloxMenuLib:clear()
    for _, child in pairs(self.contentFrame:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    self.elements = {}
    self:_updateCanvasSize()
end

-- Destroy the menu
function RobloxMenuLib:destroy()
    if self.mainFrame then
        self.mainFrame:Destroy()
    end
end

-- Return the library
return RobloxMenuLib