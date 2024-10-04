ESX = exports['es_extended']:getSharedObject()

local ox_target = exports['ox_target']
local cooldown = 0
local npcCoords = nil
local npc = nil
local selectedVehicle = nil

-- Spawning NPC function
function spawnNpc(coords)
    local model = GetHashKey(Config.NpcModel)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    npc = CreatePed(4, model, coords.x, coords.y, coords.z, coords.heading, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedDiesWhenInjured(npc, false)
    SetPedCanPlayAmbientAnims(npc, true)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetEntityInvincible(npc, true)

    npcCoords = coords

    ox_target:addLocalEntity(npc, {
        {
            name = 'chooseVehicle',
            icon = 'fa-solid fa-car',
            label = 'Select a vehicle nearby',
            onSelect = function()
                openVehicleMenu()
            end,
            canInteract = function(entity, distance, data)
                return true
            end,
        }
    })
end

-- Trigger NPC spawn on script start
CreateThread(function()
    ESX.TriggerServerCallback('cp_fakeplates:getNpcCoords', function(coords)
        if coords then
            spawnNpc(coords)
        end
    end)
end)

-- Open vehicle selection menu
function openVehicleMenu()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local vehicles = ESX.Game.GetVehiclesInArea(playerPos, 10.0)
    local elements = {}

    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(playerPos - vehicleCoords)
        local plate = GetVehicleNumberPlateText(vehicle)

        table.insert(elements, {
            label = ('%s [%s] - %.2fm'):format(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), plate, distance),
            value = vehicle
        })
    end

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_menu', {
        title = 'Select a vehicle',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        selectedVehicle = data.current.value
        menu.close()

        if selectedVehicle then
            if GetVehicleNumberOfPassengers(selectedVehicle) > 0 or not IsVehicleSeatFree(selectedVehicle, -1) then
                ESX.ShowNotification('There is someone in the vehicle')
            else
                npcApproachVehicle(selectedVehicle)
            end
        end
    end, function(data, menu)
        menu.close()
    end)
end

-- NPC approaches the selected vehicle
function npcApproachVehicle(vehicle)
    TaskGoToEntity(npc, vehicle, -1, 1.0, 2.0, 1073741824, 0)
    while GetScriptTaskStatus(npc, 0x4924437D) ~= 7 do
        Wait(100)
    end

    TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    Wait(5000)

    ClearPedTasksImmediately(npc)
    TaskGoToCoordAnyMeans(npc, npcCoords.x, npcCoords.y, npcCoords.z, 1.0, 0, 0, 786603, 0xbf800000)

    while GetScriptTaskStatus(npc, 0x4924437D) ~= 7 do
        Wait(100)
    end

    SetEntityCoords(npc, npcCoords.x, npcCoords.y, npcCoords.z, false, false, false, true)
    SetEntityHeading(npc, npcCoords.heading)

    hidePlate()
end

-- Hides vehicle plate and sets cooldown
function hidePlate()
    if cooldown > GetGameTimer() then
        ESX.ShowNotification('Wait a moment before performing this action again')
        return
    end

    local vehicle = selectedVehicle
    if vehicle and DoesEntityExist(vehicle) then
        local originalPlate = GetVehicleNumberPlateText(vehicle)
        SetVehicleNumberPlateText(vehicle, ' ')
        TriggerEvent('esx:showNotification', 'License plates hidden for 10 minutes')

        Citizen.SetTimeout(Config.HideDuration / 2, function()
            TriggerEvent('esx:showNotification', 'In 5 minute the numberplate cover will FALL OFF')
        end)

        Citizen.SetTimeout(Config.HideDuration - 60000, function()
            TriggerEvent('esx:showNotification', 'In 1 minute the number plate cover will FALL OFF')
        end)

        Citizen.SetTimeout(Config.HideDuration, function()
            SetVehicleNumberPlateText(vehicle, originalPlate)
            TriggerEvent('esx:showNotification', 'The number plate cover has been removed')
        end)

        cooldown = GetGameTimer() + Config.CooldownTime
    else
        TriggerEvent('esx:showNotification', 'No vehicle selected')
    end
end

-- ox_target setup for vehicles
ox_target:addSphereZone({
    coords = vec3(Config.NpcCoords.x, Config.NpcCoords.y, Config.NpcCoords.z),
    radius = 1.5,
    options = {
        {
            name = 'hidePlate',
            icon = 'fa-solid fa-car',
            label = '',
            onSelect = function()
                hidePlate()
            end
        }
    }
})