-- NWT_inGameMenuNetWorthTracker
--
-- Converts entries for display and populates entry lists on in game menu
--

NWT_inGameMenuNetWorthTracker = {}
NWT_inGameMenuNetWorthTracker.entryData = {}

NWT_inGameMenuNetWorthTracker._mt = Class(NWT_inGameMenuNetWorthTracker, TabbedMenuFrameElement)

function NWT_inGameMenuNetWorthTracker.new(i18n, messageCenter)
     local self = NWT_inGameMenuNetWorthTracker:superClass().new(nil, NWT_inGameMenuNetWorthTracker._mt)

     self.name = "NWT_inGameMenuNetWorthTracker"
     self.i18n = i18n
     self.messageCenter = messageCenter
     
     return self
 end

function NWT_inGameMenuNetWorthTracker:onGuiSetupFinished()
    NWT_inGameMenuNetWorthTracker:superClass().onGuiSetupFinished(self)

    self.entryTable:setDataSource(self)
    self.entryTable:setDelegate(self)
end

function NWT_inGameMenuNetWorthTracker:onFrameOpen(element)
    NWT_inGameMenuNetWorthTracker:superClass().onFrameOpen(self)

    self:updateContent()

    FocusManager:setFocus(self.entryTable)
end

function NWT_inGameMenuNetWorthTracker:updateContent()
    local farmId = g_farmManager:getFarmByUserId(g_currentMission.playerUserId).farmId
    self.entryData = NWT_netWorthCalcUtil:getEntries(farmId)

    local fCashTotalValue = 0
    local fEquipmentTotalValue = 0
    local fPropertyTotalValue = 0
    local fInventoryTotalValue = 0
    local fNetWorthTotalValue = 0

    local catCash = g_i18n:getText("table_cat_cash")
    local catEquipment = g_i18n:getText("table_cat_equipment")
    local catProperty = g_i18n:getText("table_cat_property")
    local catInventory = g_i18n:getText("table_cat_inventory")
    for _, entry in pairs(self.entryData) do
        fNetWorthTotalValue = fNetWorthTotalValue + entry.entryAmount

        if entry.catagory == catCash then
            fCashTotalValue = fCashTotalValue + entry.entryAmount

        elseif entry.catagory == catEquipment then
            fEquipmentTotalValue = fEquipmentTotalValue + entry.entryAmount

        elseif entry.catagory == catProperty then
            fPropertyTotalValue = fPropertyTotalValue + entry.entryAmount

        elseif entry.catagory == catInventory then
            fInventoryTotalValue = fInventoryTotalValue + entry.entryAmount

        end

    end 

    self.cashTotalValue:setText(g_i18n:formatMoney(fCashTotalValue, 0, true, true))
    self.equipmentTotalValue:setText(g_i18n:formatMoney(fEquipmentTotalValue, 0, true, true))
    self.propertyTotalValue:setText(g_i18n:formatMoney(fPropertyTotalValue, 0, true, true))
    self.inventoryTotalValue:setText(g_i18n:formatMoney(fInventoryTotalValue, 0, true, true))
    self.netWorthTotalValue:setText(g_i18n:formatMoney(fNetWorthTotalValue, 0, true, true))

    self.entryTable:reloadData()
end

function NWT_inGameMenuNetWorthTracker:getNumberOfSections()
    return 1
end

function NWT_inGameMenuNetWorthTracker:getNumberOfItemsInSection(list, section)
    return #self.entryData
end

function NWT_inGameMenuNetWorthTracker:getTitleForSectionHeader(list, section)
    return "no impl"
end

function NWT_inGameMenuNetWorthTracker:populateCellForItemInSection(list, section, index, cell)
    local loc_entryData = self.entryData[index]
    cell:getAttribute("entryTitle"):setText(loc_entryData.entryTitle)
    local entryCatagory = loc_entryData.catagory .. " (" .. loc_entryData.subCatagory .. ")"
    cell:getAttribute("entryCatagory"):setText(entryCatagory)
    cell:getAttribute("entryDetails"):setText(loc_entryData.details)
    cell:getAttribute("entryAmount"):setText(g_i18n:formatMoney(loc_entryData.entryAmount, 0, true, true))
end
