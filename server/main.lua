local QBCore = exports['qb-core']:GetCoreObject()

-- ==============================================================================
-- 📉 DYNAMIC ECONOMY STATE
-- ==============================================================================
local ItemMultipliers = {}
local ActiveWantedItems = {}

-- Initialize baseline economy
CreateThread(function()
    -- Load Persisted Economy
    local savedData = LoadEconomyState()
    for itemName, _ in pairs(Config.Items) do
        ItemMultipliers[itemName] = savedData[itemName] or 1.0
        -- If rotation is disabled, they want everything always
        if not Config.Economy.RotationEnabled then
             ActiveWantedItems[itemName] = true
        end
    end
    
    if Config.Economy.RotationEnabled then
        RotateWantedItems()
        LogAction("Debug", "Shop Economy Initialized: Rotation ENABLED.")
    else
        local count = 0
        for _ in pairs(ActiveWantedItems) do count = count + 1 end
        LogAction("Debug", string.format("Shop Economy Initialized: Rotation DISABLED. (%s items pawnable)", count))
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
    if maxCount == 0 and #itemKeys == 0 then
        -- Fallback: If no items picked by chance, just pick 1 random from all items
        local allKeys = {}
        for k, _ in pairs(Config.Items) do table.insert(allKeys, k) end
        ActiveWantedItems[allKeys[math.random(#allKeys)]] = true
    else
        for i = 1, maxCount do
            ActiveWantedItems[itemKeys[i]] = true
        end
    end
    
    if Config.Settings.Debug then
        local names = ""
        for k, _ in pairs(ActiveWantedItems) do names = names .. k .. ", " end
        LogAction("Debug", "Rotated Wanted Items: " .. names)
    end
end

-- Thread: Rotates Wanted Items every X minutes
CreateThread(function()
    if not Config.Economy.RotationEnabled then return end 
    while true do
        Wait(Config.Economy.RotationIntervalMin * 60000)
        RotateWantedItems()
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
            if recoveredAny then
                SaveEconomyState()
                if Config.Settings.Debug then
                    LogAction("Debug", "Economy Recovery Cycle Completed.")
                end
            end
        end
    end
end)

-- ==============================================================================
-- 💾 PERSISTENCE & LOGGING UTILS
-- ==============================================================================
function SaveEconomyState()
    SaveResourceFile(GetCurrentResourceName(), "economy_state.json", json.encode(ItemMultipliers), -1)
end

function LoadEconomyState()
    local file = LoadResourceFile(GetCurrentResourceName(), "economy_state.json")
    if file then
        local data = json.decode(file)
        return data or {}
    end
    return {}
end

function LogAction(type, message)
    if type == "Debug" and not Config.Settings.Debug then return end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local resource = GetCurrentResourceName()
    print(string.format("[%s] [%s] %s", resource, timestamp, message))
    
    -- Additional logging (file or webhook) could be added here
end

-- ==============================================================================
-- 📡 SECURE DATA TRANSMISSION
-- ==============================================================================
lib.callback.register('djonstnix_pawnshop:server:getSellableItems', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local sellableItems = {}
    local rawItems = {} -- Normalize inventory data

    -- Elite Mode: Accurate inventory check for both QB and Ox
    if GetResourceState("ox_inventory") == "started" then
        local inventory = exports.ox_inventory:GetInventoryItems(source)
        for _, item in pairs(inventory) do
            if item and item.name and Config.Items[item.name] then
                rawItems[item.name] = (rawItems[item.name] or 0) + item.count
            end
        end
    else
        for _, item in pairs(Player.PlayerData.items) do
            if item and item.name and Config.Items[item.name] then
                rawItems[item.name] = (rawItems[item.name] or 0) + (item.amount or item.count or 0)
            end
        end
    end

    for itemName, count in pairs(rawItems) do
        if ActiveWantedItems[itemName] and count > 0 then
            local currentMult = ItemMultipliers[itemName] or 1.0
            local basePrice = Config.Items[itemName].price
            
            local depletedPrice = {}
            if type(basePrice) == "table" then
                depletedPrice.min = math.floor(basePrice.min * currentMult)
                depletedPrice.max = math.floor(basePrice.max * currentMult)
            else
                depletedPrice = math.floor(basePrice * currentMult)
            end

            sellableItems[itemName] = {
                name = itemName,
                label = QBCore.Shared.Items[itemName]?.label or itemName,
                count = count,
                priceConf = depletedPrice,
                mult = currentMult
            }
        end
    end

    return sellableItems, (Config.Economy.RotationIntervalMin)
end)

-- ==============================================================================
-- 🛒 TRANSACTION LOGIC
-- ==============================================================================
RegisterNetEvent('djonstnix_pawnshop:server:sellItem', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local itemConf = Config.Items[itemName]
    if not itemConf then
        LogAction("Warning", string.format("Player %s (%s) attempted to sell invalid item: %s", GetPlayerName(src), Player.PlayerData.citizenid, itemName))
        return
    end
    
    if Config.Economy.RotationEnabled and not ActiveWantedItems[itemName] then return end

    -- Distance validation
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local distValid = false
    for _, loc in pairs(Config.Locations) do
        if #(playerCoords - vector3(loc.coords.x, loc.coords.y, loc.coords.z)) < 10.0 then
            distValid = true
            break
        end
    end
    if not distValid then 
        LogAction("Exploit", string.format("Player %s (%s) attempted to sell from too far away.", GetPlayerName(src), Player.PlayerData.citizenid))
        return 
    end

    -- Quantity verification
    local currentCount = 0
    if GetResourceState("ox_inventory") == "started" then
        currentCount = exports.ox_inventory:Search(src, 'count', itemName)
    else
        currentCount = Player.Functions.GetItemByName(itemName)?.amount or 0
    end

    if currentCount < amount then
        LogAction("Warning", string.format("Player %s (%s) attempted to sell more %s than they have (%s/%s)", GetPlayerName(src), Player.PlayerData.citizenid, itemName, amount, currentCount))
        return
    end

    -- Payout & Removal
    local currentMult = ItemMultipliers[itemName] or 1.0
    local price = 0
    if type(itemConf.price) == "table" then
        price = math.random(math.floor(itemConf.price.min * currentMult), math.floor(itemConf.price.max * currentMult))
    else
        price = math.floor(itemConf.price * currentMult)
    end
    local totalPayout = price * amount

    local removed = false
    if GetResourceState("ox_inventory") == "started" then
        removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
    else
        removed = Player.Functions.RemoveItem(itemName, amount)
    end

    if removed then
        if GetResourceState("ox_inventory") ~= "started" then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName] or {name = itemName, label = itemName}, 'remove', amount)
        end
        Player.Functions.AddMoney(Config.Settings.Currency, totalPayout, "pawn-shop-sell")
        TriggerClientEvent('ox_lib:notify', src, { title = 'Broker', description = string.format('Sold %sx %s for $%s', amount, itemName, totalPayout), type = 'success' })
        
        -- Statistics & Logging
        LogAction("Info", string.format("%s (%s) sold %sx %s for $%s [Mult: %s]", GetPlayerName(src), Player.PlayerData.citizenid, amount, itemName, totalPayout, currentMult))
        
        -- Depletion
        ItemMultipliers[itemName] = math.max(Config.Economy.MinPriceMultiplier, currentMult - (Config.Economy.DepletionPerSale * amount))
        SaveEconomyState()

        -- Snitch Alert
        if itemConf.hotItem and itemConf.snitchChance and math.random(1, 100) <= itemConf.snitchChance then
            Config.Police.AlertFunction(playerCoords, "Pawn Shop", "Suspicious transaction reported.")
            LogAction("Snitch", string.format("Police alerted for %s (%s) selling stolen %s.", GetPlayerName(src), Player.PlayerData.citizenid, itemName))
        end
    end
end)

RegisterNetEvent('djonstnix_pawnshop:server:sellAllItems', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local distValid = false
    for _, loc in pairs(Config.Locations) do
        if #(playerCoords - vector3(loc.coords.x, loc.coords.y, loc.coords.z)) < 10.0 then
            distValid = true
            break
        end
    end
    if not distValid then return end

    local itemsToSell = {}
    if GetResourceState("ox_inventory") == "started" then
        local inv = exports.ox_inventory:GetInventoryItems(src)
        for _, item in pairs(inv) do
            if item and item.name and Config.Items[item.name] and ActiveWantedItems[item.name] and item.count > 0 then
                itemsToSell[item.name] = (itemsToSell[item.name] or 0) + item.count
            end
        end
    else
        for _, item in pairs(Player.PlayerData.items) do
            if item and item.name and Config.Items[item.name] and ActiveWantedItems[item.name] and (item.amount or item.count or 0) > 0 then
                itemsToSell[item.name] = (itemsToSell[item.name] or 0) + (item.amount or item.count or 0)
            end
        end
    end

    if not next(itemsToSell) then return end

    local totalPayout = 0
    local totalItems = 0
    local triggeredSnitch = false

    for itemName, amount in pairs(itemsToSell) do
        local itemConf = Config.Items[itemName]
        local removed = false
        if GetResourceState("ox_inventory") == "started" then
            removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
        else
            removed = Player.Functions.RemoveItem(itemName, amount)
        end

        if removed then
            if GetResourceState("ox_inventory") ~= "started" then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName] or {name = itemName, label = itemName}, 'remove', amount)
            end
            
            local currentMult = ItemMultipliers[itemName] or 1.0
            local price = 0
            if type(itemConf.price) == "table" then
                price = math.random(math.floor(itemConf.price.min * currentMult), math.floor(itemConf.price.max * currentMult))
            else
                price = math.floor(itemConf.price * currentMult)
            end

            totalPayout = totalPayout + (price * amount)
            totalItems = totalItems + amount
            
            ItemMultipliers[itemName] = math.max(Config.Economy.MinPriceMultiplier, currentMult - (Config.Economy.DepletionPerSale * amount))
            
            if itemConf.hotItem and itemConf.snitchChance and not triggeredSnitch and math.random(1, 100) <= itemConf.snitchChance then
                triggeredSnitch = true
            end
        end
    end

    if totalPayout > 0 then
        Player.Functions.AddMoney(Config.Settings.Currency, totalPayout, "pawn-shop-sell-bulk")
        SaveEconomyState()
        TriggerClientEvent('ox_lib:notify', src, { title = 'Broker', description = string.format('Bulk sold %s items for $%s', totalItems, totalPayout), type = 'success' })
        LogAction("Info", string.format("%s (%s) bulk-sold %s items for $%s", GetPlayerName(src), Player.PlayerData.citizenid, totalItems, totalPayout))
        
        if triggeredSnitch then
            Config.Police.AlertFunction(playerCoords, "Pawn Shop", "Large suspicious transaction reported.")
            LogAction("Snitch", string.format("Police alerted for bulk sale by %s (%s).", GetPlayerName(src), Player.PlayerData.citizenid))
        end
    end
end)
