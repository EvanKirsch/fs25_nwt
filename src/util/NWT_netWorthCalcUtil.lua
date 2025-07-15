-- NWT_netWorthCalcUtil
--
-- Manages the calculation and creation of entries for assets/liablities
--

NWT_netWorthCalcUtil = {}

NWT_netWorthCalcUtil._mt = Class(NWT_netWorthCalcUtil)

function NWT_netWorthCalcUtil:getEntries(farmId)
    local entryTable = {}

    local cashCatagory = g_i18n:getText("table_cat_cash")
    local cashSubCatagory = g_i18n:getText("table_cash")
    local cashAmount = g_currentMission:getMoney()

    local cashAsset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
    cashAsset:init(farmId, cashSubCatagory, cashCatagory, cashSubCatagory, "", cashAmount)
    cashAsset:register()
    table.insert(entryTable, cashAsset)

    local loanAmount = self:calculateLoanAmount(farmId)
    if loanAmount > 0 then
        local loanCatagory = g_i18n:getText("table_cat_cash")
        local loanSubCatagory = g_i18n:getText("table_loan")

        local loanAsset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
        loanAsset:init(farmId, loanSubCatagory, loanCatagory, loanSubCatagory, "", -1 * loanAmount)
        loanAsset:register()
        table.insert(entryTable, loanAsset)
    end

    entryTable = self:getEquipmentEntries(entryTable, farmId)
    entryTable = self:getFarmlandEntries(entryTable, farmId)
    entryTable = self:getPlaceableEntries(entryTable, farmId)
    entryTable = self:getLivestockEntries(entryTable, farmId)
    entryTable = NWT_fillCalcUtil:getFillEntries(entryTable, farmId)

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

            local assetCatagory = g_i18n:getText("table_cat_equipment")
            local vehicleConfig = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            local assetSubCatagory = nil
            if vehicleConfig ~= nil then
                assetSubCatagory = g_storeManager:getCategoryByName(vehicleConfig.categoryName).title
            end

            local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())


            asset:init(farmId, vehicle:getFullName(), assetCatagory, assetSubCatagory, "", vehicle:getSellPrice())
            asset:register()
            table.insert(entryTable, asset)

        end
    end

    return entryTable
end

function NWT_netWorthCalcUtil:getPlaceableEntries(entryTable, farmId)
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placeable.ownerFarmId == farmId then
            local assetCatagory = g_i18n:getText("table_cat_property")
            local assetSubCatagory = g_i18n:getText("table_placeable")
            local assetDetails = g_i18n:getText("details_age") .. ": "  .. placeable.age .. " " .. g_i18n:getText("details_age_unit")

            local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            asset:init(farmId, placeable:getName(), assetCatagory, assetSubCatagory, assetDetails, placeable:getSellPrice())
            asset:register()
            table.insert(entryTable, asset)

        end
    end

    return entryTable
end

function NWT_netWorthCalcUtil:getLivestockEntries(entryTable, farmId)
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placeable.ownerFarmId == farmId
            and placeable.spec_husbandryAnimals ~= nil then

            local livestockValue = 0
            local livestockNumber = 0
            for _, cluster in pairs(placeable.spec_husbandryAnimals.clusterSystem.clusters) do

                local subType = g_currentMission.animalSystem.subTypes[cluster.subTypeIndex]
                local unmodifiedPrice = subType.sellPrice:get(cluster.age)

                -- TODO - fix price calculations, incorrect for horses and not 100% healthy animals
                local healthModifier = math.min(1, subType.healthThresholdFactor + (cluster.health / 100))
                local modifiedPrice = healthModifier * unmodifiedPrice

                livestockValue = livestockValue + (modifiedPrice * cluster.numAnimals)
                livestockNumber = livestockNumber + cluster.numAnimals

            end

            if livestockValue ~= 0 then
                local description = placeable.spec_husbandryAnimals.animalType.groupTitle
                local assetDetails = placeable:getName() .. ", " .. livestockNumber .. " " .. description
                local assetCatagory = g_i18n:getText("table_cat_inventory")
                local assetSubCatagory = g_i18n:getText("table_livestock")

                local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
                asset:init(farmId, description, assetCatagory, assetSubCatagory, assetDetails, livestockValue)
                asset:register()
                table.insert(entryTable, asset)

            end

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
            local assetCatagory = g_i18n:getText("table_cat_property")
            local assetSubCatagory = g_i18n:getText("table_land")
            local assetName = "Farmland #" .. farmland.name

            local asset = NWT_entry.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            asset:init(farmId, assetName, assetCatagory, assetSubCatagory, "", farmland.price)
            asset:register()
            table.insert(entryTable, asset)

        end
    end

    return entryTable
end
