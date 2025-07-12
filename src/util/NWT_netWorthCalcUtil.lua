-- NWT_netWorthCalcUtil
--
-- Manages the calculation and creation of entries for assets/liablities
--

NWT_netWorthCalcUtil = {}

NWT_netWorthCalcUtil._mt = Class(NWT_netWorthCalcUtil)

-- putting wrapped functions for fill lookups into table for safer lookups than reflection
local placeableFillEntryImpls = {
   spec_silo          = function(a, b, c) return NWT_netWorthCalcUtil:silo_FillCalculatorImpl(a, b, c) end,
   spec_siloExtension = function(a, b, c) return NWT_netWorthCalcUtil:siloExtension_FillCalculatorImpl(a, b, c) end,
   spec_husbandry     = function(a, b, c) return NWT_netWorthCalcUtil:husbandry_FillCalculatorImpl(a, b, c) end,
   spec_manureHeap    = function(a, b, c) return NWT_netWorthCalcUtil:manureHeap_FillCalculatorImpl(a, b, c) end,
   spec_bunkerSilo    = function(a, b, c) return NWT_netWorthCalcUtil:bunkerSilo_FillCalculatorImpl(a, b, c) end,
}

-- function NWT_netWorthCalcUtil.new() 
--     local self = NWT_netWorthCalcUtil:superClass().new(NWT_netWorthCalcUtil._mt)
--     return self
-- end

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
    entryTable = self:getPlaceableFillEntries(entryTable, farmId)
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

-- Calls implemention if found for each placeable to get entires for items in thier stock
function NWT_netWorthCalcUtil:getPlaceableFillEntries(entryTable, farmId)
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placeable.ownerFarmId == farmId then

            if placeable.specializationNames ~= nil then
                for _, name in pairs(placeable.specializationNames) do
                    local spec_name = "spec_" .. tostring(name)

                    if placeableFillEntryImpls[spec_name] ~= nil then
                        -- call spec impl based on table spec_name lookup
                        local implFunction = placeableFillEntryImpls[spec_name]
                        implFunction(entryTable, farmId, placeable)

                    end
                end
            end
        end
    end

    return entryTable
end

function NWT_netWorthCalcUtil:silo_FillCalculatorImpl(entryTable, farmId, placeable)
    local fillLevels = placeable.spec_silo:getFillLevels()
    return self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
end

function NWT_netWorthCalcUtil:siloExtension_FillCalculatorImpl(entryTable, farmId, placeable)
    local fillLevels = placeable.spec_siloExtension.storage.fillLevels
    return self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
end

function NWT_netWorthCalcUtil:manureHeap_FillCalculatorImpl(entryTable, farmId, placeable)
    local fillLevels = placeable.spec_manureHeap.manureHeap.fillLevels
    return self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
end

function NWT_netWorthCalcUtil:bunkerSilo_FillCalculatorImpl(entryTable, farmId, placeable)
    local bunkerSilo = placeable.spec_bunkerSilo.bunkerSilo
    local fillAmount = bunkerSilo.fillLevel

    -- if there is fill, find the fill type and put into table to use common fill entry calculator
    if bunkerSilo.fillLevel ~= 0 then 
        local fillId = bunkerSilo.inputFillType

        if bunkerSilo.state == BunkerSilo.STATE_FERMENTED 
            or bunkerSilo.state == BunkerSilo.STATE_DRAIN then
            fillId = bunkerSilo.outputFillType
        end 

        -- todo, put in table in order to use use common function
        if fillAmount ~= 0 then
            local fillInfo = g_fillTypeManager.fillTypes[fillId]

            if fillInfo.pricePerLiter ~= 0 then
                local entryName = fillInfo.name .. " (" .. placeable:getName() .. ")" 
                local details = tostring(fillAmount) .. "L x " .. g_i18n:formatMoney(fillInfo.pricePerLiter, 2, true, true)
                local totalFillValue = fillAmount * fillInfo.pricePerLiter

                local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
                asset:init(farmId, entryName, "Fill", details, totalFillValue)
                asset:register()
                table.insert(entryTable, asset)
            end
        end


    end
    return entryTable
end

function NWT_netWorthCalcUtil:husbandry_FillCalculatorImpl(entryTable, farmId, placeable)
    if placeable.spec_husbandry.storage ~= nil then 
        local fillLevels = placeable.spec_husbandry.storage.fillLevels
        entryTable = self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
    end
    return entryTable
end

function NWT_netWorthCalcUtil:fillEntryCalculator(entryTable, farmId, placeable, storageFillLevels)
    for fillId, fillAmount in pairs(storageFillLevels) do
        if fillAmount ~= 0 then
            local fillInfo = g_fillTypeManager.fillTypes[fillId]

            if fillInfo.pricePerLiter ~= 0 then
                local entryName = fillInfo.name .. " (" .. placeable:getName() .. ")" 
                local details = tostring(fillAmount) .. "L x " .. g_i18n:formatMoney(fillInfo.pricePerLiter, 2, true, true)
                local totalFillValue = fillAmount * fillInfo.pricePerLiter

                local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
                asset:init(farmId, entryName, "Fill", details, totalFillValue)
                asset:register()
                table.insert(entryTable, asset)

            end
        end
    end
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

-- g_nwt_netWorthCalcUtil = NWT_netWorthCalcUtil.new()
