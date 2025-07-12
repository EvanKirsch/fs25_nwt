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

    local fNetWorthTotalValue = 0
    for _, entry in pairs(self.entryData) do 
        fNetWorthTotalValue = fNetWorthTotalValue + entry.entryAmount
    end 

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
    cell:getAttribute("entryCatagory"):setText(loc_entryData.catagory)
    cell:getAttribute("entryDetails"):setText(loc_entryData.details)
    cell:getAttribute("entryAmount"):setText(g_i18n:formatMoney(loc_entryData.entryAmount, 0, true, true))
end
