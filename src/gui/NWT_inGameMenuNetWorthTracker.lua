-- NWT_inGameMenuNetWorthTracker
--
-- Converts entries for display and populates entry lists on in game menu
--

NWT_inGameMenuNetWorthTracker = {
    CATEGORIES = {
        FARM_VALUE = 1,
        FARM_HISTORY = 2
    },
    CATEGORY_TEXTS = {
        "ui_farm_value",
        "ui_farm_value_history"
    }

}
NWT_inGameMenuNetWorthTracker.entryData = {}

NWT_inGameMenuNetWorthTracker.NUM_CATEGORIES = #NWT_inGameMenuNetWorthTracker.CATEGORY_TEXTS

-- counters to track current status of sorting
local lineItemSort = 0
local categorySort = 0
local valueSort = 0
local daySort = 1

NWT_inGameMenuNetWorthTracker._mt = Class(NWT_inGameMenuNetWorthTracker, TabbedMenuFrameElement)

function NWT_inGameMenuNetWorthTracker.new(i18n, messageCenter)
    local self = NWT_inGameMenuNetWorthTracker:superClass().new(nil, NWT_inGameMenuNetWorthTracker._mt)

    self.name = "NWT_inGameMenuNetWorthTracker"
    self.i18n = i18n
    self.messageCenter = messageCenter
    self.subCategoryPages = {}
    self.subCategoryTabs = {}
    self.farmValueDelegate = NWT_farmValueDelegate.new()
    self.farmHistoryDelegate = NWT_historyDelegate.new()

    return self
 end

function NWT_inGameMenuNetWorthTracker:onGuiSetupFinished()
    NWT_inGameMenuNetWorthTracker:superClass().onGuiSetupFinished(self)

    self.historyTable:setDataSource(self)
    self.historyTable:setDelegate(self)

    self.entryTable:setDataSource(self)
    self.entryTable:setDelegate(self)

end

function NWT_inGameMenuNetWorthTracker:onFrameOpen(element)
    NWT_inGameMenuNetWorthTracker:superClass().onFrameOpen(self)

    self:hideAllSortIcons()
    self:updateContent()

    self:updateSubCategoryPages(self.CATEGORIES.FARM_VALUE)
    FocusManager:setFocus(self.subCategoryPages[self.CATEGORIES.FARM_VALUE]:getDescendantByName("layout"))
end

function NWT_inGameMenuNetWorthTracker:updateContent()
    self:getEntryTable()
    self:getHistoryTable()

    self.entryTable:reloadData()
    self.historyTable:reloadData()
end

function NWT_inGameMenuNetWorthTracker:getEntryTable()
    self.entryData = self.farmValueDelegate:getFarmEntries()

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

end

function NWT_inGameMenuNetWorthTracker:getHistoryTable()
    self.historyData = self.farmHistoryDelegate:getFarmHistories()
    table.sort(self.historyData, function (a, b) return a.dayId > b.dayId end)

    if self.historyChart ~= nil then
        local chartData = table.clone(self.historyData)
        table.sort(chartData, function (a, b) return a.dayId < b.dayId end)
        self.historyChart:setHistoryData(chartData)
    end
end

function NWT_inGameMenuNetWorthTracker:getNumberOfSections()
    return 1
end

function NWT_inGameMenuNetWorthTracker:getNumberOfItemsInSection(list, section)
    local items = #self.entryData
    if self.subCategoryPaging.state == self.CATEGORIES.FARM_HISTORY then
        items = #self.historyData
    end

    return items
end

function NWT_inGameMenuNetWorthTracker:getTitleForSectionHeader(list, section)
    return "no impl"
end

function NWT_inGameMenuNetWorthTracker:populateCellForItemInSection(list, section, index, cell)
    if self.subCategoryPaging.state == self.CATEGORIES.FARM_VALUE and cell:getAttribute("entryTitle") ~= nil then
        local loc_entryData = self.entryData[index]
        cell:getAttribute("entryTitle"):setText(loc_entryData.entryTitle)

        local entryIcon = cell:getAttribute("entryIcon")
        if loc_entryData.iconFilename ~= nil then
            entryIcon:setImageFilename(loc_entryData.iconFilename)
            entryIcon:setVisible(true)
        else
            entryIcon:setVisible(false)
        end

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

    elseif self.subCategoryPaging.state == self.CATEGORIES.FARM_HISTORY and cell:getAttribute("historyDay") ~= nil then
        -- DebugUtil.printTableRecursively(self.historyData)

        local loc_historyData = self.historyData[index]
        cell:getAttribute("historyDay"):setText(self:getDateString(loc_historyData))
        cell:getAttribute("historyAmount"):setText(g_i18n:formatMoney(loc_historyData.amount, 0, true, true))

    end

end

function NWT_inGameMenuNetWorthTracker:getDateString(historyData)
    return g_i18n:formatPeriod((((historyData.periodId or 0) - 1) % 12), false) -- wtf?
        .. " " .. tostring(historyData.dayInPeriod or 1)
        .. ", " .. tostring(2024 + (historyData.year or 0))
end

function NWT_inGameMenuNetWorthTracker:onClickLineItemSort(entry)
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

function NWT_inGameMenuNetWorthTracker:onClickDaySort(history)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:hideSortIcons()

    local sortFunction
    daySort = (daySort + 1) % 2
    if daySort == 0 then
        self.iconDayAscending:setVisible(true)
        sortFunction = function (a, b) return a.dayId < b.dayId end

    elseif daySort == 1 then
        self.iconDayDescending:setVisible(true)
        sortFunction = function (a, b) return a.dayId > b.dayId end

    end

    table.sort(self.historyData, sortFunction)
    self.historyTable:reloadData()
end

function NWT_inGameMenuNetWorthTracker:hideSortIcons()
    if self.subCategoryPaging.state == self.CATEGORIES.FARM_VALUE then
        self.iconLineItemAscending:setVisible(false)
        self.iconLineItemDescending:setVisible(false)

        self.iconCategoryAscending:setVisible(false)
        self.iconCategoryDescending:setVisible(false)

        self.iconValueAscending:setVisible(false)
        self.iconValueDescending:setVisible(false)
    elseif self.subCategoryPaging.state == self.CATEGORIES.FARM_HISTORY then
        self.iconDayAscending:setVisible(false)
        self.iconDayDescending:setVisible(false)
    end
end

function NWT_inGameMenuNetWorthTracker:hideAllSortIcons()
    self.iconLineItemAscending:setVisible(false)
    self.iconLineItemDescending:setVisible(false)

    self.iconCategoryAscending:setVisible(false)
    self.iconCategoryDescending:setVisible(false)

    self.iconValueAscending:setVisible(false)
    self.iconValueDescending:setVisible(false)

    self.iconDayAscending:setVisible(false)
    self.iconDayDescending:setVisible(false)
end

function NWT_inGameMenuNetWorthTracker:initialize()
    self.subCategoryTabs[self.CATEGORIES.FARM_VALUE] = self.inGameMenuNetWorth
    self.subCategoryTabs[self.CATEGORIES.FARM_HISTORY] = self.inGameMenuNetWorthHistory

    self.subCategoryPages[self.CATEGORIES.FARM_VALUE] = self.inGameMenuNetWorthPage
    self.subCategoryPages[self.CATEGORIES.FARM_HISTORY] = self.inGameMenuNetWorthHistoryPage

    for key = 1, NWT_inGameMenuNetWorthTracker.NUM_CATEGORIES do
        self.subCategoryPaging:addText(tostring(key))

        self.subCategoryTabs[key]:getDescendantByName("background"):setSize(self.subCategoryTabs[key].size[1], self.subCategoryTabs[key].size[2])
        self.subCategoryTabs[key].onClickCallback = function ()
            self:updateSubCategoryPages(key)
        end
    end
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
end

function NWT_inGameMenuNetWorthTracker:updateSubCategoryPages(state)
    for i, _ in ipairs(self.subCategoryPages) do
        self.subCategoryPages[i]:setVisible(false)
        self.subCategoryTabs[i]:setSelected(false)
    end
    self.subCategoryPages[state]:setVisible(true)
    self.subCategoryTabs[state]:setSelected(true)
    self.subCategoryPaging.state = state
    self.entryTable:reloadData()
    self.historyTable:reloadData()
end
