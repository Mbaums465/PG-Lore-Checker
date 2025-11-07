#Requires AutoHotkey v2.0
#SingleInstance Force

; Modern GUI for Project Gorgon Lore Report Analysis
global MainGui := ""
global LoreData := Map()
global FilteredData := []
global CurrentSort := {Column: "", Direction: ""}
global DefaultPath := "C:\Users\" . A_UserName . "\AppData\LocalLow\Elder Game\Project Gorgon\Books"

; Initialize GUI
CreateMainGui()

CreateMainGui() {
    global MainGui
    
    MainGui := Gui("+Resize", "Project Gorgon Lore XP Analyzer")
    MainGui.SetFont("s10", "Segoe UI")
    MainGui.BackColor := "0xF0F0F0"
    
    ; Title
    MainGui.SetFont("s14 Bold")
    MainGui.Add("Text", "x20 y20 w960 Center", "Lore XP Source Analyzer")
    MainGui.SetFont("s10", "Segoe UI")
    
    ; File Selection Section
    MainGui.Add("GroupBox", "x20 y60 w960 h80", "File Selection")
    MainGui.Add("Text", "x40 y85", "Skill Report File:")
    FilePathEdit := MainGui.Add("Edit", "x40 y110 w780 vFilePath ReadOnly", "")
    BrowseBtn := MainGui.Add("Button", "x830 y110 w130 h25", "Browse...")
    BrowseBtn.OnEvent("Click", (*) => SelectFile())
    
    ; Filter Section
    MainGui.Add("GroupBox", "x20 y150 w960 h120", "Filters")
    MainGui.Add("Text", "x40 y175", "Search:")
    SearchEdit := MainGui.Add("Edit", "x100 y172 w250 vSearchText")
    SearchEdit.OnEvent("Change", (*) => FilterData())
    
    MainGui.Add("Text", "x370 y175", "Source:")
    SourceDDL := MainGui.Add("DropDownList", "x430 y172 w150 vSourceFilter", ["All", "Both", "User Only", "Wiki Only"])
    SourceDDL.Choose(1)
    SourceDDL.OnEvent("Change", (*) => FilterData())
    
    MainGui.Add("Text", "x40 y210", "Category:")
    CategoryDDL := MainGui.Add("DropDownList", "x110 y207 w240 vCategoryFilter", ["All", "World Interactions", "Favors/Quests", "Hang Outs", "Recipes"])
    CategoryDDL.Choose(1)
    CategoryDDL.OnEvent("Change", (*) => FilterData())
    
    ClearBtn := MainGui.Add("Button", "x600 y207 w100 h25", "Clear Filters")
    ClearBtn.OnEvent("Click", (*) => ClearFilters())
    
    ; Statistics Section
    MainGui.Add("GroupBox", "x20 y280 w960 h80", "Progress Summary")
    StatsText := MainGui.Add("Text", "x40 y305 w920 h45 vStatsText", "")
    
    ; Results Section
    MainGui.Add("GroupBox", "x20 y370 w960 h310", "Lore XP Sources")
    
    ; ListView with columns - no Owner drawn for multiline support
    LV := MainGui.Add("ListView", "x30 y395 w940 h270 vLoreList Grid", ["Source Name", "Category", "Found In", "Location", "Hint"])
    LV.ModifyCol(1, 280)
    LV.ModifyCol(2, 110)
    LV.ModifyCol(3, 80)
    LV.ModifyCol(4, 100)
    LV.ModifyCol(5, 350)
    
    ; Add tooltip support for full hints
    LV.OnEvent("Click", ShowHintTooltip)
    LV.OnEvent("DoubleClick", ShowHintDialog)
    
    ; Status Bar
    StatusText := MainGui.Add("Text", "x20 y690 w960 vStatus", "Ready. Please select a skill report file. (Double-click a row to see full hint)")
    
    MainGui.OnEvent("Size", GuiSize)
    MainGui.OnEvent("Close", (*) => ExitApp())
    MainGui.Show("w1000 h730")
}

ShowHintTooltip(*) {
    global MainGui, FilteredData
    LV := MainGui["LoreList"]
    RowNumber := LV.GetNext()
    
    if (RowNumber > 0 && RowNumber <= FilteredData.Length) {
        hint := FilteredData[RowNumber].FullHint
        if (hint != "")
            ToolTip(hint)
        else
            ToolTip()
    }
}

ShowHintDialog(*) {
    global MainGui, FilteredData
    LV := MainGui["LoreList"]
    RowNumber := LV.GetNext()
    
    if (RowNumber > 0 && RowNumber <= FilteredData.Length) {
        item := FilteredData[RowNumber]
        hint := item.FullHint
        if (hint != "") {
            MsgBox("Source: " . item.Name . "`n`nHint:`n" . hint, "Full Hint", 64)
        }
    }
    ToolTip()
}

SelectFile() {
    global DefaultPath, MainGui
    
    SelectedFile := FileSelect(3, DefaultPath, "Select Skill Report File", "Text Files (*.txt)")
    
    if (SelectedFile = "")
        return
    
    MainGui["FilePath"].Value := SelectedFile
    MainGui["Status"].Value := "Loading file and scraping wiki..."
    
    SetTimer(() => ProcessData(SelectedFile), -100)
}

ProcessData(FilePath) {
    global MainGui, LoreData
    
    try {
        LoreData := Map()
        LoreData.CaseSense := "Off"
        
        ; Helper function to normalize for matching
        NormalizeKey := (str) => Trim(RegExReplace(StrLower(str), "\s+", " "))
        
        UserData := ParseUserFile(FilePath)
        
        MainGui["Status"].Value := "Scraping wiki data..."
        WikiData := ScrapeWiki()
        
        ; First pass: Add all user items with normalized keys
        for Item, Info in UserData {
            NormKey := NormalizeKey(Item)
            if !LoreData.Has(NormKey)
                LoreData[NormKey] := {User: false, Wiki: false, Category: "", Location: "", Hint: "", OriginalKey: Item}
            LoreData[NormKey].User := true
            if (Info.HasOwnProp("Category"))
                LoreData[NormKey].Category := Info.Category
        }
        
        ; Second pass: Add wiki items using normalized keys
        for Item, Info in WikiData {
            NormKey := NormalizeKey(Item)
            if !LoreData.Has(NormKey) {
                ; New item not in user file, use wiki's capitalization
                LoreData[NormKey] := {User: false, Wiki: true, Category: Info.Category, Location: Info.Location, Hint: Info.Hint, OriginalKey: Item}
            } else {
                ; Item exists in user data, just add wiki info
                LoreData[NormKey].Wiki := true
                if (Info.HasOwnProp("Category") && LoreData[NormKey].Category = "")
                    LoreData[NormKey].Category := Info.Category
                if (Info.HasOwnProp("Location"))
                    LoreData[NormKey].Location := Info.Location
                if (Info.HasOwnProp("Hint"))
                    LoreData[NormKey].Hint := Info.Hint
            }
        }
        
        FilterData()
        UpdateStats()
        MainGui["Status"].Value := "Loaded " . LoreData.Count . " unique lore XP sources. (Double-click a row to see full hint)"
        
    } catch as err {
        MsgBox("Error processing data: " . err.Message, "Error", 16)
        MainGui["Status"].Value := "Error: " . err.Message
    }
}

ParseUserFile(FilePath) {
    Items := Map()
    Items.CaseSense := "Off"
    
    FileContent := FileRead(FilePath)
    Lines := StrSplit(FileContent, "`n", "`r")
    
    CurrentCategory := ""
    InSection := false
    
    for Line in Lines {
        Line := Trim(Line)
        if (Line = "")
            continue
        
        ; Detect section headers
        if (InStr(Line, "Sources of Lore XP:"))
            InSection := true
        else if (InStr(Line, "Favors and Quests:")) {
            CurrentCategory := "Favors/Quests"
            continue
        }
        else if (InStr(Line, "Hang Outs:")) {
            CurrentCategory := "Hang Outs"
            continue
        }
        else if (InStr(Line, "Recipes:")) {
            CurrentCategory := "Recipes"
            continue
        }
        else if (InStr(Line, "XP from")) {
            ; End of sections
            break
        }
        
        ; Parse items (they don't have colons at the end typically)
        if (CurrentCategory != "" && Line != "" && !InStr(Line, ":") || (CurrentCategory = "Hang Outs" && InStr(Line, ":"))) {
            ; Skip if line ends with colon (it's a section header)
            if (SubStr(Line, -1) = ":")
                continue
            ; This is an item
            Items[Line] := {Category: CurrentCategory}
        }
    }
    
    return Items
}

ScrapeWiki() {
    Items := Map()
    Items.CaseSense := "Off"
    
    try {
        ; Use WinHTTP COM object to fetch the page
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", "https://wiki.projectgorgon.com/wiki/Lore", false)
        http.Send()
        html := http.ResponseText
        
        ; Parse each table section
        ParseWorldInteractions(html, Items)
        ParseFavorsQuests(html, Items)
        ParseHangOuts(html, Items)
        ParseRecipes(html, Items)
        
    } catch as err {
        MsgBox("Error scraping wiki: " . err.Message . "`n`nContinuing with user data only.", "Warning", 48)
    }
    
    return Items
}

ParseWorldInteractions(html, Items) {
    ; Find the "Interacting With The World" table
    tableStart := InStr(html, "Interacting With The World")
    if (!tableStart)
        return
    
    ; Find the table tag after this heading
    tableStart := InStr(html, "<table", , tableStart)
    if (!tableStart)
        return
    
    tableEnd := InStr(html, "</table>", , tableStart)
    if (!tableEnd)
        return
    
    tableHtml := SubStr(html, tableStart, tableEnd - tableStart + 8)
    
    ; Extract rows
    pos := 1
    rowCount := 0
    
    loop {
        trStart := InStr(tableHtml, "<tr", , pos)
        if (!trStart)
            break
            
        trEnd := InStr(tableHtml, "</tr>", , trStart)
        if (!trEnd)
            break
        
        rowCount++
        
        ; Skip header row
        if (rowCount = 1) {
            pos := trEnd + 5
            continue
        }
        
        rowHtml := SubStr(tableHtml, trStart, trEnd - trStart + 5)
        
        ; Extract cells
        cells := []
        cellPos := 1
        
        loop {
            tdStart := InStr(rowHtml, "<td", , cellPos)
            if (!tdStart)
                break
                
            tdTagEnd := InStr(rowHtml, ">", , tdStart)
            tdEnd := InStr(rowHtml, "</td>", , tdTagEnd)
            if (!tdEnd)
                break
            
            cellContent := SubStr(rowHtml, tdTagEnd + 1, tdEnd - tdTagEnd - 1)
            cells.Push(cellContent)
            
            cellPos := tdEnd + 5
        }
        
        ; Structure: Source, Lore XP, NPC/Zone, Hints
        if (cells.Length >= 3) {
            sourceName := CleanHTML(cells[1])
            location := CleanHTML(cells[3])
            hint := ""
            
            ; Extract hint from title attribute if available
            if (cells.Length >= 4) {
                if (RegExMatch(cells[4], 'title="([^"]+)"', &match)) {
                    hint := match[1]
                    hint := DecodeHTML(hint)
                }
            }
            
            ; Skip if source name is just a number
            if (sourceName != "" && !RegExMatch(sourceName, "^\d+$"))
                Items[sourceName] := {Category: "World Interactions", Location: location, Hint: hint}
        }
        
        pos := trEnd + 5
    }
}

ParseFavorsQuests(html, Items) {
    ; Find the "Favors and Quests" table
    tableStart := InStr(html, "Favors and Quests")
    if (!tableStart)
        return
    
    tableStart := InStr(html, "<table", , tableStart)
    if (!tableStart)
        return
    
    tableEnd := InStr(html, "</table>", , tableStart)
    if (!tableEnd)
        return
    
    tableHtml := SubStr(html, tableStart, tableEnd - tableStart + 8)
    
    ; Extract rows
    pos := 1
    rowCount := 0
    
    loop {
        trStart := InStr(tableHtml, "<tr", , pos)
        if (!trStart)
            break
            
        trEnd := InStr(tableHtml, "</tr>", , trStart)
        if (!trEnd)
            break
        
        rowCount++
        
        ; Skip header row
        if (rowCount = 1) {
            pos := trEnd + 5
            continue
        }
        
        rowHtml := SubStr(tableHtml, trStart, trEnd - trStart + 5)
        
        ; Extract cells
        cells := []
        cellPos := 1
        
        loop {
            tdStart := InStr(rowHtml, "<td", , cellPos)
            if (!tdStart)
                break
                
            tdTagEnd := InStr(rowHtml, ">", , tdStart)
            tdEnd := InStr(rowHtml, "</td>", , tdTagEnd)
            if (!tdEnd)
                break
            
            cellContent := SubStr(rowHtml, tdTagEnd + 1, tdEnd - tdTagEnd - 1)
            cells.Push(cellContent)
            
            cellPos := tdEnd + 5
        }
        
        ; Structure: Source, Lore XP, NPC, Hints
        if (cells.Length >= 3) {
            questName := CleanHTML(cells[1])
            npc := CleanHTML(cells[3])
            hint := ""
            
            ; Extract hint from title attribute if available
            if (cells.Length >= 4) {
                if (RegExMatch(cells[4], 'title="([^"]+)"', &match)) {
                    hint := match[1]
                    hint := DecodeHTML(hint)
                }
            }
            
            ; Skip if quest name is just a number
            if (questName != "" && !RegExMatch(questName, "^\d+$"))
                Items[questName] := {Category: "Favors/Quests", Location: npc, Hint: hint}
        }
        
        pos := trEnd + 5
    }
}

ParseHangOuts(html, Items) {
    ; Find the "Hang Outs" table
    tableStart := InStr(html, "Hang Outs")
    if (!tableStart)
        return
    
    tableStart := InStr(html, "<table", , tableStart)
    if (!tableStart)
        return
    
    tableEnd := InStr(html, "</table>", , tableStart)
    if (!tableEnd)
        return
    
    tableHtml := SubStr(html, tableStart, tableEnd - tableStart + 8)
    
    ; Extract rows
    pos := 1
    rowCount := 0
    
    loop {
        trStart := InStr(tableHtml, "<tr", , pos)
        if (!trStart)
            break
            
        trEnd := InStr(tableHtml, "</tr>", , trStart)
        if (!trEnd)
            break
        
        rowCount++
        
        ; Skip header row
        if (rowCount = 1) {
            pos := trEnd + 5
            continue
        }
        
        rowHtml := SubStr(tableHtml, trStart, trEnd - trStart + 5)
        
        ; Extract cells
        cells := []
        cellPos := 1
        
        loop {
            tdStart := InStr(rowHtml, "<td", , cellPos)
            if (!tdStart)
                break
                
            tdTagEnd := InStr(rowHtml, ">", , tdStart)
            tdEnd := InStr(rowHtml, "</td>", , tdTagEnd)
            if (!tdEnd)
                break
            
            cellContent := SubStr(rowHtml, tdTagEnd + 1, tdEnd - tdTagEnd - 1)
            cells.Push(cellContent)
            
            cellPos := tdEnd + 5
        }
        
        ; Structure: Source, Lore XP, NPC, Hints
        if (cells.Length >= 3) {
            hangoutDesc := CleanHTML(cells[1])
            npc := CleanHTML(cells[3])
            hint := ""
            
            ; Extract hint from title attribute if available
            if (cells.Length >= 4) {
                if (RegExMatch(cells[4], 'title="([^"]+)"', &match)) {
                    hint := match[1]
                    hint := DecodeHTML(hint)
                }
            }
            
            ; Combine NPC with description
            fullName := npc . ": " . hangoutDesc
            
            if (hangoutDesc != "")
                Items[fullName] := {Category: "Hang Outs", Location: npc, Hint: hint}
        }
        
        pos := trEnd + 5
    }
}

ParseRecipes(html, Items) {
    ; Find recipe list - look for recipe table in the Complete Recipe List section
    recipeStart := InStr(html, "Lore Complete Recipe List")
    if (!recipeStart)
        return
    
    ; Find the next table
    tableStart := InStr(html, "<table", , recipeStart)
    if (!tableStart)
        return
    
    tableEnd := InStr(html, "</table>", , tableStart)
    if (!tableEnd)
        return
    
    tableHtml := SubStr(html, tableStart, tableEnd - tableStart + 8)
    
    ; Extract rows
    pos := 1
    rowCount := 0
    
    loop {
        trStart := InStr(tableHtml, "<tr", , pos)
        if (!trStart)
            break
            
        trEnd := InStr(tableHtml, "</tr>", , trStart)
        if (!trEnd)
            break
        
        rowCount++
        
        ; Skip header row
        if (rowCount = 1) {
            pos := trEnd + 5
            continue
        }
        
        rowHtml := SubStr(tableHtml, trStart, trEnd - trStart + 5)
        
        ; Extract cells
        cells := []
        cellPos := 1
        
        loop {
            tdStart := InStr(rowHtml, "<td", , cellPos)
            if (!tdStart)
                break
                
            tdTagEnd := InStr(rowHtml, ">", , tdStart)
            tdEnd := InStr(rowHtml, "</td>", , tdTagEnd)
            if (!tdEnd)
                break
            
            cellContent := SubStr(rowHtml, tdTagEnd + 1, tdEnd - tdTagEnd - 1)
            cells.Push(cellContent)
            
            cellPos := tdEnd + 5
        }
        
        ; Structure: Level, Name, First-Time XP, XP, Ingredients, Results, Description, Source
        ; We want column 2 (Name), column 7 (Description as hint)
        if (cells.Length >= 2) {
            recipeName := CleanHTML(cells[2])
            hint := ""
            
            ; Get description from column 7 if available
            if (cells.Length >= 7) {
                hint := CleanHTML(cells[7])
            }
            
            if (recipeName != "")
                Items[recipeName] := {Category: "Recipes", Location: "", Hint: hint}
        }
        
        pos := trEnd + 5
    }
}

CleanHTML(str) {
    ; Remove HTML tags
    cleaned := RegExReplace(str, "<[^>]+>", "")
    ; Decode common HTML entities
    cleaned := DecodeHTML(cleaned)
    return Trim(cleaned)
}

DecodeHTML(str) {
    str := StrReplace(str, "&amp;", "&")
    str := StrReplace(str, "&lt;", "<")
    str := StrReplace(str, "&gt;", ">")
    str := StrReplace(str, "&quot;", '"')
    str := StrReplace(str, "&#39;", "'")
    str := StrReplace(str, "&nbsp;", " ")
    return str
}

FilterData() {
    global MainGui, LoreData, FilteredData
    
    SearchText := MainGui["SearchText"].Value
    SourceFilter := MainGui["SourceFilter"].Text
    CategoryFilter := MainGui["CategoryFilter"].Text
    
    FilteredData := []
    
    for Item, Info in LoreData {
        ; Use the stored original key
        DisplayName := Info.HasOwnProp("OriginalKey") ? Info.OriginalKey : Item
        
        ; Determine source
        Source := ""
        if (Info.User && Info.Wiki)
            Source := "Both"
        else if (Info.User)
            Source := "User Only"
        else if (Info.Wiki)
            Source := "Wiki Only"
        
        ; Apply filters
        if (SourceFilter != "All" && Source != SourceFilter)
            continue
        if (CategoryFilter != "All" && Info.Category != CategoryFilter)
            continue
        if (SearchText != "" && !InStr(DisplayName, SearchText))
            continue
        
        ; Show more hint text - truncate at 150 chars instead of 50
        displayHint := Info.Hint
        if (StrLen(displayHint) > 150)
            displayHint := SubStr(displayHint, 1, 147) . "..."
        
        FilteredData.Push({Name: DisplayName, Category: Info.Category, Source: Source, Location: Info.Location, Hint: displayHint, FullHint: Info.Hint})
    }
    UpdateListView()
}

UpdateListView() {
    global MainGui, FilteredData
    LV := MainGui["LoreList"]
    LV.Delete()
    
    for Item in FilteredData
        LV.Add("", Item.Name, Item.Category, Item.Source, Item.Location, Item.Hint)
    
    MainGui["Status"].Value := "Showing " . FilteredData.Length . " of " . LoreData.Count . " sources. (Double-click a row to see full hint)"
}

UpdateStats() {
    global MainGui, LoreData
    
    ; Count by category
    stats := {
        WorldTotal: 0, WorldUser: 0,
        QuestTotal: 0, QuestUser: 0,
        HangOutTotal: 0, HangOutUser: 0,
        RecipeTotal: 0, RecipeUser: 0
    }
    
    for Item, Info in LoreData {
        if (Info.Wiki) {
            if (Info.Category = "World Interactions")
                stats.WorldTotal++
            else if (Info.Category = "Favors/Quests")
                stats.QuestTotal++
            else if (Info.Category = "Hang Outs")
                stats.HangOutTotal++
            else if (Info.Category = "Recipes")
                stats.RecipeTotal++
        }
        
        if (Info.User) {
            if (Info.Category = "World Interactions")
                stats.WorldUser++
            else if (Info.Category = "Favors/Quests")
                stats.QuestUser++
            else if (Info.Category = "Hang Outs")
                stats.HangOutUser++
            else if (Info.Category = "Recipes")
                stats.RecipeUser++
        }
    }
    
    statsText := ""
    statsText .= "World Interactions: " . stats.WorldUser . " / " . stats.WorldTotal . "   "
    statsText .= "Favors/Quests: " . stats.QuestUser . " / " . stats.QuestTotal . "`n"
    statsText .= "Hang Outs: " . stats.HangOutUser . " / " . stats.HangOutTotal . "   "
    statsText .= "Recipes: " . stats.RecipeUser . " / " . stats.RecipeTotal
    
    MainGui["StatsText"].Value := statsText
}

ClearFilters() {
    global MainGui
    MainGui["SearchText"].Value := ""
    MainGui["SourceFilter"].Choose(1)
    MainGui["CategoryFilter"].Choose(1)
    FilterData()
}

GuiSize(GuiObj, MinMax, Width, Height) {
    if (MinMax = -1)
        return
    GuiObj["LoreList"].Move(, , Width - 60, Height - 435)
    GuiObj["Status"].Move(, Height - 40, Width - 40)
}