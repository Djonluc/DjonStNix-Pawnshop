local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}
local spawnedBlips = {}

-- ==============================================================================
-- 🧍 PED SPAWNING & TARGET INTEGRATION
-- ==============================================================================
CreateThread(function()
    for shopId, data in pairs(Config.Locations) do
        -- Request model
        lib.requestModel(data.pedModel)
        
        -- Spawn Ped
        local ped = CreatePed(0, GetHashKey(data.pedModel), data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if data.scenario then
            TaskStartScenarioInPlace(ped, data.scenario, 0, true)
        end
        
        spawnedPeds[shopId] = ped

        -- Target Integration
        if Config.Settings.Target == "ox" or GetResourceState("ox_target") == "started" then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'pawnshop_' .. shopId,
                    icon = data.targetIcon,
                    label = data.targetLabel,
                    distance = data.targetDistance,
                    onSelect = function()
                        OpenPawnShopUI()
                    end
                }
            })
        else
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        type = "client",
                        icon = data.targetIcon,
                        label = data.targetLabel,
                        action = function()
                            OpenPawnShopUI()
                        end,
                    }
                },
                distance = data.targetDistance
            })
        end

        -- Blip Creation
        if data.blip and data.blip.enabled then
            local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
            SetBlipSprite(blip, data.blip.id)
            SetBlipColour(blip, data.blip.color)
            SetBlipScale(blip, data.blip.scale)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(data.blip.title)
            EndTextCommandSetBlipName(blip)
            spawnedBlips[shopId] = blip
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    for _, blip in pairs(spawnedBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)

-- ==============================================================================
-- 🛒 UI & LOGIC
-- ==============================================================================
function OpenPawnShopUI()
    -- Fetch ONLY active wanted items from server, with current depleted prices applied.
    lib.callback('djonstnix_pawnshop:server:getSellableItems', false, function(sellableItems, rotationInterval)
        local options = {}
        
        local totalSellablePieces = 0
        local totalEstimatedMin = 0
        local totalEstimatedMax = 0

        for name, data in pairs(sellableItems) do
            if data.count > 0 then
                
                totalSellablePieces = totalSellablePieces + data.count
                if type(data.priceConf) == "table" then
                     totalEstimatedMin = totalEstimatedMin + (data.priceConf.min * data.count)
                     totalEstimatedMax = totalEstimatedMax + (data.priceConf.max * data.count)
                else
                     totalEstimatedMin = totalEstimatedMin + (data.priceConf * data.count)
                     totalEstimatedMax = totalEstimatedMax + (data.priceConf * data.count)
                end
                
                -- Construct price string using pre-calculated depleted min/max
                local priceStr = ""
                if type(data.priceConf) == "table" then
                    priceStr = string.format("~ $%s - $%s", data.priceConf.min, data.priceConf.max)
                else
                    priceStr = string.format("$%s", data.priceConf)
                end
                
                -- Determine color/icon based on market condition
                local marketStateIcon = "box"
                if data.mult < 0.5 then
                    marketStateIcon = "arrow-down" -- Heavily Depleted
                elseif data.mult == 1.0 then
                    marketStateIcon = "star" -- Full value
                end

                table.insert(options, {
                    title = data.label or name,
                    description = string.format("Inventory: %s | Demand Value: %s/ea", data.count, priceStr),
                    icon = marketStateIcon,
                    onSelect = function()
                        PromptSellAmount(name, data.label, data.count)
                    end
                })
            end
        end

        if #options == 0 then
            lib.notify({ title = 'Pawn Broker', description = 'I am not looking to buy anything you currently have right now. Come back later.', type = 'error' })
            return
        end

        -- Add 'Sell All' option at the top if there is more than 1 item piece total
        if totalSellablePieces > 1 then
            local totalStr = ""
            if totalEstimatedMin ~= totalEstimatedMax then
                totalStr = string.format("~ $%s - $%s", totalEstimatedMin, totalEstimatedMax)
            else
                totalStr = string.format("$%s", totalEstimatedMin)
            end
            
            local bulkTitle = Config.Economy.RotationEnabled and "Sell ALL Wanted Goods" or "Bulk Sell Items"
            local bulkDesc = Config.Economy.RotationEnabled and string.format("Sell all %s wanted items at once.\nEst. Value: %s", totalSellablePieces, totalStr) or string.format("Sell all %s items at once.\nEst. Value: %s", totalSellablePieces, totalStr)

            table.insert(options, 1, {
                title = bulkTitle,
                description = bulkDesc,
                icon = "circle-dollar-to-slot",
                onSelect = function()
                    TriggerServerEvent('djonstnix_pawnshop:server:sellAllItems')
                end
            })
        end

        local menuTitle = Config.Economy.RotationEnabled and 'Pawn Broker (Wanted Goods)' or 'Pawn Broker (Sell Items)'
        lib.registerContext({
            id = 'djonstnix_pawnshop_menu',
            title = menuTitle,
            options = options
        })

        lib.showContext('djonstnix_pawnshop_menu')
    end)
end

function PromptSellAmount(itemName, itemLabel, maxAmount)
    local input = lib.inputDialog('Sell ' .. (itemLabel or itemName), {
        {
            type = 'number',
            label = 'Amount to sell',
            description = 'Max you have: ' .. maxAmount,
            icon = 'hashtag',
            default = maxAmount,
            min = 1,
            max = maxAmount,
            required = true
        }
    })

    if not input or not input[1] then return end

    local amount = tonumber(input[1])
    if amount and amount > 0 and amount <= maxAmount then
        TriggerServerEvent('djonstnix_pawnshop:server:sellItem', itemName, amount)
    else
        lib.notify({ title = 'Error', description = 'Invalid amount entered.', type = 'error' })
    end
end
