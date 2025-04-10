--[[
    Custom Roblox Notification System for Synapse X
    Author: Your Name
    Version: 1.0
]]

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

-- Configuration
local config = {
    defaultDuration = 5,
    maxNotifications = 5,
    spacing = 10,
    animationSpeed = 0.3,
    defaultWidth = 300,
    defaultHeight = 80,
    cornerRadius = UDim.new(0, 8),
    font = Enum.Font.SourceSansBold,
    textSize = 14,
    defaultPosition = UDim2.new(1, -20, 0, 20), -- Top right
    defaultAnchorPoint = Vector2.new(1, 0),
    defaultSound = "rbxassetid://6518811702",
    themes = {
        default = {
            backgroundColor = Color3.fromRGB(45, 45, 45),
            textColor = Color3.fromRGB(255, 255, 255),
            borderColor = Color3.fromRGB(60, 60, 60),
            iconColor = Color3.fromRGB(255, 255, 255),
            progressBarColor = Color3.fromRGB(80, 80, 80),
            progressBarFillColor = Color3.fromRGB(100, 100, 100)
        },
        success = {
            backgroundColor = Color3.fromRGB(40, 100, 60),
            textColor = Color3.fromRGB(255, 255, 255),
            borderColor = Color3.fromRGB(50, 120, 70),
            iconColor = Color3.fromRGB(200, 255, 200),
            progressBarColor = Color3.fromRGB(30, 80, 50),
            progressBarFillColor = Color3.fromRGB(60, 160, 90)
        },
        error = {
            backgroundColor = Color3.fromRGB(150, 40, 40),
            textColor = Color3.fromRGB(255, 255, 255),
            borderColor = Color3.fromRGB(180, 50, 50),
            iconColor = Color3.fromRGB(255, 200, 200),
            progressBarColor = Color3.fromRGB(120, 30, 30),
            progressBarFillColor = Color3.fromRGB(200, 60, 60)
        },
        warning = {
            backgroundColor = Color3.fromRGB(150, 120, 30),
            textColor = Color3.fromRGB(255, 255, 255),
            borderColor = Color3.fromRGB(180, 140, 40),
            iconColor = Color3.fromRGB(255, 240, 180),
            progressBarColor = Color3.fromRGB(120, 100, 20),
            progressBarFillColor = Color3.fromRGB(200, 160, 40)
        },
        info = {
            backgroundColor = Color3.fromRGB(40, 80, 150),
            textColor = Color3.fromRGB(255, 255, 255),
            borderColor = Color3.fromRGB(50, 100, 180),
            iconColor = Color3.fromRGB(200, 220, 255),
            progressBarColor = Color3.fromRGB(30, 60, 120),
            progressBarFillColor = Color3.fromRGB(60, 120, 200)
        },
        custom = {
            backgroundColor = Color3.fromRGB(80, 40, 120),
            textColor = Color3.fromRGB(255, 255, 255),
            borderColor = Color3.fromRGB(100, 50, 150),
            iconColor = Color3.fromRGB(220, 200, 255),
            progressBarColor = Color3.fromRGB(60, 30, 90),
            progressBarFillColor = Color3.fromRGB(120, 60, 180)
        }
    },
    icons = {
        default = "rbxassetid://7072718185", -- Bell icon
        success = "rbxassetid://7072707588", -- Checkmark icon
        error = "rbxassetid://7072725342", -- X icon
        warning = "rbxassetid://7072724538", -- Warning icon
        info = "rbxassetid://7072717857", -- Info icon
        custom = "rbxassetid://7072706796" -- Star icon
    }
}

-- Variables
local activeNotifications = {}
local screenGui = nil

-- Initialize the notification system
function NotificationSystem.Init()
    -- Create ScreenGui if it doesn't exist
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SynapseNotificationSystem"
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.ResetOnSpawn = false
        screenGui.Parent = game:GetService("CoreGui")
        
        -- Create a container for notifications
        local container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Position = UDim2.new(0, 0, 0, 0)
        container.Parent = screenGui
    end
    
    return NotificationSystem
end

-- Update notification positions
function NotificationSystem.UpdatePositions()
    local yOffset = 0
    
    for i, notification in ipairs(activeNotifications) do
        local targetPosition = UDim2.new(
            config.defaultPosition.X.Scale,
            config.defaultPosition.X.Offset,
            config.defaultPosition.Y.Scale,
            config.defaultPosition.Y.Offset + yOffset
        )
        
        -- Animate to new position
        notification.frame:TweenPosition(
            targetPosition,
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quart,
            config.animationSpeed,
            true
        )
        
        yOffset = yOffset + notification.frame.AbsoluteSize.Y + config.spacing
    end
end

-- Create a new notification
function NotificationSystem.Create(options)
    options = options or {}
    
    -- Default options
    local title = options.title or "Notification"
    local message = options.message or ""
    local duration = options.duration or config.defaultDuration
    local theme = options.theme or "default"
    local icon = options.icon or config.icons[theme] or config.icons.default
    local sound = options.sound or config.defaultSound
    local callback = options.callback
    local width = options.width or config.defaultWidth
    local height = options.height or config.defaultHeight
    
    -- Get theme colors
    local themeColors = config.themes[theme] or config.themes.default
    
    -- Create notification frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification_" .. tostring(#activeNotifications + 1)
    notificationFrame.Size = UDim2.new(0, width, 0, height)
    notificationFrame.Position = UDim2.new(
        config.defaultPosition.X.Scale + 0.2,
        config.defaultPosition.X.Offset,
        config.defaultPosition.Y.Scale,
        config.defaultPosition.Y.Offset
    )
    notificationFrame.AnchorPoint = config.defaultAnchorPoint
    notificationFrame.BackgroundColor3 = themeColors.backgroundColor
    notificationFrame.BorderSizePixel = 0
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.Parent = screenGui.NotificationContainer
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = config.cornerRadius
    corner.Parent = notificationFrame
    
    -- Add border
    local border = Instance.new("UIStroke")
    border.Color = themeColors.borderColor
    border.Thickness = 1
    border.Parent = notificationFrame
    
    -- Add icon
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "Icon"
    iconImage.Size = UDim2.new(0, height - 30, 0, height - 30)
    iconImage.Position = UDim2.new(0, 15, 0.5, 0)
    iconImage.AnchorPoint = Vector2.new(0, 0.5)
    iconImage.BackgroundTransparency = 1
    iconImage.Image = icon
    iconImage.ImageColor3 = themeColors.iconColor
    iconImage.Parent = notificationFrame
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0, 25)
    titleLabel.Position = UDim2.new(0, 65, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = themeColors.textColor
    titleLabel.TextSize = config.textSize + 2
    titleLabel.Font = config.font
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextWrapped = true
    titleLabel.Parent = notificationFrame
    
    -- Add message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -80, 1, -45)
    messageLabel.Position = UDim2.new(0, 65, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = themeColors.textColor
    messageLabel.TextSize = config.textSize
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = notificationFrame
    
    -- Add progress bar
    local progressBarBackground = Instance.new("Frame")
    progressBarBackground.Name = "ProgressBarBackground"
    progressBarBackground.Size = UDim2.new(1, 0, 0, 4)
    progressBarBackground.Position = UDim2.new(0, 0, 1, -4)
    progressBarBackground.BackgroundColor3 = themeColors.progressBarColor
    progressBarBackground.BorderSizePixel = 0
    progressBarBackground.Parent = notificationFrame
    
    local progressBarFill = Instance.new("Frame")
    progressBarFill.Name = "ProgressBarFill"
    progressBarFill.Size = UDim2.new(1, 0, 1, 0)
    progressBarFill.BackgroundColor3 = themeColors.progressBarFillColor
    progressBarFill.BorderSizePixel = 0
    progressBarFill.Parent = progressBarBackground
    
    -- Add corner radius to progress bar
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 2)
    progressCorner.Parent = progressBarBackground
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 2)
    progressFillCorner.Parent = progressBarFill
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -15, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "×"
    closeButton.TextColor3 = themeColors.textColor
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = notificationFrame
    
    -- Play sound
    if sound then
        local soundInstance = Instance.new("Sound")
        soundInstance.SoundId = sound
        soundInstance.Volume = 0.5
        soundInstance.Parent = notificationFrame
        soundInstance:Play()
        
        game:GetService("Debris"):AddItem(soundInstance, 2)
    end
    
    -- Create notification object
    local notification = {
        frame = notificationFrame,
        progressBar = progressBarFill,
        duration = duration,
        callback = callback,
        startTime = tick(),
        closing = false
    }
    
    -- Add to active notifications
    table.insert(activeNotifications, notification)
    
    -- Update positions
    NotificationSystem.UpdatePositions()
    
    -- Animate in
    notificationFrame.Position = UDim2.new(
        config.defaultPosition.X.Scale + 0.2,
        config.defaultPosition.X.Offset,
        config.defaultPosition.Y.Scale,
        config.defaultPosition.Y.Offset
    )
    
    notificationFrame:TweenPosition(
        UDim2.new(
            config.defaultPosition.X.Scale,
            config.defaultPosition.X.Offset,
            config.defaultPosition.Y.Scale,
            config.defaultPosition.Y.Offset
        ),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        config.animationSpeed,
        true
    )
    
    -- Handle close button
    closeButton.MouseButton1Click:Connect(function()
        NotificationSystem.Close(notification)
    end)
    
    -- Make notification clickable
    notificationFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and notification.callback then
            notification.callback()
            NotificationSystem.Close(notification)
        end
    end)
    
    -- Start progress bar animation
    spawn(function()
        local startTime = tick()
        
        while tick() - startTime < duration and not notification.closing do
            local elapsed = tick() - startTime
            local progress = 1 - (elapsed / duration)
            
            progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
            
            wait(0.03)
        end
        
        if not notification.closing then
            NotificationSystem.Close(notification)
        end
    end)
    
    -- Limit max notifications
    if #activeNotifications > config.maxNotifications then
        NotificationSystem.Close(activeNotifications[1])
    end
    
    return notification
end

-- Close a notification
function NotificationSystem.Close(notification)
    if notification.closing then return end
    
    notification.closing = true
    
    -- Find index
    local index = table.find(activeNotifications, notification)
    if not index then return end
    
    -- Remove from active notifications
    table.remove(activeNotifications, index)
    
    -- Animate out
    notification.frame:TweenPosition(
        UDim2.new(
            config.defaultPosition.X.Scale + 0.2,
            config.defaultPosition.X.Offset,
            notification.frame.Position.Y.Scale,
            notification.frame.Position.Y.Offset
        ),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        config.animationSpeed,
        true,
        function()
            notification.frame:Destroy()
            NotificationSystem.UpdatePositions()
        end
    )
end

-- Show a success notification
function NotificationSystem.Success(title, message, duration, callback)
    return NotificationSystem.Create({
        title = title,
        message = message,
        duration = duration,
        theme = "success",
        callback = callback
    })
end

-- Show an error notification
function NotificationSystem.Error(title, message, duration, callback)
    return NotificationSystem.Create({
        title = title,
        message = message,
        duration = duration,
        theme = "error",
        callback = callback
    })
end

-- Show a warning notification
function NotificationSystem.Warning(title, message, duration, callback)
    return NotificationSystem.Create({
        title = title,
        message = message,
        duration = duration,
        theme = "warning",
        callback = callback
    })
end

-- Show an info notification
function NotificationSystem.Info(title, message, duration, callback)
    return NotificationSystem.Create({
        title = title,
        message = message,
        duration = duration,
        theme = "info",
        callback = callback
    })
end

-- Show a custom notification
function NotificationSystem.Custom(options)
    return NotificationSystem.Create(options)
end

-- Clear all notifications
function NotificationSystem.ClearAll()
    for i = #activeNotifications, 1, -1 do
        NotificationSystem.Close(activeNotifications[i])
    end
end

-- Update configuration
function NotificationSystem.UpdateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if type(value) == "table" then
            for subKey, subValue in pairs(value) do
                config[key][subKey] = subValue
            end
        else
            config[key] = value
        end
    end
end

-- Add a new theme
function NotificationSystem.AddTheme(themeName, themeColors)
    config.themes[themeName] = themeColors
end

-- Add a new icon
function NotificationSystem.AddIcon(iconName, iconId)
    config.icons[iconName] = iconId
end

-- Get current configuration
function NotificationSystem.GetConfig()
    return config
end

-- Initialize and return the module
return NotificationSystem.Init()