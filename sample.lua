--[[
    Example Script
    Created for Script Authentication System
]]

-- Script Information
local ScriptInfo = {
    Key = "%KEY%", -- Will be replaced with the actual key
    Name = "Sample Script",
    Version = "1.0.0",
    Author = "Script Server"
}

-- Utilities
local function log(level, ...)
    local prefix = "[" .. ScriptInfo.Name .. "]" 
    
    if level == "INFO" then
        print(prefix, ...)
    elseif level == "WARN" then
        warn(prefix, ...)
    elseif level == "ERROR" then
        error(prefix .. " " .. table.concat({...}, " "))
    end
end

-- Key Validation
local function validateKey()
    if not ScriptInfo.Key or ScriptInfo.Key == "" then
        log("WARN", "No key provided")
        return false
    end
    
    -- For testing, always return true
    -- In a real implementation, you would verify with your server
    return true
end

-- Main Execution
log("INFO", "==================================================")
log("INFO", ScriptInfo.Name .. " (v" .. ScriptInfo.Version .. ")")
log("INFO", "Created by: " .. ScriptInfo.Author)
log("INFO", "==================================================")

if validateKey() then
    log("INFO", "Key validated successfully!")
    
    -- Your actual script code would go here
    log("INFO", "Hello world! This is a sample script.")
    
    -- Sample function 
    local function createPart()
        log("INFO", "Creating a part...")
        
        -- This is just a demonstration and would be replaced with actual code
        log("INFO", "Part created successfully!")
    end
    
    -- Execute the function
    createPart()
else
    log("WARN", "Script terminated due to authentication failure")
end
