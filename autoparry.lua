local ws = nil
local isConnected = false

local function connectWebSocket()
    local success, err = pcall(function()
        ws = WebSocket.connect("ws://localhost:8766")
    end)
    if not success then
        task.wait(3)
        connectWebSocket()
        return
    end
    if ws then
        isConnected = true
    end
end

connectWebSocket()

local function pressF()
    if isConnected and ws then
        local data = game:GetService("HttpService"):JSONEncode({
            action = "press_f"
        })
        ws:Send(data)
        return true
    end
    return false
end

getgenv().Fsploit = {
    AutoParry = true,
    PingBased = true,
    PingBasedOffset = 0.05,
    PingSmoothing = 0.3,
    DistanceToParry = 0.5,
    BallSpeedCheck = true,
    ParryTime = 0.5,
    PredictionTime = 0.1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local local_player = Players.LocalPlayer
local lastParryTime = 0
local hasParried = false

local smoothedPing = 0
local pingHistory = {}
local maxHistory = 5

local function getSmoothedPing()
    local currentPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    
    table.insert(pingHistory, currentPing)
    if #pingHistory > maxHistory then
        table.remove(pingHistory, 1)
    end
    
    local sum = 0
    for _, value in pairs(pingHistory) do
        sum = sum + value
    end
    local averagePing = sum / #pingHistory
    
    smoothedPing = smoothedPing * (1 - getgenv().Fsploit.PingSmoothing) + averagePing * getgenv().Fsploit.PingSmoothing
    
    return smoothedPing
end

local function isTargeted()
    return local_player.Character and local_player.Character:FindFirstChild("Highlight") ~= nil
end

local function findRealBall()
    local balls = workspace:FindFirstChild("Balls")
    if not balls then return nil end
    
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") == true then
            return ball
        end
    end
    return nil
end

RunService.PreRender:Connect(function()
    if not getgenv().Fsploit.AutoParry then return end
    
    local ball = findRealBall()
    if not ball then
        hasParried = false
        return
    end
    
    local character = local_player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not isTargeted() then return end
    
    local ballVelocity = ball.AssemblyLinearVelocity.Magnitude
    if getgenv().Fsploit.BallSpeedCheck and ballVelocity == 0 then return end
    
    local distance = (rootPart.Position - ball.Position).Magnitude
    local ping = getSmoothedPing()
    
    local totalDelay = ping + 0.016 + getgenv().Fsploit.PingBasedOffset
    local timeToImpact = (distance - (ballVelocity * totalDelay)) / ballVelocity
    
    if timeToImpact <= 0 then
        hasParried = false
        return
    end
    
    local currentTime = tick()
    
    if timeToImpact <= getgenv().Fsploit.ParryTime and not hasParried then
        if currentTime - lastParryTime > 0.05 then
            pressF()
            lastParryTime = currentTime
            hasParried = true
        end
    end
    
    if timeToImpact > getgenv().Fsploit.ParryTime then
        hasParried = false
    end
end)