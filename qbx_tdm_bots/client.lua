local spawnedEnemies = {}

RegisterCommand('enimyadd', function(source, args, rawCommand)
    local amount = tonumber(args[1])
    
    if not amount or amount <= 0 then
        lib.notify({
            title = 'Error',
            description = 'Please specify a valid amount of enemies to spawn.',
            type = 'error'
        })
        return
    end
    
    -- Cap the amount at 100
    if amount > 100 then
        amount = 100
        lib.notify({
            title = 'Warning',
            description = 'Amount capped at 100 to prevent server/client lag.',
            type = 'warning'
        })
    end
    
    SpawnEnemies(amount)
    
    lib.notify({
        title = 'Success',
        description = 'Spawned ' .. amount .. ' fully armored enemies.',
        type = 'success'
    })
end, false)

function SpawnEnemies(amount)
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    
    -- Load SWAT ped model (you can change this to any ped model)
    local model = `s_m_y_swat_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    -- Create a relationship group so enemies don't shoot each other
    local enemyGroup = `TDM_ENEMIES`
    AddRelationshipGroup('TDM_ENEMIES')
    SetRelationshipBetweenGroups(5, enemyGroup, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, enemyGroup)
    SetRelationshipBetweenGroups(0, enemyGroup, enemyGroup)
    
    for i = 1, amount do
        -- Randomize spawn position around the player
        local offsetX = math.random(-40, 40)
        local offsetY = math.random(-40, 40)
        
        -- Prevent them from spawning directly on top of the player
        if offsetX > -10 and offsetX < 10 then offsetX = 15 end
        if offsetY > -10 and offsetY < 10 then offsetY = 15 end
        
        local spawnPos = vector3(playerPos.x + offsetX, playerPos.y + offsetY, playerPos.z)
        
        -- Try to place them on the ground properly
        local hasGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
        if hasGround then
            spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ + 1.0)
        end
        
        local ped = CreatePed(4, model, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
        
        if DoesEntityExist(ped) then
            -- Equip 100% Armor
            SetPedArmour(ped, 100)
            
            -- Give Carbine Rifle
            GiveWeaponToPed(ped, `WEAPON_CARBINERIFLE`, 255, false, true)
            
            -- Combat Attributes
            SetPedRelationshipGroupHash(ped, enemyGroup)
            SetPedCombatAttributes(ped, 46, true) -- Always fight, don't flee
            SetPedCombatAttributes(ped, 5, true)  -- Can fight unarmed if weapon is lost
            SetPedCombatAbility(ped, 2)           -- Professional shooting ability
            SetPedAccuracy(ped, 60)               -- Adjust accuracy (0-100)
            SetPedFleeAttributes(ped, 0, false)   -- Will never flee
            SetPedAsEnemy(ped, true)
            
            -- Task the ped to attack the player
            TaskCombatPed(ped, playerPed, 0, 16)
            
            table.insert(spawnedEnemies, ped)
        end
    end
    
    -- Cleanup model memory
    SetModelAsNoLongerNeeded(model)
end

RegisterCommand('removeenimy', function(source, args, rawCommand)
    local count = 0
    for i, ped in ipairs(spawnedEnemies) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            count = count + 1
        end
    end
    
    -- Clear the table
    spawnedEnemies = {}
    
    lib.notify({
        title = 'Success',
        description = 'Removed ' .. count .. ' enemies.',
        type = 'success'
    })
end, false)

-- Safety cleanup when the script restarts/stops so bots don't become ghost entities
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i, ped in ipairs(spawnedEnemies) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
    end
end)
