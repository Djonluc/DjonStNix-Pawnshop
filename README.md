# DjonStNix-Pawnshop

A highly advanced, fully standalone Pawn Shop script for QBCore frameworks, adhering to the strict **DjonStNix Ecosystem Standards**. This resource features a dynamically rotating inventory of "wanted items", a live market supply/demand pricing system, and a built-in "snitch" police alert mechanic for selling stolen goods.

## 🌟 Key Features

*   **🔄 Rotating "Wanted" Inventory:** The pawn broker doesn't buy everything forever. Every hour, they rotate their requests, forcing players to check back to see what is currently valuable.
*   **📉 Dynamic Economy (Market Depletion):** As players sell items, the market becomes flooded, dynamically dropping the sale price for everyone on the server. The market slowly recovers over time in the background.
*   **🚨 Snitch System (Police Alerts):** Attempting to pawn "Hot Items" like stolen TVs or Diamond Rings carries a configurable percentage risk of the broker silently alerting the police.
*   **💎 Rarity Mechanics:** Items can have a `buyChance` assigned to them. Extremely rare items like Gold Bars might only spawn on the broker's "Wanted List" 5% of the time.
*   **🔒 Secure UI:** Fully integrated with `ox_lib` for clean, responsive context menus and input dialogs. Strictly server-sided validation to completely eliminate duplicating or remote-selling exploits.

## 📦 Dependencies

*   [qb-core](https://github.com/qbcore-framework/qb-core)
*   [ox_lib](https://github.com/overextended/ox_lib)
*   [ox_target](https://github.com/overextended/ox_target) OR [qb-target](https://github.com/qbcore-framework/qb-target)
*   (Optional but Supported) [ox_inventory](https://github.com/overextended/ox_inventory)

---

## 🛠️ Installation Process

1.  Download or clone the resource into your `[addons]` folder (or wherever you prefer).
2.  Ensure that the folder name is exactly `DjonStNix-Pawnshop`.
3.  Add the following line to your `server.cfg`, ensuring it is loaded **after** QBCore and ox_lib:
    ```bash
    ensure DjonStNix-Pawnshop
    ```
4.  Restart your server or start the resource dynamically.

---

## ⚙️ Snippets & Configuration Guide

You can completely control the economy and items through `config.lua`.

### How to Add a New Item
To add a new item for the pawn shop to buy, navigate to `Config.Items` in `config.lua`.

**Example: Standard Item**
```lua
["laptop"] = { 
    price = 300,            -- Fixed price of $300
    hotItem = false         -- No risk of police alerts
},
```

**Example: Randomized Price & Stolen Item**
```lua
["stolen_laptop"] = { 
    price = { min = 150, max = 500 }, -- Random payout
    hotItem = true,                   -- Flags the item as illegal
    snitchChance = 25                 -- 25% chance to call the police
},
```

**Example: Ultra-Rare Item**
```lua
["goldbar"] = { 
    price = { min = 15000, max = 22000 },
    buyChance = 10,   -- The broker only has a 10% chance to want this during a rotation
    hotItem = true,
    snitchChance = 35 
},
```

### Market Settings
Adjust how quickly prices drop and recover in the `Config.Economy` table:
```lua
Config.Economy = {
    RotationEnabled = true,        
    RotationIntervalMin = 60,      -- Broker changes what they want every 60 minutes
    MaxWantedItems = 3,            -- Broker only wants 3 different item types at once
    
    DepletionEnabled = true,       
    DepletionPerSale = 0.05,       -- Price drops 5% every time 1 item is sold
    MinPriceMultiplier = 0.20,     -- Hard cap: item values won't drop below 20%
    
    RecoveryInterval = 10,         -- Prices slowly recover every 10 minutes
    RecoveryAmount = 0.02,         -- Recover by +2%
}
```

### Police Dispatch Support
If you use a custom dispatch system like **PS-Dispatch** or **CD-Dispatch**, you can easily swap the generic alert. Simply edit the function in `config.lua`:
```lua
Config.Police = {
    AlertFunction = function(coords, title, description)
        -- Example for ps-dispatch:
        -- exports['ps-dispatch']:SuspiciousActivity(coords)
        
        -- Default generic qb-core alert:
        TriggerEvent("police:server:policeAlert", "Shady Pawn Transaction")
    end,
}
```

---
*Developed adhering strictly to DjonStNix professional ecosystem standards.*
