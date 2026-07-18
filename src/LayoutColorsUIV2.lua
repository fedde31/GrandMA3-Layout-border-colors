local pluginName = select(1, ...)
local componentName = select(2, ...)
local pluginTable = select(3, ...)
local pluginHandle = select(4, ...)

function pluginTable:LayoutColorUI()

    local displayIndex = Obj.Index(GetFocusDisplay())
    if displayIndex > 5 then
        displayIndex = 1
    end
    local display = GetDisplayByIndex(displayIndex)

    local baseLayer = GetFocusDisplay().ScreenOverlay:Append("BaseInput")
        baseLayer.Name = "LayoutColorSelector"
        baseLayer.W = 800
        baseLayer.MaxSize = string.format("%s,%s", display.W * 0.8, display.H * 0.6)
        baseLayer.MinSize = "500,300"
        baseLayer.Columns = 1
        baseLayer.Rows = 2
        baseLayer[1][1].SizePolicy = "Fixed"
        baseLayer[1][1].Size = "60"
        baseLayer[1][2].SizePolicy = "Stretch"
        baseLayer.PluginComponent = pluginHandle
        baseLayer.AutoClose = "No"
        baseLayer.CloseOnEscape = "Yes"
        baseLayer:OverlaySetCloseCallback("CancelButtonClicked")


    local titleBar = baseLayer:Append("TitleBar")
        titleBar.Columns = 2
        titleBar.Rows = 1
        titleBar.Anchors = "0,0"
        titleBar[2][2].SizePolicy = "Fixed"
        titleBar[2][2].Size = 50
        titleBar.Texture = "corner2"

    local titleBarIcon = titleBar:Append("TitleButton")
        titleBarIcon.Texture = "corner1"
        titleBarIcon.Anchors = "0,0"
        titleBarIcon.Icon = "object_colpick"
        titleBarIcon.Text = "Select fixture type colors"

    local titleBarCloseButton = titleBar:Append("CloseButton")
        titleBarCloseButton.Anchors = "1,0"
        titleBarCloseButton.Texture = "corner2"

    local dialogFrame = baseLayer:Append("DialogFrame")
        dialogFrame.H = "100%"
        dialogFrame.W = "100%"
        dialogFrame.Columns = 1
        dialogFrame.Rows = 2
        dialogFrame.Anchors = "0,1"
        dialogFrame[1][1].SizePolicy = "Stretch"
        dialogFrame[1][2].SizePolicy = "Fixed"
        dialogFrame[1][2].Size = 80

    local scrollContainer = dialogFrame:Append("ScrollContainer")
        scrollContainer.Columns = 2
        scrollContainer.Rows = 1
        scrollContainer[2][2].SizePolicy = "Content"
        scrollContainer.H = "95%"

    local scrollBox = scrollContainer:Append("ScrollBox")
    	scrollBox.Name = "mybox"
 
	local scrollBar = scrollContainer:Append("ScrollBarV")
    	scrollBar.ScrollTarget = "../mybox"
    	scrollBar.Anchors = '1,0'

    local colorSelectorGrid = scrollBox:Append("UILayoutGrid")
        colorSelectorGrid.Columns = 4
        colorSelectorGrid.Rows = #self.fixtureTypes
        colorSelectorGrid.Anchors = "0,0"
        colorSelectorGrid.H = "100%"
        colorSelectorGrid.W = "100%"
        colorSelectorGrid.Padding = "10,15"
        colorSelectorGrid[2][3].SizePolicy = "Stretch"
        colorSelectorGrid[2][3].Size = 0.75
        colorSelectorGrid[2][4].SizePolicy = "Stretch"
        colorSelectorGrid[2][4].Size = 0.55

    local nameUIObject = {}
    local colorInput = {}
    local colorSelector = {}
    local colorSkip = {}

    for index, value in ipairs(self.fixtureTypes) do
        
        colorSelectorGrid[1][index].SizePolicy = "Fixed"
        colorSelectorGrid[1][index].Size = 40

        nameUIObject[index] = colorSelectorGrid:Append("UIObject")
        nameUIObject[index].Text = value.handle.name
        nameUIObject[index].Name = "FixtureType "..index
        nameUIObject[index].Anchors = string.format("0,%d+", index - 1)
        nameUIObject[index].HasHover = "No"
        nameUIObject[index].TextAutoAdjust = "No"
        nameUIObject[index].TextalignmentH = "Left"
        nameUIObject[index].Padding = "5,0"
        nameUIObject[index].Margin = "2,2"

        colorInput[index] = colorSelectorGrid:Append("ColorPropertyInput")
        colorInput[index].Anchors = string.format("1,%d+",index - 1)
        colorInput[index].Margin = "2,2"
        colorInput[index].Target = value.dummy.handle
        colorInput[index].Property = "BorderColor"
        colorInput[index].ShowLabel = "No"

        colorSelector[index] = colorSelectorGrid:Append("SwipeButton")
        colorSelector[index].ShowLabel = "No"
        colorSelector[index].Anchors = string.format("2,%d+",index - 1)
        colorSelector[index].Margin = "2,2"
        colorSelector[index]:AddListStringItems(self:SelectorColorList())

        colorSkip[index] = colorSelectorGrid:Append("CheckBox")
        colorSkip[index].Anchors = string.format("3,%d+",index - 1)
        colorSkip[index].Margin = "2,2"
        colorSkip[index].Text = "Skip"
        colorSkip[index].PluginComponent = pluginHandle
        colorSkip[index].Clicked = "CheckboxClicked"
        colorSkip[index].Name = "Checkbox "..index

        coroutine.yield(0.01)
        value.color.UIHandels = {name = nameUIObject[index], input = colorInput[index], selector = colorSelector[index], skip = colorSkip[index]}
        self:LoadValuesUI(value)
    end

    local buttonGrid = dialogFrame:Append("UILayoutGrid")
        buttonGrid.Columns = 2
        buttonGrid.Rows = 1
        buttonGrid.H = "100%"
        buttonGrid.Anchors = "0,1"
        buttonGrid.Padding = "0,0"
        buttonGrid.Margin = "0,20,0,0"

    local applyButton = buttonGrid:Append("Button")
        applyButton.Anchors = "0,0"
        applyButton.Textshadow = "1"
        applyButton.HasHover = "Yes"
        applyButton.TextalignmentH = "Center"
        applyButton.Text = "Apply"
        applyButton.PluginComponent = pluginHandle
        applyButton.Clicked = "ApplyButtonClicked"
        applyButton.BackColor = "Button.BackgroundPlease"
        applyButton.Focus = "WantsFocus"

    local cancelButton = buttonGrid:Append("Button")
        cancelButton.Anchors = "1,0"
        cancelButton.Textshadow = "1"
        cancelButton.HasHover = "Yes"
        cancelButton.TextalignmentH = "Center"
        cancelButton.Text = "Cancel"
        cancelButton.PluginComponent = pluginHandle
        cancelButton.Clicked = "CancelButtonClicked"
        cancelButton.BackColor = "Button.BackgroundClear"

    function self.CheckboxClicked(caller)
        if caller.state == 1 then
            caller.state = 0
        else
            caller.state = 1
        end
    end

    function self.CancelButtonClicked(caller)
        self.cancel = true
        self.continue = true
        GetFocusDisplay().ScreenOverlay:ClearUIChildren()
    end

    function self.ApplyButtonClicked(caller)
        self:UpdateFixtureTable()
        self:AssignBorderColor()
        self.cancel = false
        self.continue = true
        GetFocusDisplay().ScreenOverlay:ClearUIChildren()
    end

    coroutine.yield(0.1)
    FindBestFocus(applyButton)
end