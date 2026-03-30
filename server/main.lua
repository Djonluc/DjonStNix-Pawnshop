local QBCore = exports['qb-core']:GetCoreObject()

-- ==============================================================================
-- 📉 DYNAMIC ECONOMY STATE
-- ==============================================================================
local ItemMultipliers = {}
local ActiveWantedItems = {}

-- Initialize baseline economy
CreateThread(function()
    for itemName, conf in pairs(Config.Items) do
        ItemMultipliers[itemName] = 1.0
    end
    
    if Config.Economy.RotationEnabled then
        RotateWantedItems()
    else
        -- If rotation is disabled, they want everything always
        for itemName, _ in pairs(Config.Items) do
            ActiveWantedItems[itemName] = true
        end
    end
end)

-- Function to pick random items for the pawn broker to want
function RotateWantedItems()
    ActiveWantedItems = {}
    local itemKeys = {}
    
    -- Filter items based on buyChance first
    for k, v in pairs(Config.Items) do 
        local chance = v.buyChance or 100
        if math.random(1, 100) <= chance then
            table.insert(itemKeys, k) 
        end
    end
    
    -- Shuffle keys
    for i = #itemKeys, 2, -1 do
        local j = math.random(i)
        itemKeys[i], itemKeys[j] = itemKeys[j], itemKeys[i]
    end
    
    -- Pick top N
    local maxCount = math.min(Config.Economy.MaxWantedItems, #itemKeys)
    for i = 1, maxCount do
        ActiveWantedItems[itemKeys[i]] = true
    end
    
    if Config.Settings.Debug then
        print("[DjonStNix-Pawnshop] 🔄 Rotated Wanted Items:")
        for k, _ in pairs(ActiveWantedItems) do
            print("- " .. k)
        end
    end
end

-- Thread: Rotates Wanted Items every X minutes
CreateThread(function()
    while true do
        Wait(Config.Economy.RotationIntervalMin * 60000)
        if Config.Economy.RotationEnabled then
            RotateWantedItems()
        end
    end
end)

-- Thread: Slowly recovers depleted prices globally
CreateThread(function()
    while true do
        Wait(Config.Economy.RecoveryInterval * 60000)
        if Config.Economy.DepletionEnabled then
            local recoveredAny = false
            for itemName, mult in pairs(ItemMultipliers) do
                if mult < 1.0 then
                    ItemMultipliers[itemName] = math.min(1.0, mult + Config.Economy.RecoveryAmount)
                    recoveredAny = true
                end
            end
            if Config.Settings.Debug and recoveredAny then
                print("[DjonStNix-Pawnshop] 📈 Economy Recovery Cycle Completed.")
            end
        end
    end
end)


-- ==============================================================================
-- 📡 SECURE DATA TRANSMISSION
-- ==============================================================================
lib.callback.register('djonstnix_pawnshop:server:getSellableItems', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local sellableItems = {}
    local inventory = Player.PlayerData.items

    for _, itemData in pairs(inventory) do
        if itemData and itemData.name and Config.Items[itemData.name] then
            -- ONLY return items if they are currently "wanted" by the pawn shop
            if not Config.Economy.RotationEnabled or ActiveWantedItems[itemData.name] then
                local count = itemData.amount or itemData.count or 0
                if count > 0 then
                    if not sellableItems[itemData.name] then
                        
                        -- Calculate the current projected price factoring in global depletion
                        local basePriceData = Config.Items[itemData.name].price
                        local currentMult = ItemMultipliers[itemData.name] or 1.0
                        
                        local depletedConf = {}
                        if type(basePriceData) == "table" then
                            depletedConf.min = math.floor(basePriceData.min * currentMult)
                            depletedConf.max = math.floor(basePriceData.max * currentMult)
                        else
                            depletedConf = math.floor(basePriceData * currentMult)
                        end
                        
                        sellableItems[itemData.name] = {
                            name = itemData.name,
                            label = itemData.label or itemData.name,
                            count = count,
                            priceConf = depletedConf,
                            mult = currentMult
                        }
                    else
                        sellableItems[itemData.name].count = sellableItems[itemData.name].count + count
                    end
                end
            end
        end
    end

    return sellableItems, (Config.Economy.RotationIntervalMin) -- Send interval as extra data if needed
end)

-- ==============================================================================
-- 🛒 SECURE TRANSACTION PROCESSING & ALERTS
-- ==============================================================================
RegisterNetEvent('djonstnix_pawnshop:server:sellItem', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Invalid amount.', type = 'error' })
        return
    end

    local itemConf = Config.Items[itemName]
    if not itemConf then
        print(string.format("[DjonStNix-Pawnshop] Exploit Warning: Player %s attempted to sell invalid item: %s", src, itemName))
        return
    end
    
    -- Check if it is currently a wanted item
    if Config.Economy.RotationEnabled and not ActiveWantedItems[itemName] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'The broker is not buying ' .. itemName .. ' right now.', type = 'error' })
        return
    end

    -- Verify distance to prevent remote selling exploits
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local distValid = false
    for _, loc in pairs(Config.Locations) do
        local dist = #(playerCoords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
        if dist < 10.0 then
            distValid = true
            break
        end
    end

    if not distValid then 
        print(string.format("[DjonStNix-Pawnshop] Exploit Warning: Player %s attempted to sell from too far away.", src))
        return 
    end

    -- Amount Verification (works for qb/ox)
    local totalAmount = 0
    if GetResourceState("ox_inventory") == "started" then
        totalAmount = exports.ox_inventory:Search(src, 'count', itemName)
    else
        for _, v in pairs(Player.PlayerData.items) do
            if v and v.name == itemName then
                totalAmount = totalAmount + (v.amount or 0)
            end
        end
    end

    if totalAmount < amount then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'You do not have enough of this item.', type = 'error' })
        return
    end

    -- Determine payout at CURRENT market multiplier
    local currentMult = ItemMultipliers[itemName] or 1.0
    local pricePerUnit = 0
    
    if type(itemConf.price) == "table" then
        local rMin = math.floor(itemConf.price.min * currentMult)
        local rMax = math.floor(itemConf.price.max * currentMult)
        pricePerUnit = math.random(math.min(rMin, rMax), math.max(rMin, rMax)) 
    else
        pricePerUnit = math.floor(itemConf.price * currentMult)
    end

    local totalPayout = pricePerUnit * amount

    -- Execute Safe Removal and Payout
    if Player.Functions.RemoveItem(itemName, amount) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName] or {name = itemName, label = itemName}, 'remove', amount)
        Player.Functions.AddMoney(Config.Settings.Currency, totalPayout, "sold-pawn-shop")
        TriggerClientEvent('ox_lib:notify', src, { title = 'Success', description = string.format('Sold %sx %s for $%s.', amount, itemName, totalPayout), type = 'success' })
        
        if Config.Settings.Debug then
            print(string.format("[DjonStNix-Pawnshop] %s sold %sx %s for $%s [Market Mult: %s]", Player.PlayerData.citizenid, amount, itemName, totalPayout, currentMult))
        end
        
        -- Apply Depletion
        if Config.Economy.DepletionEnabled then
            -- Deplete based on AMOUNT sold
            local newMult = currentMult - (Config.Economy.DepletionPerSale * amount)
            if newMult < Config.Economy.MinPriceMultiplier then
                newMult = Config.Economy.MinPriceMultiplier
            end
            ItemMultipliers[itemName] = newMult
            if Config.Settings.Debug then print("[DjonStNix-Pawnshop] Market Multiplier for " .. itemName .. " dropped to " .. newMult) end
        end
        
        -- Police Snitch System Check
        if itemConf.hotItem and itemConf.snitchChance then
            if math.random(1, 100) <= itemConf.snitchChance then
                Config.Police.AlertFunction(playerCoords, "Pawn Shop", "Suspicious transaction reported involving stolen goods.")
                if Config.Settings.Debug then
                    print("[DjonStNix-Pawnshop] 🚨 Snitch Triggered! Police alerted for player " .. src)
                end
            end
        end

    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Transaction failed. Could not remove item.', type = 'error' })
    end
end)
