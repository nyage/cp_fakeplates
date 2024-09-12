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
            label = 'Wybierz pojazd w pobliżu',
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
        title = 'Wybierz pojazd',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        selectedVehicle = data.current.value
        menu.close()

        if selectedVehicle then
            if GetVehicleNumberOfPassengers(selectedVehicle) > 0 or not IsVehicleSeatFree(selectedVehicle, -1) then
                ESX.ShowNotification('Ktoś jest w pojeździe')
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
        ESX.ShowNotification('Poczekaj chwilę przed ponownym wykonaniem tej akcji')
        return
    end

    local vehicle = selectedVehicle
    if vehicle and DoesEntityExist(vehicle) then
        local originalPlate = GetVehicleNumberPlateText(vehicle)
        SetVehicleNumberPlateText(vehicle, ' ')
        TriggerEvent('esx:showNotification', 'Tablice rejestracyjne ukryte na 10 minut')

        Citizen.SetTimeout(Config.HideDuration / 2, function()
            TriggerEvent('esx:showNotification', 'Za 5 minut zasłona tablicy SPADNIE')
        end)

        Citizen.SetTimeout(Config.HideDuration - 60000, function()
            TriggerEvent('esx:showNotification', 'Za 1 minutę zasłona tablicy SPADNIE')
        end)

        Citizen.SetTimeout(Config.HideDuration, function()
            SetVehicleNumberPlateText(vehicle, originalPlate)
            TriggerEvent('esx:showNotification', 'Zasłona tablicy została zdjęta')
        end)

        cooldown = GetGameTimer() + Config.CooldownTime
    else
        TriggerEvent('esx:showNotification', 'Brak wybranego pojazdu')
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
            label = 'Zasłoń tablice',
            onSelect = function()
                hidePlate()
            end
        }
    }
})