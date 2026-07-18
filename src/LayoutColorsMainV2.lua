local pluginTable = select(3,...)
local pluginHandle = select(4,...)

local undoer --Undo handle. Created in main func.
local colorListAmount = 0 --Gets it real value in Init().

function pluginTable:Init()
    self.layouts = DataPool().layouts:Children()
    self.fixtureTypes = {}
    colorListAmount = #self.colorList

    local function faultyHandel(layoutHandle)--If you change things in the patch the layout object link can break. Solved by selecting the layout
        local faulty = false
        local selectedLayout = SelectedLayout()
        ::checkAgain::
        if  not faulty then
            if layoutHandle.object == nil then
                ErrPrintf("Faulty fixture handle on layout element "..layoutHandle.name..".")
                ErrPrintf("Trying to resolve.")
                for _, value in ipairs(self.layouts) do
                    CmdIndirectWait("Select "..value)
                end
                CmdIndirectWait("Select "..selectedLayout)
                faulty = true
                goto checkAgain
            else
                faulty = false
            end
        else
            if layoutHandle.object == nil then
                ErrPrintf("Could not resolve faulty fixture handle for layout element "..layoutHandle.name..".")
            else
                Printf("Resolved.")
                faulty = false
            end
        end
        
        return faulty
    end

    local function collectFixtureInformation(layoutHandle, fixtureHandel, fixtureTypeTable)

        local function collectFixtureType()
            local subFix = fixtureHandel
            local counter = 1
            while true do
                if not (subFix.fixturetype == nil) then
                    return subFix.fixturetype, true
                elseif counter >= 8 then
                    ErrPrintf(subFix.." have to many layers!!!")
                    break
                else
                    subFix = subFix:Parent()
                    counter = counter + 1
                end
            end
        end

        local function sortFxtureType(fixtureType, notNil)
            local collector = {handle = fixtureType,layoutElements = {layoutHandle}}
            if notNil then
                if #fixtureTypeTable == 0 then
                    table.insert(fixtureTypeTable, collector)
                else
                    for index, value in ipairs(fixtureTypeTable) do
                        if value.handle == fixtureType  then
                            table.insert(value.layoutElements, layoutHandle)
                            break
                        elseif #fixtureTypeTable == index then
                            table.insert(fixtureTypeTable, collector)
                        end
                    end
                end
            end
        end

        sortFxtureType(collectFixtureType())
    end

    -- Collect layout object information
    for _, layout in ipairs(self.layouts) do
        for _, layoutElement in ipairs(layout) do
            if layoutElement.assigntype == "Fixture" then
                if not faultyHandel(layoutElement) then
                    collectFixtureInformation(layoutElement, layoutElement.object, self.fixtureTypes)
                end
            end
        end
    end

    -- Create dummy fixtures in the first indexed layout for UI references
    for _, layout in ipairs(self.layouts) do
        local layout = layout
        for _, fixtureType in ipairs(self.fixtureTypes) do
            layout:Acquire("Element")
            coroutine.yield(0.01)
            fixtureType.dummy = {handle = layout[#layout]}
        end
        break
    end
end

function pluginTable:BorderColorAssigner()--Assign a color to the fixturetypes depending on if they have stored values or not.

    local function assignColor(fixtureType, colorIndex, colorCode, skip)
        fixtureType.color = {assignedColor = colorIndex, assignedColorCode = colorCode or "808080FF", skipColor = skip or 0}
    end

    local offsetList = 0
    local listIndex = 1
    local function assignFromList(fixtureType)
        local colorIndex = listIndex - colorListAmount * offsetList
        if colorIndex >= colorListAmount then
            offsetList = offsetList +1
        end
        assignColor(fixtureType, colorIndex)
        listIndex = listIndex + 1
    end
    
    if pluginHandle:Parent()[4] and self.storedColorList then
        for index, value in ipairs(self.fixtureTypes) do
            local fixType = value
            for index, value in ipairs(self.storedColorList) do
                if value.fixtureType.name == fixType.handle.name then
                    assignColor(fixType, value.color.assignedColor, value.color.assignedColorCode, value.color.skipColor)
                    break
                else
                    if index == #self.storedColorList then
                        assignFromList(fixType)
                    end
                end
            end
        end
    else
        for index, value in ipairs(self.fixtureTypes) do
            assignFromList(value)
        end
    end
end

function pluginTable:SelectorColorList()--Create a list for the UI
    local list = {}
    for index, value in ipairs(self.colorList) do
        local item = {value.name, value.colCode}
        table.insert(list, item)
    end
    do
        local item = {"Custom", "FFFFFFFF"}
        table.insert(list, item)
    end
    return list
end

function pluginTable:LoadValuesUI(fixtureType)--Load the values from BorderColorAssigner() in the UI.
    fixtureType.color.UIHandels.selector:SelectListItemByIndex(fixtureType.color.assignedColor)
    fixtureType.color.UIHandels.skip.state = fixtureType.color.skipColor
    fixtureType.dummy.handle.bordercolor = fixtureType.color.UIHandels.selector:GetListItemValueStr(fixtureType.color.assignedColor)
    if fixtureType.color.skipColor == 1 then
        fixtureType.color.UIHandels.selector.interactive = "No"
        fixtureType.color.UIHandels.selector.backcolor = "RadioItemButton.SelectedBackground"
        fixtureType.color.UIHandels.name.backcolor = "RadioItemButton.SelectedBackground"
        fixtureType.color.UIHandels.input.showvalue = "No"
    end

    if fixtureType.color.assignedColor > colorListAmount and fixtureType.color.skipColor == 0 then
        fixtureType.color.UIHandels.input.interactive = "Yes"
    else
        fixtureType.color.UIHandels.input.interactive = "No"
    end
end

function pluginTable:UpdateUIColor()--Part of loop to update the values depending on input in UI.
    local function updateValues(fixtureType)
        local colorIndex = fixtureType.color.UIHandels.selector:GetListSelectedItemIndex()
        if fixtureType.color.UIHandels.skip.state == 1 then
            fixtureType.color.UIHandels.selector.interactive = "No"
            fixtureType.color.UIHandels.selector.backcolor = "RadioItemButton.SelectedBackground"
            fixtureType.color.UIHandels.name.backcolor = "RadioItemButton.SelectedBackground"
            fixtureType.color.UIHandels.input.showvalue = "No"
            fixtureType.dummy.handle.bordercolor = "808080FF"
        else
            fixtureType.color.UIHandels.selector.interactive = "Yes"
            fixtureType.color.UIHandels.selector.backcolor = "Button.Background"
            fixtureType.color.UIHandels.name.backcolor = "UIObject.Background"
            fixtureType.color.UIHandels.input.showvalue = "Yes"
        end

        if colorIndex <= colorListAmount and fixtureType.color.UIHandels.skip.state == 0 then
            fixtureType.dummy.handle.bordercolor = fixtureType.color.UIHandels.selector:GetListItemValueStr(colorIndex)
        end

        if colorIndex > colorListAmount and fixtureType.color.UIHandels.skip.state == 0 then
            fixtureType.color.UIHandels.input.interactive = "Yes"
        else
            fixtureType.color.UIHandels.input.interactive = "No"
        end
    end

    for index, value in ipairs(self.fixtureTypes) do
        updateValues(value)
    end
end

function pluginTable:UpdateFixtureTable()--Update the fixtureTypes table with selected values.
    local function updateValues(fixtureType)
        local colorIndex = fixtureType.color.UIHandels.selector:GetListSelectedItemIndex()
        fixtureType.dummy.handle.bordercolor = fixtureType.color.UIHandels.selector:GetListItemValueStr(colorIndex)
        fixtureType.color.assignedColorCode = fixtureType.dummy.handle.bordercolor
        fixtureType.color.assignedColor = colorIndex
        fixtureType.color.skipColor = fixtureType.color.UIHandels.skip.state
    end

    for index, value in ipairs(self.fixtureTypes) do
        updateValues(value)
    end
end

function pluginTable:AssignBorderColor()--Assign the colors to the real fixturetypes in the layouts.
    -- Collect information for the assign commands
    local cmdCollect = {}
    for _, value in ipairs(self.layouts) do
        local layout = value
        local layoutStr = tostring(value)
        cmdCollect[layoutStr] = {}
        for _, value in ipairs(self.fixtureTypes) do
            local fixType = value
            local fixTypeStr = tostring(value.handle)
            for _, value in ipairs(value.layoutElements) do
                if value:Parent() == layout and fixType.color.skipColor == 0 then
                    if cmdCollect[layoutStr][fixTypeStr] == nil then
                        cmdCollect[layoutStr][fixTypeStr] = {color = fixType.color.assignedColorCode, objects = {} }
                    end
                    table.insert(cmdCollect[layoutStr][fixTypeStr].objects, tonumber(value.no))
                elseif fixType.color.skipColor == 1 then
                    if cmdCollect[layoutStr]["skip"] == nil then
                        cmdCollect[layoutStr]["skip"] = {objects = {} }
                    end
                    table.insert(cmdCollect[layoutStr]["skip"].objects, tonumber(value.no))
                end
            end
        end
    end

    --Prepare commands and executing them. Doing it thru commands to be able to oops
    local cmdString = ""
    local cmdStrings = {}
    local function stringStart(layout, layoutObject)
        local string = string.format("Set %s.%s",layout, layoutObject)
        return string
    end

    local function stringCollect(stringInput, layoutObject)
        local string = string.format("%s + %d", stringInput, layoutObject)
        return string
    end

    local function stringEnd(stringInput, color, fixTypeKey )
        local string = ""
        if fixTypeKey == "skip" then
            string = string.format("%s Property 'visibilityborder' 'Hidden'", stringInput)
        else
            string = string.format("%s Property 'bordercolor' '%s' 'visibilityborder' 'Visible'", stringInput, color)
        end
        
        return string
    end

    for key, value in pairs(cmdCollect) do
        local layout = key
        for key, value in pairs(value) do
            local counter = 0
            local threshold = 40
            local fixType = value
            local fixTypeKey = key
            for index, layoutObject in ipairs(fixType.objects) do
                if index - counter * threshold == 1 then
                    cmdString = stringStart(layout, layoutObject)
                elseif index - counter * threshold >= threshold then
                    cmdString = stringCollect(cmdString, layoutObject)
                    cmdString = stringEnd(cmdString, fixType.color, fixTypeKey)
                    counter = counter + 1
                    table.insert(cmdStrings, cmdString)
                else
                    cmdString = stringCollect(cmdString, layoutObject)
                end
            end
            cmdString = stringEnd(cmdString, fixType.color, fixTypeKey)
            table.insert(cmdStrings, cmdString)
        end
    end

    for _, value in ipairs(cmdStrings) do
        CmdIndirectWait(value,undoer)
    end
end

function pluginTable:WriteToComponent()--Create component for permanent storage of colors.
    local contentString = ""
    local plugin = pluginHandle:Parent()

    --Create component for permanent storage of table if it don't exist.
    if not plugin[4] then
        plugin:Insert(4, "ComponentLua", undoer, 1)
        plugin[4].name = "ColorStore"
    end

    --Create table in component
    local function stringCollect(stringInput, fixtureType)
        local string = string.format("%s\n\t{\n\tfixtureType = {name = '%s'},\n\tcolor = {\n\t\tassignedColor = %d,\n\t\tassignedColorCode = '%s',\n\t\tskipColor = %d\n\t\t}\n\t},",
        stringInput, fixtureType.handle.name, fixtureType.color.assignedColor, fixtureType.color.assignedColorCode, fixtureType.color.skipColor or 0)
        return string
    end

    contentString = "local pluginTable = select(3,...)\nlocal pluginHandle = select(4,...)\n\npluginTable.storedColorList = {"
    for index, value in ipairs(self.fixtureTypes) do
        contentString = stringCollect(contentString, value)
    end
    contentString = contentString.."\n}"

    plugin[4]:Set("filecontent", contentString)
end

function pluginTable:Stop()--Removes dummy fixtures
    for index, value in ipairs(self.fixtureTypes) do
        Echo(string.format("Deleting dummy %d!",index))
        value.dummy.handle:Parent():Delete(value.dummy.handle.no)
    end
end

local function main()
    -- Set depending on user input
    pluginTable.cancel = false
    pluginTable.continue = false
    undoer = CreateUndo("Layout Colors")
    
    pluginTable:Init()
    pluginTable:BorderColorAssigner()
    pluginTable:LayoutColorUI()

    repeat
        pluginTable:UpdateUIColor()
        coroutine.yield(0.1)
    until pluginTable.continue
    if not pluginTable.cancel then
        --Needs to be called from main func.
        --Otherwise it won't load until restart or update of main component.
        pluginTable:WriteToComponent()
    end
    pluginTable:Stop()
    CloseUndo(undoer)
    
end
return main