local RSGCore = exports['rsg-core']:GetCoreObject()
local scores = {}


local function initializeTargetGameDatabase()
    if not MySQL then
       
        return
    end
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS targetgame_scores (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            name VARCHAR(255) NOT NULL,
            score INT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end

if MySQL then
    MySQL.ready(function()
        initializeTargetGameDatabase()
    end)
else
    
end


RegisterNetEvent('rsg-targetpractice:startGame')
AddEventHandler('rsg-targetpractice:startGame', function()
    local src = source
    print('^3[DEBUG] Server received startGame event from source: ' .. src .. '^7')
    scores[src] = 0
    TriggerClientEvent('rsg-targetpractice:startGameClient', src)
    print('^3[DEBUG] Server triggered startGameClient event for source: ' .. src .. '^7')
end)

RegisterNetEvent('rsg-targetpractice:resetScoreboard')
AddEventHandler('rsg-targetpractice:resetScoreboard', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if MySQL then
        MySQL.Async.execute('DELETE FROM targetgame_scores', {}, function()
            TriggerClientEvent('lib.notify', src, { 
                title = 'Success', 
                description = 'Scoreboard has been reset!', 
                type = 'success' 
            })
            
        end)
    else
        TriggerClientEvent('lib.notify', src, { 
            title = 'Error', 
            description = 'Database not available!', 
            type = 'error' 
        })
    end
end)

RegisterNetEvent('rsg-targetpractice:addPoint')
AddEventHandler('rsg-targetpractice:addPoint', function()
    local src = source
    scores[src] = (scores[src] or 0) + 1
end)


RegisterNetEvent('rsg-targetpractice:endGame')
AddEventHandler('rsg-targetpractice:endGame', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local score = scores[src] or 0

    if MySQL then
        MySQL.Async.execute('INSERT INTO targetgame_scores (identifier, name, score) VALUES (@identifier, @name, @score)', {
            ['@identifier'] = identifier,
            ['@name'] = name,
            ['@score'] = score
        })
    else
        
    end
    scores[src] = nil
end)


RegisterNetEvent('rsg-targetpractice:getScoreboard')
AddEventHandler('rsg-targetpractice:getScoreboard', function()
    local src = source
    if not MySQL then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1Error', 'Scoreboard unavailable: Database error.' } })
        return
    end
    MySQL.Async.fetchAll('SELECT name, score, DATE_FORMAT(timestamp, "%Y-%m-%d %H:%i") as game_time FROM targetgame_scores ORDER BY score DESC LIMIT 10', {}, function(result)
        TriggerClientEvent('rsg-targetpractice:showScoreboard', src, result)
    end)
end)