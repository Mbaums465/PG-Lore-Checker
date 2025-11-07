# Key Features and Changes - Lore XP Analyzer

## Script Adaptations from Death Report Analyzer

### 1. Multi-Category Tracking
- **Deaths**: Single table of death causes
- **Lore**: Four separate categories:
  - World Interactions (books/items with locations)
  - Favors and Quests (quest completions)
  - Hang Outs (NPC activities with descriptions)
  - Recipes (learnable recipes)

### 2. Enhanced GUI Layout
- **Added**: Category dropdown filter (All/World/Quests/Hangouts/Recipes)
- **Added**: Progress Summary section showing completion stats per category
- **Modified**: ListView now shows Category and Location columns
- **Resized**: Taller window (730px) to accommodate progress section

### 3. Wiki Parsing Functions
Created four specialized parsing functions:
- `ParseWorldInteractions()` - Extracts item names and locations
- `ParseFavorsQuests()` - Extracts quest names from NPC column
- `ParseHangOuts()` - Combines NPC name with hangout description
- `ParseRecipes()` - Extracts recipe names from recipe table

### 4. User File Parsing
- Detects section headers: "Favors and Quests:", "Hang Outs:", "Recipes:"
- Parses plain text items (no colon suffix like death counts)
- Assigns category to each item based on current section
- Stops at "XP from" totals line

### 5. Progress Statistics
New `UpdateStats()` function calculates:
- Total available per category (from wiki)
- Completed per category (from user file)
- Displays as "X / Y" format in summary section

### 6. HTML Table Structure Handling
Each category has unique table structure:
- **World Interactions**: Column 1 = item name, Column 2 = location
- **Favors/Quests**: Column 2 = quest name (skip column 1 NPC)
- **Hang Outs**: Columns 1 + 2 combined (NPC: description)
- **Recipes**: Column 2 = recipe name (column 1 is level)

## File Format Differences

### Input File Structure
**Death Report:**
```
Deaths (by Cause Of Death):
Crushing Damage: 15
Falling Damage: 8
Slashing Damage: 23
```

**Lore Report:**
```
Sources of Lore XP:

Favors and Quests:
Broken Playset
Save Sarina

Hang Outs:
Blanche: Search for antique Human artifacts

Recipes:
Advanced Augury
Apply Beaker Augment
```

### Output Display
**Death Analyzer:**
- Cause of Death | Found In | Wiki Hint

**Lore Analyzer:**
- Source Name | Category | Found In | Location

## Technical Implementation Notes

### Normalization
Both scripts use case-insensitive matching with whitespace normalization to handle:
- Capitalization differences
- Extra spaces
- Different formats between wiki and in-game text

### Wiki Scraping
- **URL**: https://wiki.projectgorgon.com/wiki/Lore
- **Method**: WinHTTP COM object
- **Tables**: Four separate tables on same page vs. one table for deaths
- **Challenge**: Each table has different column structure requiring custom parsing

### Data Structure
```ahk
LoreData[NormalizedKey] := {
    User: boolean,          ; Found in user's report
    Wiki: boolean,          ; Found on wiki
    Category: string,       ; Which type of XP source
    Location: string,       ; Where to find it (World items only)
    OriginalKey: string     ; Display name (original capitalization)
}
```

## Usage Recommendations

### For Players Tracking Progress
1. Generate report after each play session
2. Filter to "Wiki Only" to see what's missing
3. Use Category filter to focus on one type at a time
4. Location column helps find world interaction items efficiently

### For Completionists
1. Check Progress Summary for overall completion %
2. Sort by category to work through systematically
3. Cross-reference with wiki for quest requirements
4. Track hangouts requiring specific favor levels

### For Tool Developers
- Code structure is modular and easy to extend
- Each category parser can be modified independently
- Easy to add new categories if wiki adds sections
- Statistics function can be expanded for more metrics

## Future Enhancement Ideas

1. **XP Value Tracking**: Parse and display XP values per source
2. **Favor Requirements**: Show required favor level for hangouts
3. **Quest Chains**: Link related quests together
4. **Export Function**: Save progress report to file
5. **Comparison Mode**: Compare two skill reports to see progress over time
6. **Missing Only Mode**: Quick filter to show only incomplete sources
7. **Zone Filtering**: Filter world items by specific zone
8. **NPC Grouping**: Group hangouts by NPC for easier tracking

## Testing Checklist

- [ ] File selection and loading
- [ ] Wiki scraping for all four categories
- [ ] Progress statistics accuracy
- [ ] Search filter across all categories
- [ ] Category dropdown filter
- [ ] Source filter (Both/User Only/Wiki Only)
- [ ] Clear filters button
- [ ] ListView sorting (if implemented)
- [ ] Window resizing
- [ ] HTML entity decoding
- [ ] Normalization and matching
- [ ] Error handling for network issues
- [ ] Error handling for missing tables

## Known Limitations

1. **Network Dependency**: Requires internet to scrape wiki
2. **Wiki Format Changes**: May break if wiki table structure changes
3. **Matching Accuracy**: Some items may not match due to formatting differences
4. **Location Data**: Only available for World Interactions category
5. **XP Values**: Not currently tracked or displayed
6. **Historical Tracking**: No built-in comparison between multiple reports

## Maintenance Notes

### If Wiki Format Changes
1. Check table structure on wiki page
2. Update corresponding Parse function
3. Verify column indices are correct
4. Test HTML entity decoding
5. Check for new table headers or structure

### If Game Report Format Changes
1. Update `ParseUserFile()` section detection
2. Verify item line parsing logic
3. Check for new categories or renamed sections
4. Validate XP total line detection

## Support and Updates

For issues or feature requests:
- Check the Project Gorgon forums
- Visit the wiki discussion pages
- Contact script maintainer

Remember to update the script when major game updates change:
- Skill report format
- Wiki page structure
- Category names
- XP calculation methods
