-- NWT_inGameMenuNetWorthTracker
--
-- Converts entries for display and populates entry lists on in game menu
--

NWT_inGameMenuNetWorthTracker = {}
NWT_inGameMenuNetWorthTracker.entryData = {}

-- counters to track current status of sorting
local lineItemSort = 0
local categorySort = 0
local valueSort = 0

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

    self:hideSortIcons()
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

        if entry.category == catCash then
            fCashTotalValue = fCashTotalValue + entry.entryAmount

        elseif entry.category == catEquipment then
            fEquipmentTotalValue = fEquipmentTotalValue + entry.entryAmount

        elseif entry.category == catProperty then
            fPropertyTotalValue = fPropertyTotalValue + entry.entryAmount

        elseif entry.category == catInventory then
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

    local entryCategory = tostring(loc_entryData.category)
    if loc_entryData.subCategory ~= nil
        and loc_entryData.subCategory ~= "" then
        entryCategory = entryCategory .. " (" .. tostring(loc_entryData.subCategory) .. ")"

    end
    cell:getAttribute("entryCategory"):setText(entryCategory)

    local entryDetails = tostring(loc_entryData.details)
    local subCatFill = g_i18n:getText("table_fill")
    if loc_entryData.details ~= nil
        and loc_entryData.subCategory ~= nil
        and loc_entryData.subCategory == subCatFill then
        -- TODO - formats tree saplings funky
        entryDetails = g_i18n:formatVolume(loc_entryData.details, 0)

    end
    cell:getAttribute("entryDetails"):setText(entryDetails)

    cell:getAttribute("entryAmount"):setText(g_i18n:formatMoney(loc_entryData.entryAmount, 0, true, true))
end

function NWT_inGameMenuNetWorthTracker:onClickLineItemSort(entry)
    print("---- onClickLineItemSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:hideSortIcons()

    local sortFunction
    lineItemSort = (lineItemSort + 1) % 2
    if lineItemSort == 0 then
        self.iconLineItemAscending:setVisible(true)
        sortFunction = function (a, b) return string.lower(a.entryTitle) < string.lower(b.entryTitle) end

    elseif lineItemSort == 1 then
        self.iconLineItemDescending:setVisible(true)
        sortFunction = function (a, b) return string.lower(a.entryTitle) > string.lower(b.entryTitle) end

    end

    table.sort(self.entryData, sortFunction)
    self.entryTable:reloadData()
end

function NWT_inGameMenuNetWorthTracker:onClickCategorySort(entry)
    print("---- onClickLineItemSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:hideSortIcons()

    local sortFunction
    categorySort = (categorySort + 1) % 2
    if categorySort == 0 then
        self.iconCategoryAscending:setVisible(true)
        sortFunction = function (a, b)
            return string.lower(a.category .. tostring(a.subCategory)) < string.lower(b.category .. tostring(b.subCategory))
        end

    elseif categorySort == 1 then
        self.iconCategoryDescending:setVisible(true)
        sortFunction = function (a, b)
            return string.lower(a.category .. tostring(a.subCategory)) > string.lower(b.category .. tostring(b.subCategory))
        end

    end

    table.sort(self.entryData, sortFunction)
    self.entryTable:reloadData()
end

function NWT_inGameMenuNetWorthTracker:onClickValueSort(entry)
    print("--- onClickValueSort ---")
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:hideSortIcons()

    local sortFunction
    valueSort = (valueSort + 1) % 2
    if valueSort == 0 then
        self.iconValueAscending:setVisible(true)
        sortFunction = function (a, b) return a.entryAmount < b.entryAmount end

    elseif valueSort == 1 then
        self.iconValueDescending:setVisible(true)
        sortFunction = function (a, b) return a.entryAmount > b.entryAmount end

    end

    table.sort(self.entryData, sortFunction)
    self.entryTable:reloadData()
end


function NWT_inGameMenuNetWorthTracker:hideSortIcons()
        self.iconLineItemAscending:setVisible(false)
        self.iconLineItemDescending:setVisible(false)

        self.iconCategoryAscending:setVisible(false)
        self.iconCategoryDescending:setVisible(false)

        self.iconValueAscending:setVisible(false)
        self.iconValueDescending:setVisible(false)
end
