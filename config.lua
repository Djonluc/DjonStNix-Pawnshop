Config = Config or {}

-- ==============================================================================
-- ⚙️ CORE SETTINGS & UI CONFIGURATION
-- ==============================================================================
Config.Settings = {
    Debug = true, -- Enabled temporarily for review
    Target = "ox", -- "ox" or "qb"
    Inventory = "qb", -- "qb" or "ox". ox_inventory is auto-detected.
    Currency = "cash", -- "cash", "bank", or "crypto"
}

-- ==============================================================================
-- 📉 DYNAMIC ECONOMY & ROTATION
-- ==============================================================================
Config.Economy = {
    -- Rotating Wanted Items
    RotationEnabled = true,        -- If true, the pawn shop only buys a random subset of items at a time
    RotationIntervalMin = 60,      -- How often the "Wanted Items" change (in minutes)
    MaxWantedItems = 3,            -- How many different items the pawn shop will buy at any given time
    
    -- Price Depletion
    DepletionEnabled = true,       -- If true, selling an item lowers its price for everyone on the server
    DepletionPerSale = 0.05,       -- 0.05 = Price drops 5% per item sold
    MinPriceMultiplier = 0.20,     -- Price cannot drop below 20% of its base value
    
    -- Price Recovery
    RecoveryInterval = 10,         -- How often (in minutes) prices recover globally
    RecoveryAmount = 0.02,         -- 0.02 = Price recovers 2% every interval
}

-- ==============================================================================
-- 🚨 POLICE / SNITCH SETTINGS
-- ==============================================================================
Config.Police = {
    AlertFunction = function(coords, title, description)
        -- DjonStNix Standard Dispatch / Police Alert Integration
        TriggerEvent("police:server:policeAlert", "Shady Pawn Transaction")
    end,
}

-- ==============================================================================
-- 🗺️ PAWN SHOP LOCATIONS & NPCS
-- ==============================================================================
Config.Locations = {
    ["MainPawn"] = {
        coords = vector4(412.31, 314.11, 103.02, 237.5),
        pedModel = "ig_cletus",
        scenario = "WORLD_HUMAN_STAND_IMPATIENT",
        blip = {
            enabled = true,
            id = 431,
            color = 5,
            scale = 0.8,
            title = "Pawn Shop"
        },
        targetLabel = "Talk to Pawn Broker",
        targetIcon = "fas fa-hand-holding-usd",
        targetDistance = 2.0
    }
}

-- ==============================================================================
-- 🛒 PAWNABLE ITEMS, PRICES & FLAGS
-- ==============================================================================
Config.Items = {
    ["goldbar"] = { 
        price = { min = 15000, max = 22000 },
        buyChance = 10,    -- 10% chance the broker will even consider buying this during a rotation (rare)
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 35  -- 35% chance to call cops when sold
    },
    ["rolex"] = { 
        price = 250,
        hotItem = false -- Legal
    }, 
    ["goldchain"] = { 
        price = { min = 150, max = 300 },
        hotItem = false 
    }, 
    ["diamond_ring"] = { 
        price = 400,
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 10  -- 10% chance to call cops when sold
    },
    ["stolen_tv"] = { 
        price = { min = 50, max = 150 },
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 25  -- 25% chance to call cops when sold
    },
    ["copper_wire"] = { 
        price = 25,
        hotItem = false 
    },
    ["aluminum_scrap"] = { 
        price = 15,
        hotItem = false 
    },
}
