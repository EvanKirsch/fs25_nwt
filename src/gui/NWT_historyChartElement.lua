-- NWT_historyChartElement
--
-- Custom GuiElement that draws a line chart of net worth history over time
--

NWT_historyChartElement = {}
NWT_historyChartElement.LINE_WIDTH = 2
NWT_historyChartElement.LINE_COLOR = {0.2, 0.85, 0.3, 1}
NWT_historyChartElement.LABEL_TEXT_SIZE = 12
NWT_historyChartElement.LABEL_PADDING = 4
NWT_historyChartElement.BORDER_COLOR = {1, 1, 1, 0.4}
NWT_historyChartElement.BORDER_WIDTH = 1
NWT_historyChartElement.GRID_LINE_COLOR = {1, 1, 1, 0.12}
NWT_historyChartElement.GRID_LINE_WIDTH = 1
NWT_historyChartElement.GRID_ROWS = 4
NWT_historyChartElement.GRID_COLS = 6

local NWT_historyChartElement_mt = Class(NWT_historyChartElement, GuiElement)
Gui.registerGuiElement("NWT_historyChart", NWT_historyChartElement)

function NWT_historyChartElement.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or NWT_historyChartElement_mt)

    self.historyData = {}

    return self
end

-- expects historyData sorted ascending by dayId
function NWT_historyChartElement:setHistoryData(historyData)
    self.historyData = historyData or {}
end

function NWT_historyChartElement:drawGrid(x, y, w, h)
    local gc = NWT_historyChartElement.GRID_LINE_COLOR
    local gridLineWidth = NWT_historyChartElement.GRID_LINE_WIDTH * g_pixelSizeY

    for i = 1, NWT_historyChartElement.GRID_ROWS - 1 do
        local ly = y + (i / NWT_historyChartElement.GRID_ROWS) * h
        drawLine2D(x, ly, x + w, ly, gridLineWidth, gc[1], gc[2], gc[3], gc[4])
    end

    for i = 1, NWT_historyChartElement.GRID_COLS - 1 do
        local lx = x + (i / NWT_historyChartElement.GRID_COLS) * w
        drawLine2D(lx, y, lx, y + h, gridLineWidth, gc[1], gc[2], gc[3], gc[4])
    end
end

function NWT_historyChartElement:drawBorder(x, y, w, h)
    local bc = NWT_historyChartElement.BORDER_COLOR
    local borderWidth = NWT_historyChartElement.BORDER_WIDTH * g_pixelSizeY

    drawLine2D(x, y, x + w, y, borderWidth, bc[1], bc[2], bc[3], bc[4])
    drawLine2D(x, y + h, x + w, y + h, borderWidth, bc[1], bc[2], bc[3], bc[4])
    drawLine2D(x, y, x, y + h, borderWidth, bc[1], bc[2], bc[3], bc[4])
    drawLine2D(x + w, y, x + w, y + h, borderWidth, bc[1], bc[2], bc[3], bc[4])
end

function NWT_historyChartElement:draw(clipX1, clipY1, clipX2, clipY2)
    NWT_historyChartElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

    local x, y = self.absPosition[1], self.absPosition[2]
    local w, h = self.absSize[1], self.absSize[2]

    self:drawGrid(x, y, w, h)
    self:drawBorder(x, y, w, h)

    local data = self.historyData
    if data == nil or #data < 2 then
        return
    end

    local minDay, maxDay = data[1].dayId, data[1].dayId
    local minAmt, maxAmt = data[1].amount, data[1].amount
    for _, entry in ipairs(data) do
        minDay = math.min(minDay, entry.dayId)
        maxDay = math.max(maxDay, entry.dayId)
        minAmt = math.min(minAmt, entry.amount)
        maxAmt = math.max(maxAmt, entry.amount)
    end

    local dayRange = math.max(maxDay - minDay, 1)
    local amtRange = math.max(maxAmt - minAmt, 1)

    local function toScreen(entry)
        local px = x + ((entry.dayId - minDay) / dayRange) * w
        local py = y + ((entry.amount - minAmt) / amtRange) * h
        return px, py
    end

    local c = NWT_historyChartElement.LINE_COLOR
    local lineWidth = NWT_historyChartElement.LINE_WIDTH * g_pixelSizeY

    local prevX, prevY = toScreen(data[1])
    for i = 2, #data do
        local curX, curY = toScreen(data[i])
        drawLine2D(prevX, prevY, curX, curY, lineWidth, c[1], c[2], c[3], c[4])
        prevX, prevY = curX, curY
    end

    local labelSize = NWT_historyChartElement.LABEL_TEXT_SIZE * g_pixelSizeY
    local labelPadding = NWT_historyChartElement.LABEL_PADDING * g_pixelSizeY

    setTextBold(false)
    setTextColor(1, 1, 1, 0.6)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(x + w, y + h - labelSize - labelPadding, labelSize, g_i18n:formatMoney(maxAmt, 0, true, true))
    renderText(x + w, y + labelPadding, labelSize, g_i18n:formatMoney(minAmt, 0, true, true))

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
end
