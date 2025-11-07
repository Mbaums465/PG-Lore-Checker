# Project Gorgon Lore XP Analyzer

## Overview
This AutoHotkey v2 script analyzes your Lore skill progress in Project Gorgon by comparing your in-game Skill Report with the wiki's complete list of Lore XP sources.

## Features

### Data Sources
The script tracks four categories of Lore XP sources from the wiki:
1. **World Interactions** - Books and items found in the world
2. **Favors and Quests** - Quest completions that grant Lore XP
3. **Hang Outs** - NPC hangout activities
4. **Recipes** - Lore recipes learned

### Main Features
- **Automatic Wiki Scraping** - Fetches the latest data from https://wiki.projectgorgon.com/wiki/Lore
- **Progress Tracking** - Shows completion status for each category
- **Comparison View** - Identifies which sources you have vs. what's available on wiki
- **Advanced Filtering**:
  - Search by source name
  - Filter by category (World Interactions, Favors/Quests, Hang Outs, Recipes)
  - Filter by completion status (Both, User Only, Wiki Only)
- **Location Information** - Displays NPC or zone location for finding sources
- **Hint Display** - View hints/descriptions for each source:
  - Up to 150 characters shown in the list
  - Click a row to see a tooltip preview
  - Double-click any row to see the full hint in a dialog box

## How to Use

### Step 1: Generate Your Skill Report
1. In Project Gorgon, open your Skills window (K key by default)
2. Click on the **Lore** skill
3. Click the **"Report"** button at the bottom
4. The report will be saved to: `C:\Users\<YourName>\AppData\LocalLow\Elder Game\Project Gorgon\Books\`
5. The file will be named something like `SkillReport_YYMMDD_HHMMSS.txt`

### Step 2: Run the Analyzer
1. Double-click `PGLore.ahk` to launch the program
2. Click the **"Browse..."** button
3. Navigate to the Books folder (shown above)
4. Select your most recent Skill Report file
5. Wait while the script loads your data and scrapes the wiki

### Step 3: Analyze Your Progress
The **Progress Summary** section shows your completion percentage for each category:
```
World Interactions: X / Y    Favors/Quests: X / Y
Hang Outs: X / Y             Recipes: X / Y
```

The main list shows all Lore XP sources with these columns:
- **Source Name** - The name of the quest, hangout, recipe, or item
- **Category** - Which type of Lore XP source it is
- **Found In** - Where it appears:
  - **Both** - You have it AND it's on the wiki (completed)
  - **User Only** - In your report but not found on wiki (possible formatting difference)
  - **Wiki Only** - On the wiki but not in your report (not yet obtained)
- **Location** - Shows NPC name or zone where the source is found
- **Hint** - Description or hint text (up to 150 chars displayed, double-click for full text)

### Step 4: View Hints and Details
- **Click** any row to see a tooltip preview of the hint
- **Double-click** any row to open a dialog with the full hint text
- Hints provide context about where to find items, who gives quests, or what recipes do
### Step 5: Filter and Search
- **Search Box** - Type any text to filter by name
- **Source Filter** - Show only completed items, missing items, or all
- **Category Filter** - Focus on a specific type of Lore XP source
- **Clear Filters** - Reset all filters to show everything

## Skill Report Format
The script expects your skill report to be formatted like this:

```
Sources of Lore XP:

Favors and Quests:
Broken Playset
Save Sarina
Stargazer Alignment

Hang Outs:
Blanche: Search for antique Human artifacts
Blanche: Talk about how the council needs to send more researchers to Serbule
Ferris Blueheart: Discuss the history of The Council

Recipes:
Advanced Augury
Apply Beaker Augment
Apply Bow Augment
```

## Tips for Maximizing Lore XP

### Finding Missing World Interactions
1. Filter by **Category: World Interactions** and **Source: Wiki Only**
2. Check the **Location** column to see where to find each item
3. Visit those zones and look for sparkly/interactable books and items

### Completing Missing Hangouts
1. Filter by **Category: Hang Outs** and **Source: Wiki Only**
2. The NPC name is shown before the colon
3. Talk to that NPC and check their hangout options
4. Some hangouts require specific favor levels

### Learning Missing Recipes
1. Filter by **Category: Recipes** and **Source: Wiki Only**
2. Most Lore recipes come from:
   - NPCs like Velkort, Flia, and Marna
   - Quest rewards
   - Recipe scrolls found in the world

### Quest Tracking
1. Filter by **Category: Favors/Quests** and **Source: Wiki Only**
2. Check the wiki for quest givers and requirements
3. Many Lore quests are in Serbule Keep or come from Council members

## Technical Notes

### Requirements
- AutoHotkey v2.0 (download from https://www.autohotkey.com/)
- Windows operating system
- Project Gorgon game installed

### Recent Improvements
- **Numeric Filtering** - Automatically filters out numeric-only entries (like "100", "200", "50") from the Lore XP column that were incorrectly parsed as sources
- **Enhanced Hint Display** - Hints now show up to 150 characters in the list view, with full text accessible via double-click or tooltip
- **Proper Table Parsing** - Correctly handles different table structures:
  - World Interactions, Favors/Quests, Hang Outs: Source, Lore XP, NPC/Zone, Hints
  - Recipes: Level, Name, First-Time XP, XP, Ingredients, Results, Description, Source
- **Better Hangout Matching** - Properly combines NPC name with description (e.g., "Blanche: Search for antique Human artifacts")

### Data Accuracy
- The script scrapes live data from the wiki each time you load a file
- If wiki data changes, your next analysis will reflect those updates
- Some formatting differences between your report and wiki may cause items to appear in "User Only" - these are usually still matches

### Troubleshooting
- **"Could not find table" error**: The wiki page format may have changed. Check for script updates.
- **Missing items**: Make sure you're using the most recent Skill Report file
- **Network errors**: The script needs internet access to scrape the wiki

## Differences from Death Report Analyzer
This script is based on the Death Report Analyzer but adapted for Lore XP tracking:
- Tracks 4 categories instead of just one death table
- Includes progress statistics by category
- Shows location information (NPC/zone) for all sources
- Displays hints with interactive features (click for tooltip, double-click for full dialog)
- Uses different parsing logic for the Lore wiki page structure
- Filters out numeric-only entries from XP columns
- Category-based filtering instead of just source filtering
- Wider window (1000px) to accommodate hint column

## Credits
- Based on the Project Gorgon Death Report Analyzer
- Wiki data from https://wiki.projectgorgon.com/
- Created for the Project Gorgon community

## Version History
- v1.1 - Enhanced hint display with tooltips and full text dialog, filtered numeric-only entries, improved table parsing
- v1.0 - Initial release with four category tracking
