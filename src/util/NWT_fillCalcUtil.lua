-- NWT_fillCalcUtil
--
-- Calculates fill stock amounts, agregates and creates entries
--

NWT_fillCalcUtil = {}

-- putting wrapped functions for fill lookups into table for safer lookups than reflection
local placeableFillEntryImpls = {
   spec_silo          = function(a, b, c) return NWT_fillCalcUtil:silo_FillCalculatorImpl(a, b, c) end,
   spec_siloExtension = function(a, b, c) return NWT_fillCalcUtil:siloExtension_FillCalculatorImpl(a, b, c) end,
   spec_husbandry     = function(a, b, c) return NWT_fillCalcUtil:husbandry_FillCalculatorImpl(a, b, c) end,
   spec_manureHeap    = function(a, b, c) return NWT_fillCalcUtil:manureHeap_FillCalculatorImpl(a, b, c) end,
   spec_bunkerSilo    = function(a, b, c) return NWT_fillCalcUtil:bunkerSilo_FillCalculatorImpl(a, b, c) end,
}

function NWT_fillCalcUtil:getFillEntries(entryTable, farmId)
    local fillTable = {}
    fillTable = self:getPlaceableFillEntries(fillTable, farmId)
    fillTable = self:getVehicleFillEntries(fillTable, farmId)
    fillTable = self:getBaleFillEntries(fillTable, farmId)
    fillTable = self:getProductionEntries(fillTable, farmId)

    for _, fillEntry in pairs(fillTable) do
        table.insert(entryTable, fillEntry)
    end

    return entryTable
end

function NWT_fillCalcUtil:getVehicleFillEntries(fillTable, farmId)
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == farmId
            and vehicle.spec_fillUnit ~= nil
            and vehicle.spec_fillUnit.fillUnits ~= nil -- nullable even in fillUnit spec?
            and vehicle.propertyState == VehiclePropertyState.OWNED then

            for _, fillUnit in pairs(vehicle.spec_fillUnit.fillUnits) do
                 local storageFillLevels = {}
                 storageFillLevels[fillUnit.fillType] = fillUnit.fillLevel
                 fillTable = self:fillEntryCalculator(fillTable, farmId, storageFillLevels)
            end

        end
    end

    return fillTable
end

function NWT_fillCalcUtil:getBaleFillEntries(fillTable, farmId)
    for _, obj in pairs(g_currentMission.itemSystem.itemsToSave) do
        local bale = obj.item

        if bale.isa ~= nil and bale:isa(Bale) and bale.ownerFarmId == farmId then
            local fillId = bale.fillType
            local fillAmount = bale.fillLevel
            local storageFillLevels = {}
            storageFillLevels[fillId] = fillAmount
            fillTable = self:fillEntryCalculator(fillTable, farmId, storageFillLevels)

        end
    end

    return fillTable
end

function NWT_fillCalcUtil:getProductionEntries(fillTable, farmId)
    for _, production in pairs(g_currentMission.productionChainManager.productionPoints) do

        if production.ownerFarmId == farmId then
            for _, fillId in pairs(production.outputFillTypeIdsArray) do
                local fillAmount = MathUtil.round(production.storage:getFillLevel(fillId))
                local storageFillLevels = {}
                storageFillLevels[fillId] = fillAmount
                fillTable = self:fillEntryCalculator(fillTable, farmId, storageFillLevels)
            end

        end
    end

    return fillTable
end

-- Calls implemention if found for each placeable to get entires for items in thier stock
function NWT_fillCalcUtil:getPlaceableFillEntries(fillTable, farmId)
    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if placeable.ownerFarmId == farmId then

            if placeable.specializationNames ~= nil then
                for _, name in pairs(placeable.specializationNames) do
                    local spec_name = "spec_" .. tostring(name)

                    if placeableFillEntryImpls[spec_name] ~= nil then
                        -- call spec impl based on table spec_name lookup
                        local implFunction = placeableFillEntryImpls[spec_name]
                        implFunction(fillTable, farmId, placeable)

                    end
                end
            end
        end
    end

    return fillTable
end

function NWT_fillCalcUtil:silo_FillCalculatorImpl(fillTable, farmId, placeable)
    local fillLevels = placeable.spec_silo:getFillLevels()
    return self:fillEntryCalculator(fillTable, farmId, fillLevels)
end

function NWT_fillCalcUtil:siloExtension_FillCalculatorImpl(fillTable, farmId, placeable)
    local fillLevels = placeable.spec_siloExtension.storage.fillLevels
    return self:fillEntryCalculator(fillTable, farmId, fillLevels)
end

function NWT_fillCalcUtil:manureHeap_FillCalculatorImpl(fillTable, farmId, placeable)
    local fillLevels = placeable.spec_manureHeap.manureHeap.fillLevels
    return self:fillEntryCalculator(fillTable, farmId, fillLevels)
end

function NWT_fillCalcUtil:bunkerSilo_FillCalculatorImpl(fillTable, farmId, placeable)
    local bunkerSilo = placeable.spec_bunkerSilo.bunkerSilo
    local fillAmount = bunkerSilo.fillLevel

    -- if there is fill, find the fill type and put into table to use common fill entry calculator
    if bunkerSilo.fillLevel ~= 0 then
        local fillId = bunkerSilo.inputFillType

        if bunkerSilo.state == BunkerSilo.STATE_FERMENTED
            or bunkerSilo.state == BunkerSilo.STATE_DRAIN then
            fillId = bunkerSilo.outputFillType
        end

        local storageFillLevels = {}
        storageFillLevels[fillId] = fillAmount
        fillTable = self:fillEntryCalculator(fillTable, farmId, storageFillLevels)

    end

    return fillTable
end

function NWT_fillCalcUtil:husbandry_FillCalculatorImpl(fillTable, farmId, placeable)
    if placeable.spec_husbandry.storage ~= nil then
        local fillLevels = placeable.spec_husbandry.storage.fillLevels
        fillTable = self:fillEntryCalculator(fillTable, farmId, fillLevels)
    end

    return fillTable
end

function NWT_fillCalcUtil:fillEntryCalculator(fillTable, farmId, storageFillLevels)
    for fillId, fillAmount in pairs(storageFillLevels) do
        if fillAmount ~= 0 then
            local fillInfo = g_fillTypeManager.fillTypes[fillId]

            if fillInfo.pricePerLiter ~= 0 then
                local entryTitle = fillInfo.title
                local details = math.floor(fillAmount + 0.5)
                local fillValue = fillAmount * fillInfo.pricePerLiter

                local asset = nil
                if fillTable[fillId] == nil then
                    asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
                    asset:init(farmId, entryTitle, "Fill", details, fillValue)
                    asset:register()

                else
                    asset = fillTable[fillId]
                    asset.details = asset.details + details
                    asset.entryAmount = asset.entryAmount + fillValue

                end

                fillTable[fillId] = asset

            end
        end
    end

    return fillTable
end
