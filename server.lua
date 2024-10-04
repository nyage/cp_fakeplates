ESX = exports['es_extended']:getSharedObject()

local npcCoords = { x = 767.364, y = -1642.796, z = 30.123, heading = 90.0 }

-- Hides the plate server-side
ESX.RegisterServerCallback('cp_fakeplates:hidePlate', function(source, cb, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    local money = exports.ox_inventory:GetItem(source, 'money')

    if money and money.count >= price then
        exports.ox_inventory:RemoveItem(source, 'money', price)
        cb(true)
    else
        cb(false)
    end
end)

-- Provides NPC coordinates to client
ESX.RegisterServerCallback('cp_fakeplates:getNpcCoords', function(source, cb)
    cb(npcCoords)
end)