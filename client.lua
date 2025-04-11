local RSGCore = exports['rsg-core']:GetCoreObject()
local gameActive = false
local targets = {}
local boxes = {}
local targetCoords = {}
local spawnPositions = {} 
local promptGroup = GetRandomIntInRange(0, 0xffffff)
local menuPrompt
local blip


local function ShowGameMenu()
   
    lib.registerContext({
        id = 'target_game_menu',
        title = 'Target Shooting Game',
        options = {
            {
                title = 'Start Game',
                description = 'Shoot bottles and targets to earn points!',
                icon = 'play',
                onSelect = function()
                    print('^3[DEBUG] Start Game selected, triggering server event^7')
                    TriggerServerEvent('rsg-targetpractice:startGame')
                end
            },
            {
                title = 'View Scoreboard',
                description = 'Check the top scores.',
                icon = 'list',
                onSelect = function()
                    TriggerServerEvent('rsg-targetpractice:getScoreboard')
                end
            },
            {
                title = 'Reset Scoreboard',
                description = 'Clear all scores.',
                icon = 'trash',
                onSelect = function()
                    TriggerServerEvent('rsg-targetpractice:resetScoreboard')
                end
            }
        }
    })
    lib.showContext('target_game_menu')
end


local function SetupMenuPrompt()
    menuPrompt = PromptRegisterBegin()
    PromptSetControlAction(menuPrompt, 0xF3830D8E) -- [j] key
    PromptSetText(menuPrompt, CreateVarString(10, 'LITERAL_STRING', 'Open Target Game'))
    PromptSetEnabled(menuPrompt, true)
    PromptSetVisible(menuPrompt, true)
    PromptSetStandardMode(menuPrompt, true)
    PromptSetGroup(menuPrompt, promptGroup)
    PromptRegisterEnd(menuPrompt)
end


local function CreateBlip()
    blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, Config.StartLocation.x, Config.StartLocation.y, Config.StartLocation.z) 
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, 'Target Practice') 
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_COLOR_YELLOW')) 
end



local function SpawnTarget(position)
    local targetProp = Config.TargetProps[math.random(1, #Config.TargetProps)]
    local target = CreateObject(GetHashKey(targetProp), position.x, position.y, position.z, true, true, false)
    
    if DoesEntityExist(target) then
        
        SetEntityAsMissionEntity(target, true, true)
        FreezeEntityPosition(target, true) 
        targetCoords[target] = position
        table.insert(targets, target)
        
       
        Citizen.CreateThread(function()
            while gameActive and DoesEntityExist(target) do
                if HasEntityBeenDamagedByAnyPed(target) then
                    
                    DeleteEntity(target)
                    targetCoords[target] = nil
                    for i = #targets, 1, -1 do
                        if targets[i] == target then
                            table.remove(targets, i)
                            break
                        end
                    end
                    TriggerServerEvent('rsg-targetpractice:addPoint')
                    lib.notify({ title = 'Hit!', description = 'You hit a target!', type = 'success' })
                    
                    
                    Citizen.SetTimeout(1500, function()
                        if gameActive then
                            SpawnTarget(position) 
                            
                        end
                    end)
                    break
                end
                Wait(0)
            end
        end)
        return target
    else
       
        return nil
    end
end

local function SpawnTargets()
   
    spawnPositions = {}
    
    for i = 1, Config.MaxTargets do
        local offset = Config.SpawnOffsets[i]
        if offset then
            local spawnX = Config.GameArea.x + offset.x
            local spawnY = Config.GameArea.y + offset.y
            local spawnZ = Config.GameArea.z

            

            local box = CreateObject(GetHashKey(Config.BoxProp), spawnX, spawnY, spawnZ, true, true, false)
            if DoesEntityExist(box) then
               
                PlaceObjectOnGroundProperly(box)
                SetEntityAsMissionEntity(box, true, true)
                SetEntityCollision(box, false, false) 
                table.insert(boxes, box)
                
                local boxCoords = GetEntityCoords(box)
                local position = {
                    x = boxCoords.x,
                    y = boxCoords.y,
                    z = boxCoords.z + 0.4
                }
                table.insert(spawnPositions, position)
                
                local target = SpawnTarget(position)
                if not target then
                   
                end
            else
               
            end
        end
    end
    
end



local function CheckHits()
    Citizen.CreateThread(function()
        while gameActive do
            local ped = PlayerPedId()
            if IsPedShooting(ped) then
                
                
                local weapon = GetCurrentPedWeapon(ped, true)
                local camPos = GetGameplayCamCoord()
                local camRot = GetGameplayCamRot(2)
                local camDir = {
                    x = -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
                    y = math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
                    z = math.sin(math.rad(camRot.x))
                }
                local endPos = vector3(camPos.x + camDir.x * 50.0, camPos.y + camDir.y * 50.0, camPos.z + camDir.z * 50.0)
                local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPos.x, endPos.y, endPos.z, -1, ped, 0)
                local _, hit, hitPos, _, entityHit = GetShapeTestResult(rayHandle)
                
                
                
                if hit == 1 then
                    
                    if DoesEntityExist(entityHit) then
                        local modelHash = GetEntityModel(entityHit)
                        local hitCoords = GetEntityCoords(entityHit)
                       
                    else
                       
                    end
                else
                   
                end

                if hit == 1 and entityHit ~= 0 and targetCoords[entityHit] then
                   
                    
                    local position = targetCoords[entityHit]
                    targetCoords[entityHit] = nil
                    for i = #targets, 1, -1 do
                        if targets[i] == entityHit then
                            table.remove(targets, i)
                           
                            break
                        end
                    end
                    
                    if DoesEntityExist(entityHit) then
                        DeleteEntity(entityHit)
                      
                    end
                    
                    TriggerServerEvent('rsg-targetpractice:addPoint')
                    lib.notify({ title = 'Hit!', description = 'You hit a target!', type = 'success' })
                    
                    Citizen.SetTimeout(1500, function()
                        if gameActive then
                            local newTarget = SpawnTarget(position)
                            if newTarget then
                               
                            else
                                
                            end
                        else
                            
                        end
                    end)
                elseif hit == 1 and entityHit ~= 0 then
                    
                end
            end
            Wait(0)
        end
        
    end)
end

local function CleanupTargets()
    for _, target in ipairs(targets) do
        if DoesEntityExist(target) then 
            DeleteEntity(target) 
           
        end
    end
    for _, box in ipairs(boxes) do
        if DoesEntityExist(box) then 
            DeleteEntity(box) 
            
        end
    end
    
    targets = {}
    boxes = {}
    targetCoords = {}
    spawnPositions = {}
    
end

RegisterNetEvent('rsg-targetpractice:startGameClient')
AddEventHandler('rsg-targetpractice:startGameClient', function()
    
    gameActive = true
    SpawnTargets()
    lib.notify({ title = 'Game Started', description = 'Shoot the targets within ' .. Config.GameDuration .. ' seconds!', type = 'inform' })

    Citizen.CreateThread(function()
        local timer = Config.GameDuration
        PromptSetEnabled(menuPrompt, false)
        PromptSetVisible(menuPrompt, false)
        while gameActive and timer > 0 do
            Wait(1000)
            timer = timer - 1
        end
        gameActive = false
        CleanupTargets()
        PromptSetEnabled(menuPrompt, true)
        PromptSetVisible(menuPrompt, true)
        TriggerServerEvent('rsg-targetpractice:endGame')
        lib.notify({ title = 'Game Over', description = 'Times up!', type = 'error' })
    end)
end)


RegisterNetEvent('rsg-targetpractice:showScoreboard')
AddEventHandler('rsg-targetpractice:showScoreboard', function(scoreboard)
    local options = {}
    for i, entry in ipairs(scoreboard) do
        table.insert(options, {
            title = entry.name,
            description = 'Bottles Shot: ' .. entry.score .. ' | Date: ' .. entry.game_time,
            icon = 'bottle-water'
        })
    end
    
   
    table.insert(options, 1, {
        title = 'Top Scores',
        description = 'Player scores sorted by bottles shot',
        disabled = true,
        icon = 'trophy'
    })
    
    lib.registerContext({
        id = 'scoreboard_menu',
        title = 'Target Practice Scoreboard',
        options = options
    })
    lib.showContext('scoreboard_menu')
end)


Citizen.CreateThread(function()
    
    SetupMenuPrompt()
    CreateBlip()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - Config.StartLocation)

        if dist < 5.0 and not gameActive then
            local promptLabel = CreateVarString(10, 'LITERAL_STRING', 'Target Practice')
            PromptSetActiveGroupThisFrame(promptGroup, promptLabel)
            if PromptHasStandardModeCompleted(menuPrompt) then
                ShowGameMenu()
            end
        end
        Wait(0)
    end
end)