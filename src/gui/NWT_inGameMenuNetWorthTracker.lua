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

    local entryCatagory = tostring(loc_entryData.catagory)
    if loc_entryData.subCatagory ~= nil
        and loc_entryData.subCatagory ~= "" then
        entryCatagory = entryCatagory .. " (" .. tostring(loc_entryData.subCatagory) .. ")"

    end
    cell:getAttribute("entryCatagory"):setText(entryCatagory)

    local entryDetails = tostring(loc_entryData.details)
    local subCatFill = g_i18n:getText("table_fill")
    if loc_entryData.details ~= nil
        and loc_entryData.subCatagory ~= nil
        and loc_entryData.subCatagory == subCatFill then
        -- TODO - formats tree saplings funky
        entryDetails = g_i18n:formatVolume(loc_entryData.details, 0)

    end
    cell:getAttribute("entryDetails"):setText(entryDetails)

    cell:getAttribute("entryAmount"):setText(g_i18n:formatMoney(loc_entryData.entryAmount, 0, true, true))
end

local lineItemSort = 0
local catagorySort = 0
local detailsSort = 0
local valueSort = 0

-- empty table of fuctions to build sorter
local sortFunctions = {}

function NWT_inGameMenuNetWorthTracker:onClickLineItemSort(entry)
    print("---- onClickLineItemSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

    lineItemSort = (lineItemSort + 1) % 3
    if lineItemSort == 0 then
        self.iconLineItemAscending:setVisible(false)
        self.iconLineItemDescending:setVisible(false)

    elseif lineItemSort == 1 then
        self.iconLineItemAscending:setVisible(true)
        self.iconLineItemDescending:setVisible(false)

    elseif lineItemSort == 2 then
        self.iconLineItemAscending:setVisible(false)
        self.iconLineItemDescending:setVisible(true)

    end
end

function NWT_inGameMenuNetWorthTracker:onClickCatagorySort(entry)
    print("---- onClickLineItemSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

    catagorySort = (catagorySort + 1) % 3
    if catagorySort == 0 then
        self.iconCatagoryAscending:setVisible(false)
        self.iconCatagoryDescending:setVisible(false)

    elseif catagorySort == 1 then
        self.iconCatagoryAscending:setVisible(true)
        self.iconCatagoryDescending:setVisible(false)

    elseif catagorySort == 2 then
        self.iconCatagoryAscending:setVisible(false)
        self.iconCatagoryDescending:setVisible(true)

    end
end

function NWT_inGameMenuNetWorthTracker:onClickDetailsSort(entry)
    print("--- onClickDetailsSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

    detailsSort = (detailsSort + 1) % 3
    if detailsSort == 0 then
        self.iconDetailsAscending:setVisible(false)
        self.iconDetailsDescending:setVisible(false)

    elseif detailsSort == 1 then
        self.iconDetailsAscending:setVisible(true)
        self.iconDetailsDescending:setVisible(false)

    elseif detailsSort == 2 then
        self.iconDetailsAscending:setVisible(false)
        self.iconDetailsDescending:setVisible(true)

    end

end

function NWT_inGameMenuNetWorthTracker:onClickValueSort(entry)
    print("--- onClickValueSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

    valueSort = (valueSort + 1) % 3
    if valueSort == 0 then
        self.iconValueAscending:setVisible(false)
        self.iconValueDescending:setVisible(false)

    elseif valueSort == 1 then
        self.iconValueAscending:setVisible(true)
        self.iconValueDescending:setVisible(false)

    elseif valueSort then
        self.iconValueAscending:setVisible(false)
        self.iconValueDescending:setVisible(true)

    end

end
