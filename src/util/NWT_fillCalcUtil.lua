
NWT_fillCalcUtil = {}

-- putting wrapped functions for fill lookups into table for safer lookups than reflection
local placeableFillEntryImpls = {
   spec_silo          = function(a, b, c) return NWT_fillCalcUtil:silo_FillCalculatorImpl(a, b, c) end,
   spec_siloExtension = function(a, b, c) return NWT_fillCalcUtil:siloExtension_FillCalculatorImpl(a, b, c) end,
   spec_husbandry     = function(a, b, c) return NWT_fillCalcUtil:husbandry_FillCalculatorImpl(a, b, c) end,
   spec_manureHeap    = function(a, b, c) return NWT_fillCalcUtil:manureHeap_FillCalculatorImpl(a, b, c) end,
   spec_bunkerSilo    = function(a, b, c) return NWT_fillCalcUtil:bunkerSilo_FillCalculatorImpl(a, b, c) end,
}

-- Calls implemention if found for each placeable to get entires for items in thier stock
function NWT_fillCalcUtil:getPlaceableFillEntries(entryTable, farmId)
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

function NWT_fillCalcUtil:silo_FillCalculatorImpl(entryTable, farmId, placeable)
    local fillLevels = placeable.spec_silo:getFillLevels()
    return self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
end

function NWT_fillCalcUtil:siloExtension_FillCalculatorImpl(entryTable, farmId, placeable)
    local fillLevels = placeable.spec_siloExtension.storage.fillLevels
    return self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
end

function NWT_fillCalcUtil:manureHeap_FillCalculatorImpl(entryTable, farmId, placeable)
    local fillLevels = placeable.spec_manureHeap.manureHeap.fillLevels
    return self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
end

function NWT_fillCalcUtil:bunkerSilo_FillCalculatorImpl(entryTable, farmId, placeable)
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

function NWT_fillCalcUtil:husbandry_FillCalculatorImpl(entryTable, farmId, placeable)
    if placeable.spec_husbandry.storage ~= nil then 
        local fillLevels = placeable.spec_husbandry.storage.fillLevels
        entryTable = self:fillEntryCalculator(entryTable, farmId, placeable, fillLevels)
    end
    return entryTable
end

function NWT_fillCalcUtil:fillEntryCalculator(entryTable, farmId, placeable, storageFillLevels)
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
