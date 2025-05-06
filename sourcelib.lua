local SkottiUI = {}
SkottiUI.__index = SkottiUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local PLAYER = Players.LocalPlayer
local MOUSE = PLAYER:GetMouse()
local SCREEN_GUI = Instance.new("ScreenGui")

-- UI Settings/Theme
local SETTINGS = {
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    
    -- Color Theme
    Colors = {
        Background = Color3.fromRGB(30, 30, 35),
        SecondaryBackground = Color3.fromRGB(40, 40, 45),
        Accent = Color3.fromRGB(90, 140, 240),
        AccentDark = Color3.fromRGB(70, 110, 210),
        Text = Color3.fromRGB(240, 240, 240),
        TextDark = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(50, 200, 100),
        Warning = Color3.fromRGB(240, 175, 60),
        Error = Color3.fromRGB(240, 80, 80)
    },
    
    -- Animation Settings
    TweenInfo = {
        Short = TweenService:Create({Time = 0.15, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out}),
        Medium = TweenService:Create({Time = 0.3, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out}),
        Long = TweenService:Create({Time = 0.5, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out})
    },
    
    -- UI Element Settings
    ElementHeight = 40,
    Padding = 10,
    CornerRadius = 8,
    WindowSize = Vector2.new(550, 400),
    MinWindowSize = Vector2.new(400, 300),
}

-- Utility Functions
local Utils = {}

-- Create a new instance with properties
function Utils.Create(className, properties)
    local instance = Instance.new(className)
    
    for property, value in pairs(properties) do
        instance[property] = value
    end
    
    return instance
end

-- Create a rounded frame
function Utils.CreateRoundedFrame(properties)
    local frame = Utils.Create("Frame", properties)
    local corner = Utils.Create("UICorner", {
        CornerRadius = UDim.new(0, SETTINGS.CornerRadius),
        Parent = frame
    })
    
    return frame
end

-- Create a shadow effect
function Utils.AddShadow(parent, opacity)
    opacity = opacity or 0.2
    
    local shadow = Utils.Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 24, 1, 24),
        ZIndex = parent.ZIndex - 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 1 - opacity,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = parent
    })
    
    return shadow
end

-- Create a tween for an instance
function Utils.Tween(instance, properties, duration, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration or 0.3, 
        easingStyle or Enum.EasingStyle.Quad, 
        easingDirection or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    
    return tween
end

-- Make a frame draggable
function Utils.MakeDraggable(frame, dragFrame)
    dragFrame = dragFrame or frame
    
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Apply hover effect
function Utils.ApplyHoverEffect(button, onEnter, onLeave)
    button.MouseEnter:Connect(function()
        if onEnter then onEnter() end
    end)
    
    button.MouseLeave:Connect(function()
        if onLeave then onLeave() end
    end)
end

-- Initialize
function SkottiUI:Init()
    if SCREEN_GUI.Parent then
        return self
    end
    
    -- Set up ScreenGui
    SCREEN_GUI.Name = "SkottiUI"
    SCREEN_GUI.ResetOnSpawn = false
    SCREEN_GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SCREEN_GUI.IgnoreGuiInset = true
    
    -- Parent to the correct location based on context
    if RunService:IsStudio() then
        SCREEN_GUI.Parent = PLAYER.PlayerGui
    else
        if game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
            SCREEN_GUI.Parent = game:GetService("CoreGui").RobloxGui
        else
            SCREEN_GUI.Parent = game:GetService("CoreGui")
        end
    end
    
    return self
end

-- Create window
function SkottiUI:CreateWindow(title)
    local window = {}
    
    -- Initialize library if not done already
    self:Init()
    
    -- Create main window container
    window.Container = Utils.CreateRoundedFrame({
        Name = "WindowContainer",
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(SETTINGS.WindowSize.X, SETTINGS.WindowSize.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SETTINGS.Colors.Background,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = SCREEN_GUI
    })
    
    -- Add shadow
    Utils.AddShadow(window.Container)
    
    -- Create title bar
    window.TitleBar = Utils.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = SETTINGS.Colors.SecondaryBackground,
        ZIndex = 11,
        Parent = window.Container
    })
    
    Utils.Create("UICorner", {
        CornerRadius = UDim.new(0, SETTINGS.CornerRadius),
        Parent = window.TitleBar
    })
    
    -- Create title
    window.Title = Utils.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Font = SETTINGS.Font,
        Text = title or "SkottiUI",
        TextColor3 = SETTINGS.Colors.Text,
        TextSize = SETTINGS.TextSize + 2,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = window.TitleBar
    })
    
    -- Create close button
    window.CloseButton = Utils.Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = SETTINGS.Colors.Error,
        BackgroundTransparency = 0.8,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = window.TitleBar
    })
    
    Utils.Create("UICorner", {
        CornerRadius = UDim.new(0, SETTINGS.CornerRadius),
        Parent = window.CloseButton
    })
    
    -- Add close button X symbol
    window.CloseButtonSymbol = Utils.Create("TextLabel", {
        Name = "X",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = SETTINGS.Colors.Text,
        TextSize = 20,
        ZIndex = 13,
        Parent = window.CloseButton
    })
    
    -- Handle close button hover effect
    Utils.ApplyHoverEffect(
        window.CloseButton,
        function()
            Utils.Tween(window.CloseButton, {BackgroundTransparency = 0}, 0.2)
        end,
        function()
            Utils.Tween(window.CloseButton, {BackgroundTransparency = 0.8}, 0.2)
        end
    )
    
    -- Handle close button click
    window.CloseButton.MouseButton1Click:Connect(function()
        Utils.Tween(window.Container, {Size = UDim2.fromOffset(0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        wait(0.3)
        window.Container:Destroy()
    end)
    
    -- Create content container
    window.ContentContainer = Utils.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 11,
        Parent = window.Container
    })
    
    -- Create tab container
    window.TabContainer = Utils.Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 130, 1, 0),
        BackgroundColor3 = SETTINGS.Colors.SecondaryBackground,
        ZIndex = 11,
        Parent = window.ContentContainer
    })
    
    -- Create tab buttons container
    window.TabButtonsContainer = Utils.Create("ScrollingFrame", {
        Name = "TabButtonsContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 12,
        Parent = window.TabContainer
    })
    
    -- Add padding to tab buttons
    Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, SETTINGS.Padding),
        PaddingLeft = UDim.new(0, SETTINGS.Padding),
        PaddingRight = UDim.new(0, SETTINGS.Padding),
        Parent = window.TabButtonsContainer
    })
    
    -- Add list layout to tab buttons
    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, SETTINGS.Padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = window.TabButtonsContainer
    })
    
    -- Create tab content container
    window.TabContentContainer = Utils.Create("Frame", {
        Name = "TabContentContainer",
        Size = UDim2.new(1, -130, 1, 0),
        Position = UDim2.new(0, 130, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 11,
        Parent = window.ContentContainer
    })
    
    -- Make the window draggable
    Utils.MakeDraggable(window.Container, window.TitleBar)
    
    -- Create tabs table
    window.Tabs = {}
    window.ActiveTab = nil
    
    -- Add a tab to the window
    function window:AddTab(name)
        local tab = {}
        
        -- Create tab button
        tab.Button = Utils.CreateRoundedFrame({
            Name = name .. "TabButton",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = #self.Tabs == 0 and SETTINGS.Colors.Accent or SETTINGS.Colors.SecondaryBackground,
            ZIndex = 13,
            Parent = self.TabButtonsContainer
        })
        
        -- Create tab button label
        tab.ButtonLabel = Utils.Create("TextLabel", {
            Name = "ButtonLabel",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = SETTINGS.Font,
            Text = name,
            TextColor3 = #self.Tabs == 0 and SETTINGS.Colors.Text or SETTINGS.Colors.TextDark,
            TextSize = SETTINGS.TextSize,
            ZIndex = 14,
            Parent = tab.Button
        })
        
        -- Create tab content frame
        tab.Content = Utils.Create("ScrollingFrame", {
            Name = name .. "TabContent",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
            Visible = #self.Tabs == 0,
            ZIndex = 12,
            Parent = self.TabContentContainer
        })
        
        -- Add padding to tab content
        Utils.Create("UIPadding", {
            PaddingTop = UDim.new(0, SETTINGS.Padding),
            PaddingLeft = UDim.new(0, SETTINGS.Padding),
            PaddingRight = UDim.new(0, SETTINGS.Padding),
            PaddingBottom = UDim.new(0, SETTINGS.Padding),
            Parent = tab.Content
        })
        
        -- Add list layout to tab content
        tab.ContentList = Utils.Create("UIListLayout", {
            Padding = UDim.new(0, SETTINGS.Padding),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tab.Content
        })
        
        -- Update ScrollingFrame canvas size when elements are added
        tab.ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.ContentList.AbsoluteContentSize.Y + SETTINGS.Padding)
        end)
        
        -- Handle tab button click
        tab.Button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:SelectTab(name)
            end
        end)
        
        -- Apply hover effect to tab button
        Utils.ApplyHoverEffect(
            tab.Button,
            function()
                if self.ActiveTab ~= name then
                    Utils.Tween(tab.Button, {BackgroundColor3 = SETTINGS.Colors.SecondaryBackground:Lerp(SETTINGS.Colors.Accent, 0.3)}, 0.2)
                    Utils.Tween(tab.ButtonLabel, {TextColor3 = SETTINGS.Colors.TextDark:Lerp(SETTINGS.Colors.Text, 0.3)}, 0.2)
                end
            end,
            function()
                if self.ActiveTab ~= name then
                    Utils.Tween(tab.Button, {BackgroundColor3 = SETTINGS.Colors.SecondaryBackground}, 0.2)
                    Utils.Tween(tab.ButtonLabel, {TextColor3 = SETTINGS.Colors.TextDark}, 0.2)
                end
            end
        )
        
        -- Add tab to tabs table
        self.Tabs[name] = tab
        
        -- Set as active tab if it's the first one
        if #self.Tabs == 1 then
            self.ActiveTab = name
        end
        
        -- Create sections table
        tab.Sections = {}
        
        -- Add a section to the tab
        function tab:AddSection(sectionName)
            local section = {}
            
            -- Create section container
            section.Container = Utils.CreateRoundedFrame({
                Name = sectionName .. "Section",
                Size = UDim2.new(1, -SETTINGS.Padding, 0, 36),  -- Will be resized based on content
                BackgroundColor3 = SETTINGS.Colors.SecondaryBackground,
                ZIndex = 13,
                Parent = self.Content
            })
            
            -- Create section title
            section.Title = Utils.Create("TextLabel", {
                Name = "SectionTitle",
                Size = UDim2.new(1, -SETTINGS.Padding * 2, 0, 36),
                Position = UDim2.new(0, SETTINGS.Padding, 0, 0),
                BackgroundTransparency = 1,
                Font = SETTINGS.Font,
                Text = sectionName,
                TextColor3 = SETTINGS.Colors.Text,
                TextSize = SETTINGS.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
                Parent = section.Container
            })
            
            -- Create section content
            section.Content = Utils.Create("Frame", {
                Name = "SectionContent",
                Size = UDim2.new(1, 0, 1, -36),
                Position = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex = 14,
                Parent = section.Container
            })
            
            -- Add padding to section content
            Utils.Create("UIPadding", {
                PaddingLeft = UDim.new(0, SETTINGS.Padding),
                PaddingRight = UDim.new(0, SETTINGS.Padding),
                PaddingBottom = UDim.new(0, SETTINGS.Padding),
                Parent = section.Content
            })
            
            -- Add list layout to section content
            section.ContentList = Utils.Create("UIListLayout", {
                Padding = UDim.new(0, SETTINGS.Padding),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = section.Content
            })
            
            -- Update section size when elements are added
            section.ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                section.Container.Size = UDim2.new(1, -SETTINGS.Padding, 0, section.ContentList.AbsoluteContentSize.Y + 36 + SETTINGS.Padding)
            end)
            
            -- Function to add a button to the section
            function section:AddButton(options)
                local button = {}
                
                -- Default options
                options = options or {}
                options.Name = options.Name or "Button"
                options.Description = options.Description or ""
                options.Callback = options.Callback or function() end
                
                -- Create button container
                button.Container = Utils.CreateRoundedFrame({
                    Name = options.Name .. "Button",
                    Size = UDim2.new(1, 0, 0, options.Description ~= "" and 60 or 40),
                    BackgroundColor3 = SETTINGS.Colors.Background,
                    ZIndex = 15,
                    Parent = self.Content
                })
                
                -- Create button
                button.Button = Utils.CreateRoundedFrame({
                    Name = "ButtonElement",
                    Size = UDim2.new(0, 100, 0, 30),
                    Position = UDim2.new(1, -110, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = SETTINGS.Colors.Accent,
                    ZIndex = 16,
                    Parent = button.Container
                })
                
                -- Create button label
                button.ButtonLabel = Utils.Create("TextLabel", {
                    Name = "ButtonLabel",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Font = SETTINGS.Font,
                    Text = "Execute",
                    TextColor3 = SETTINGS.Colors.Text,
                    TextSize = SETTINGS.TextSize,
                    ZIndex = 17,
                    Parent = button.Button
                })
                
                -- Make the button clickable
                button.ClickDetector = Utils.Create("TextButton", {
                    Name = "ClickDetector",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 18,
                    Parent = button.Button
                })
                
                -- Create button name label
                button.NameLabel = Utils.Create("TextLabel", {
                    Name = "NameLabel",
                    Size = UDim2.new(1, -130, 0, 20),
                    Position = UDim2.new(0, 10, 0, options.Description ~= "" and 10 or 10),
                    BackgroundTransparency = 1,
                    Font = SETTINGS.Font,
                    Text = options.Name,
                    TextColor3 = SETTINGS.Colors.Text,
                    TextSize = SETTINGS.TextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 16,
                    Parent = button.Container
                })
                
                -- Create description label if provided
                if options.Description ~= "" then
                    button.DescriptionLabel = Utils.Create("TextLabel", {
                        Name = "DescriptionLabel",
                        Size = UDim2.new(1, -130, 0, 20),
                        Position = UDim2.new(0, 10, 0, 35),
                        BackgroundTransparency = 1,
                        Font = SETTINGS.Font,
                        Text = options.Description,
                        TextColor3 = SETTINGS.Colors.TextDark,
                        TextSize = SETTINGS.TextSize - 2,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 16,
                        Parent = button.Container
                    })
                end
                
                -- Handle button hover effect
                Utils.ApplyHoverEffect(
                    button.ClickDetector,
                    function()
                        Utils.Tween(button.Button, {BackgroundColor3 = SETTINGS.Colors.AccentDark}, 0.2)
                    end,
                    function()
                        Utils.Tween(button.Button, {BackgroundColor3 = SETTINGS.Colors.Accent}, 0.2)
                    end
                )
                
                -- Handle button click
                button.ClickDetector.MouseButton1Click:Connect(function()
                    -- Animation effect
                    Utils.Tween(button.Button, {Size = UDim2.new(0, 95, 0, 28)}, 0.1)
                    task.wait(0.1)
                    Utils.Tween(button.Button, {Size = UDim2.new(0, 100, 0, 30)}, 0.1)
                    
                    -- Call the callback function
                    task.spawn(options.Callback)
                end)
                
                return button
            end
            
            -- Function to add a toggle to the section
            function section:AddToggle(options)
                local toggle = {}
                
                -- Default options
                options = options or {}
                options.Name = options.Name or "Toggle"
                options.Description = options.Description or ""
                options.Default = options.Default or false
                options.Callback = options.Callback or function() end
                
                -- Toggle state
                toggle.Value = options.Default
                
                -- Create toggle container
                toggle.Container = Utils.CreateRoundedFrame({
                    Name = options.Name .. "Toggle",
                    Size = UDim2.new(1, 0, 0, options.Description ~= "" and 60 or 40),
                    BackgroundColor3 = SETTINGS.Colors.Background,
                    ZIndex = 15,
                    Parent = self.Content
                })
                
                -- Create toggle name label
                toggle.NameLabel = Utils.Create("TextLabel", {
                    Name = "NameLabel",
                    Size = UDim2.new(1, -90, 0, 20),
                    Position = UDim2.new(0, 10, 0, options.Description ~= "" and 10 or 10),
                    BackgroundTransparency = 1,
                    Font = SETTINGS.Font,
                    Text = options.Name,
                    TextColor3 = SETTINGS.Colors.Text,
                    TextSize = SETTINGS.TextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 16,
                    Parent = toggle.Container
                })
                
                -- Create description label if provided
                if options.Description ~= "" then
                    toggle.DescriptionLabel = Utils.Create("TextLabel", {
                        Name = "DescriptionLabel",
                        Size = UDim2.new(1, -90, 0, 20),
                        Position = UDim2.new(0, 10, 0, 35),
                        BackgroundTransparency = 1,
                        Font = SETTINGS.Font,
                        Text = options.Description,
                        TextColor3 = SETTINGS.Colors.TextDark,
                        TextSize = SETTINGS.TextSize - 2,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 16,
                        Parent = toggle.Container
                    })
                end
                
                -- Create toggle background
                toggle.Background = Utils.CreateRoundedFrame({
                    Name = "ToggleBackground",
                    Size = UDim2.new(0, 50, 0, 26),
                    Position = UDim2.new(1, -60, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = toggle.Value and SETTINGS.Colors.Accent or SETTINGS.Colors.SecondaryBackground,
                    ZIndex = 16,
                    Parent = toggle.Container
                })
                
                -- Create toggle indicator
                toggle.Indicator = Utils.CreateRoundedFrame({
                    Name = "ToggleIndicator",
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(toggle.Value and 1 or 0, toggle.Value and -23 or 3, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = SETTINGS.Colors.Text,
                    ZIndex = 17,
                    Parent = toggle.Background
                })
                
                -- Create toggle click detector
                toggle.ClickDetector = Utils.Create("TextButton", {
                    Name = "ToggleClickDetector",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 18,
                    Parent = toggle.Container
                })
                
                -- Function to update toggle state
                function toggle:SetValue(value)
                    self.Value = value
                    
                    -- Update visuals
                    Utils.Tween(toggle.Background, {BackgroundColor3 = value and SETTINGS.Colors.Accent or SETTINGS.Colors.SecondaryBackground}, 0.2)
                    Utils.Tween(toggle.Indicator, {Position = UDim2.new(value and 1 or 0, value and -23 or 3, 0.5, 0)}, 0.2)
                    
                    -- Call callback
                    options.Callback(value)
                end
                
                -- Initialize with default value
                if options.Default then
                    toggle:SetValue(true)
                end
                
                -- Handle toggle click
                toggle.ClickDetector.MouseButton1Click:Connect(function()
                    toggle:SetValue(not toggle.Value)
                end)
                
                return toggle
            end
            
            -- Add section to tab's sections table
            self.Sections[sectionName] = section
            
            return section
        end
        
        return tab
    end
    
    -- Function to select a tab
    function window:SelectTab(tabName)
        -- Check if tab exists
        if not self.Tabs[tabName] then return end
        
        -- Deselect previous active tab
        if self.ActiveTab and self.Tabs[self.ActiveTab] then
            Utils.Tween(self.Tabs[self.ActiveTab].Button, {BackgroundColor3 = SETTINGS.Colors.SecondaryBackground}, 0.2)
            Utils.Tween(self.Tabs[self.ActiveTab].ButtonLabel, {TextColor3 = SETTINGS.Colors.TextDark}, 0.2)
            self.Tabs[self.ActiveTab].Content.Visible = false
        end
        
        -- Select new tab
        Utils.Tween(self.Tabs[tabName].Button, {BackgroundColor3 = SETTINGS.Colors.Accent}, 0.2)
        Utils.Tween(self.Tabs[tabName].ButtonLabel, {TextColor3 = SETTINGS.Colors.Text}, 0.2)
        self.Tabs[tabName].Content.Visible = true
        
        -- Update active tab
        self.ActiveTab = tabName
    end
    
    -- Notification system
    function window:Notify(title, message, notificationType)
        notificationType = notificationType or "Info"
        
        -- Define colors based on notification type
        local colors = {
            Success = SETTINGS.Colors.Success,
            Info = SETTINGS.Colors.Accent,
            Warning = SETTINGS.Colors.Warning,
            Error = SETTINGS.Colors.Error
        }
        
        local color = colors[notificationType] or colors.Info
        
        -- Create notification container
        local notification = Utils.CreateRoundedFrame({
            Name = "Notification",
            Position = UDim2.new(1, -20, 1, -20),
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 300, 0, 80),
            BackgroundColor3 = SETTINGS.Colors.Background,
            ZIndex = 100,
            Parent = SCREEN_GUI
        })
        
        -- Add shadow
        Utils.AddShadow(notification, 0.3)
        
        -- Create colored indicator
        local indicator = Utils.Create("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, 6, 1, 0),
            BackgroundColor3 = color,
            ZIndex = 101,
            Parent = notification
        })
        
        Utils.Create("UICorner", {
            CornerRadius = UDim.new(0, SETTINGS.CornerRadius),
            Parent = indicator
        })
        
        -- Create title label
        local notificationTitle = Utils.Create("TextLabel", {
            Name = "Title",
            Position = UDim2.new(0, 16, 0, 10),
            Size = UDim2.new(1, -26, 0, 20),
            BackgroundTransparency = 1,
            Font = SETTINGS.Font,
            Text = title,
            TextColor3 = SETTINGS.Colors.Text,
            TextSize = SETTINGS.TextSize + 2,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 101,
            Parent = notification
        })
        
        -- Create message label
        local notificationMessage = Utils.Create("TextLabel", {
            Name = "Message",
            Position = UDim2.new(0, 16, 0, 35),
            Size = UDim2.new(1, -26, 0, 35),
            BackgroundTransparency = 1,
            Font = SETTINGS.Font,
            Text = message,
            TextColor3 = SETTINGS.Colors.TextDark,
            TextSize = SETTINGS.TextSize - 1,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 101,
            Parent = notification
        })
        
        -- Create close button
        local closeButton = Utils.Create("TextButton", {
            Name = "CloseButton",
            Position = UDim2.new(1, -20, 0, 10),
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1,
            Text = "×",
            TextColor3 = SETTINGS.Colors.TextDark,
            TextSize = 20,
            Font = SETTINGS.Font,
            ZIndex = 102,
            Parent = notification
        })
        
        -- Initial position (off-screen)
        notification.Position = UDim2.new(1, 20, 1, -20)
        
        -- Slide in animation
        Utils.Tween(notification, {Position = UDim2.new(1, -20, 1, -20)}, 0.5, Enum.EasingStyle.Quint)
        
        -- Auto close timer
        local autoCloseTime = 5
        local autoCloseConnection
        
        autoCloseConnection = RunService.Heartbeat:Connect(function()
            autoCloseTime = autoCloseTime - RunService.Heartbeat:Wait()
            
            if autoCloseTime <= 0 then
                autoCloseConnection:Disconnect()
                
                -- Slide out animation
                Utils.Tween(notification, {Position = UDim2.new(1, 320, 1, -20)}, 0.5, Enum.EasingStyle.Quint)
                wait(0.5)
                notification:Destroy()
            end
        end)
        
        -- Close button handler
        closeButton.MouseButton1Click:Connect(function()
            if autoCloseConnection then
                autoCloseConnection:Disconnect()
            end
            
            -- Slide out animation
            Utils.Tween(notification, {Position = UDim2.new(1, 320, 1, -20)}, 0.5, Enum.EasingStyle.Quint)
            wait(0.5)
            notification:Destroy()
        end)
        
        -- Mouse hover effects for close button
        Utils.ApplyHoverEffect(
            closeButton,
            function()
                Utils.Tween(closeButton, {TextColor3 = SETTINGS.Colors.Text}, 0.2)
            end,
            function()
                Utils.Tween(closeButton, {TextColor3 = SETTINGS.Colors.TextDark}, 0.2)
            end
        )
        
        return notification
    end
    
    return window
end

-- Return the library
return SkottiUI
