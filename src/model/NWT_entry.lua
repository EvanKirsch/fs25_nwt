-- NWT_entry
--
-- Data object for table entry information
--

NWT_entry = {}
local NWT_entry_mt = Class(NWT_entry, Object)

InitObjectClass(NWT_entry, "NWT_entry")

function NWT_entry.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or NWT_entry_mt)

    return self
end

function NWT_entry:init(farmId, title, catagory, subCatagory, details, amount)
    self.farmId = farmId
    self.entryTitle = title
    self.catagory = catagory
    self.subCatagory = subCatagory
    self.details = details
    self.entryAmount = amount
end
