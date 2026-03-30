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
    -- Pawn Shop Configuration
    RotationEnabled = false,        -- If false, ALL items in Config.Items are always buyable. If true, the broker only buys a subset.
    RotationIntervalMin = 60,      -- (Only if RotationEnabled is true) How often the "Wanted Items" change (in minutes)
    MaxWantedItems = 5,            -- (Only if RotationEnabled is true) How many different items the pawn shop will buy at any given time
    
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
        price = { min = 20000, max = 30000 },
        buyChance = 10,    -- 10% chance the broker will even consider buying this during a rotation (rare)
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 35  -- 35% chance to call cops when sold
    },
    ["gold"] = { 
        price = { min = 8000, max = 12000 },
        buyChance = 15,    -- 15% chance the broker will buy this
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 30  -- 30% chance to call cops when sold
    },
    ["rolex"] = { 
        price = 400,
        hotItem = false -- Legal
    }, 
    ["goldchain"] = { 
        price = { min = 250, max = 450 },
        hotItem = false 
    }, 
    ["diamond_ring"] = { 
        price = 600,
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 10  -- 10% chance to call cops when sold
    },
    ["stolen_tv"] = { 
        price = { min = 100, max = 250 },
        hotItem = true,    -- (Stolen / Illegal items)
        snitchChance = 25  -- 25% chance to call cops when sold
    },
    ["copper_wire"] = { 
        price = 40,
        hotItem = false 
    },
    ["aluminum_scrap"] = { 
        price = 25,
        hotItem = false 
    },
    -- Heist Loot Items
    ["gold_ring"] = { 
        price = 500,
        hotItem = true,
        snitchChance = 15
    },
    ["gold_watch"] = { 
        price = 600,
        hotItem = true,
        snitchChance = 15
    },
    ["gold_bracelet"] = { 
        price = { min = 200, max = 350 },
        hotItem = true,
        snitchChance = 15
    },
    ["gold_necklace"] = { 
        price = { min = 250, max = 400 },
        hotItem = true,
        snitchChance = 18
    },
    ["heist_paint_1"] = { 
        price = { min = 20000, max = 25000 },
        hotItem = true,
        snitchChance = 50,
        buyChance = 5  -- Rare, high value
    },
    ["heist_paint_2"] = { 
        price = { min = 20000, max = 25000 },
        hotItem = true,
        snitchChance = 50,
        buyChance = 5
    },
    ["heist_paint_3"] = { 
        price = { min = 20000, max = 25000 },
        hotItem = true,
        snitchChance = 50,
        buyChance = 5
    },
    ["heist_paint_4"] = { 
        price = { min = 20000, max = 25000 },
        hotItem = true,
        snitchChance = 50,
        buyChance = 5
    },
    ["painting"] = { 
        price = 400,
        hotItem = true,
        snitchChance = 20
    },
    ["silver_coin"] = { 
        price = 120,
        hotItem = true,
        snitchChance = 10
    },
    ["gold_coin"] = { 
        price = 160,
        hotItem = true,
        snitchChance = 15
    },
    ["ninja_figure"] = { 
        price = 140,
        hotItem = true,
        snitchChance = 10
    },
    ["trading_painting"] = { 
        price = 250,
        hotItem = true,
        snitchChance = 15
    },
    ["trading_statue"] = { 
        price = 220,
        hotItem = true,
        snitchChance = 15
    },
    -- Illegal Activity Items (Non-Drug)
    ["laptop"] = { 
        price = { min = 2000, max = 3000 },
        hotItem = true,
        snitchChance = 20
    },
    ["phone"] = { 
        price = 500,
        hotItem = true,
        snitchChance = 10
    },
    ["tablet"] = { 
        price = { min = 800, max = 1200 },
        hotItem = true,
        snitchChance = 15
    },
    ["lockpick"] = { 
        price = { min = 150, max = 300 },
        hotItem = true,
        snitchChance = 5
    },
    ["advancedlockpick"] = { 
        price = { min = 300, max = 600 },
        hotItem = true,
        snitchChance = 10
    },
    ["thermite"] = { 
        price = { min = 3000, max = 5000 },
        hotItem = true,
        snitchChance = 40
    },
    ["gatecrack"] = { 
        price = { min = 2500, max = 4000 },
        hotItem = true,
        snitchChance = 35
    },
    ["coke_paint_marker"] = { 
        price = 80,
        hotItem = true,
        snitchChance = 5
    },
    -- House Robbery Items
    ["diamond"] = { 
        price = { min = 800, max = 1200 },
        hotItem = true,
        snitchChance = 25
    },
    ["ruby"] = { 
        price = { min = 600, max = 900 },
        hotItem = true,
        snitchChance = 20
    },
    ["danburite"] = { 
        price = { min = 400, max = 700 },
        hotItem = true,
        snitchChance = 15
    },
    ["charlotte_ring"] = { 
        price = 350,
        hotItem = true,
        snitchChance = 15
    },
    ["simbolos_chain"] = { 
        price = 450,
        hotItem = true,
        snitchChance = 20
    },
    ["action_figure"] = { 
        price = 180,
        hotItem = true,
        snitchChance = 10
    },
    ["nomimos_ring"] = { 
        price = 320,
        hotItem = true,
        snitchChance = 15
    },
    ["boss_chain"] = { 
        price = 500,
        hotItem = true,
        snitchChance = 25
    },
    ["branded_cigarette"] = { 
        price = 25,
        hotItem = true,
        snitchChance = 5
    },
    ["branded_cigarette_box"] = { 
        price = 200,
        hotItem = true,
        snitchChance = 10
    },
    ["ancient_egypt_artifact"] = { 
        price = { min = 1500, max = 2500 },
        hotItem = true,
        snitchChance = 30
    },
    ["television"] = { 
        price = { min = 300, max = 600 },
        hotItem = true,
        snitchChance = 15
    },
    ["music_player"] = { 
        price = { min = 200, max = 400 },
        hotItem = true,
        snitchChance = 12
    },
    ["microwave"] = { 
        price = { min = 150, max = 300 },
        hotItem = true,
        snitchChance = 10
    },
    ["computer"] = { 
        price = { min = 800, max = 1500 },
        hotItem = true,
        snitchChance = 20
    },
    ["coffee_machine"] = { 
        price = { min = 250, max = 500 },
        hotItem = true,
        snitchChance = 12
    }
}
