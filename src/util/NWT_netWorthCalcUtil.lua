-- NWT_netWorthCalcUtil
--
-- Manages the calculation and creation of entries for assets/liablities
--

NWT_netWorthCalcUtil = {}

NWT_netWorthCalcUtil._mt = Class(NWT_netWorthCalcUtil)

function NWT_netWorthCalcUtil:getEntries(farmId)
    local entryTable = {}

    local cashAmount = g_currentMission:getMoney()
    local cashAsset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
    cashAsset:init(farmId, g_i18n:getText("table_cash"), "Cash", "", cashAmount)
    cashAsset:register()
    table.insert(entryTable, cashAsset)

    local loanAmount = self:calculateLoanAmount(farmId)
    local loanAsset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
    loanAsset:init(farmId, g_i18n:getText("table_loan"), "Loan", "", -1 * loanAmount)
    loanAsset:register()
    table.insert(entryTable, loanAsset)

    entryTable = self:getEquipmentEntries(entryTable, farmId)
    entryTable = self:getFarmlandEntries(entryTable, farmId)
    entryTable = self:getSpawnedPalletEntries(entryTable, farmId)
    entryTable = self:getPlaceableEntries(entryTable, farmId)
    entryTable = NWT_fillCalcUtil:getPlaceableFillEntries(entryTable, farmId)
    -- todo 
    --     livestock
    --     production chains
    --     equipment fill stock

    return entryTable
end

function NWT_netWorthCalcUtil:getEquipmentEntries(entryTable, farmId)
    for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
        
        if vehicle.ownerFarmId == farmId 
            and vehicle.getSellPrice ~= nil 
            and vehicle.typeName ~= nil 
            and vehicle.typeName ~= "pallet"            -- exclude spawned pallets 
            and vehicle.typeName ~= "treeSaplingPallet" -- exclude spawned tree sapling pallets
            and vehicle.typeName ~= "bigBag"            -- exclude spawned big bags
            and vehicle.propertyState == VehiclePropertyState.OWNED then

            local vehicleAsset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            vehicleAsset:init(farmId, vehicle:getFullName(), "Equipment", "todo", vehicle:getSellPrice())
            vehicleAsset:register()
            table.insert(entryTable, vehicleAsset)

        end
    end

    return entryTable
end

function NWT_netWorthCalcUtil:getSpawnedPalletEntries(entryTable, farmId)
    for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == farmId 
            and vehicle.getSellPrice ~= nil 
            and vehicle.typeName ~= nil 
            and (vehicle.typeName == "pallet"               -- include spawned pallets 
                or vehicle.typeName == "treeSaplingPallet"  -- include spawned tree sapling pallets
                or vehicle.typeName == "bigBag")            -- include bags
            and vehicle.propertyState == VehiclePropertyState.OWNED then

            local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            asset:init(farmId, vehicle:getFullName(), "Pallet", "",  vehicle:getSellPrice())
            asset:register()
            table.insert(entryTable, asset)
            
        end
    end

    -- todo include with placeable stock

    return entryTable
end

function NWT_netWorthCalcUtil:getPlaceableEntries(entryTable, farmId)
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placeable.ownerFarmId == farmId then

            local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            asset:init(farmId, placeable:getName(), "Placeable", "", placeable:getSellPrice())
            asset:register()
            table.insert(entryTable, asset)

        end
    end

    return entryTable
end

function NWT_netWorthCalcUtil:calculateLoanAmount(farmId)
    local amount = 0
    local farms = g_farmManager:getFarms()

    for _, farm in pairs(farms) do
        if farm.farmId == farmId then
            amount = amount + farm.loan
        end
    end

    return amount
end

function NWT_netWorthCalcUtil:getFarmlandEntries(entryTable, farmId)
    for _, farmland in pairs(g_farmlandManager:getFarmlands()) do
        if g_farmlandManager:getFarmlandOwner(farmland.id) == farmId then
            local farmlandAsset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            farmlandAsset:init(farmId, "Farmland #" .. farmland.name, "Farmland", "", farmland.price)
            farmlandAsset:register()
            table.insert(entryTable, farmlandAsset)
        end
    end

    return entryTable
end
