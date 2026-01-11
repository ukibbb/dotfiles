# Command 1: Search for files named "cmp.lua" in the NvChad plugin directory
# find: utility to search for files and directories
# ~/.local/share/nvim/lazy/ui/lua/nvchad: starting directory (NvChad's 
# UI plugin location managed by lazy.nvim)
# -name "cmp.lua": filter to find only files with exact name "cmp.lua"
# 2>/dev/null: redirect stderr (error messages like "permission denied") to /dev/null to hide them
find ~/.local/share/nvim/lazy/ui/lua/nvchad -name "cmp.lua" 2>/dev/null


# Command 2: Search recursively for patterns related to cmp exports or module definitions
# grep: text search utility
# -r: recursive search through all files in directory and subdirectories
# "exports.*cmp\|M\.cmp": regex pattern to find either "exports" followed by any chars then "cmp", OR "M.cmp" (module export pattern)
# ~/.local/share/nvim/lazy/ui/lua/nvchad: directory to search in
# 2>/dev/null: suppress error messages
# | grep -v ".git": pipe output to second grep with -v (invert match) to exclude lines containing ".git" directory
# | head -10: pipe to head to show only first 10 results (limits output)
grep -r "exports.*cmp\|M\.cmp" ~/.local/share/nvim/lazy/ui/lua/nvchad 2>/dev/null | grep -v ".git" | head -10


# Command 3: Display contents of init.lua and show cmp-related sections with context
# cat: concatenate and display file contents
# ~/.local/share/nvim/lazy/ui/lua/nvchad/init.lua: path to NvChad's main initialization file
# 2>/dev/null: suppress error messages if file doesn't exist
# | grep -A 20 "cmp": pipe to grep with -A 20 (After context) flag to show matching line plus 20 lines after it
# This helps see the full context of cmp configuration/setup
cat ~/.local/share/nvim/lazy/ui/lua/nvchad/init.lua 2>/dev/null | grep -A 20 "cmp"

# Command 4: List all files and directories in the NvChad lua directory with detailed information
# ls: list directory contents
# -la: combined flags: -l (long format with permissions, size, date) and -a (show all files including hidden ones starting with .)
# ~/.local/share/nvim/lazy/ui/lua/nvchad/: directory path to list
# 2>/dev/null: suppress error messages
ls -la ~/.local/share/nvim/lazy/ui/lua/nvchad/ 2>/dev/null

# Command 5: List cmp directory contents AND display the init.lua file inside it
# ls -la ~/.local/share/nvim/lazy/ui/lua/nvchad/cmp/: list all files in cmp subdirectory with detailed info
# &&: logical AND operator - only execute second command if first command succeeds (exit code 0)
# cat ~/.local/share/nvim/lazy/ui/lua/nvchad/cmp/init.lua: display contents of init.lua file inside cmp directory
# This combines both viewing the directory structure and file contents in one command chain
ls -la ~/.local/share/nvim/lazy/ui/lua/nvchad/cmp/ && cat ~/.local/share/nvim/lazy/ui/lua/nvchad/cmp/init.lua


# Command 1: Count how many theme files are available in Ghostty's themes directory
# ls: lists all files in the themes directory of Ghostty
# | wc -l: pipes the list of files to wc (word count), using -l to count the number of lines (i.e., number of themes)
ls /Applications/Ghostty.app/Contents/Resources/ghostty/themes/ | wc -l

# Command 2: Search for popular theme names in the Ghostty themes directory
# ls: lists all files (theme names) in the themes directory
# | grep -i "catppuccin\|mocha\|nord\|dracula\|gruvbox\|solarized\|tokyo\|one":
#     pipes the list to grep, which searches case-insensitively (-i) for any of the specified theme names
#     The \| symbol means "or" in regular expressions, so any listed theme will match and be shown in output
ls /Applications/Ghostty.app/Contents/Resources/ghostty/themes/ | grep -i "catppuccin\|mocha\|nord\|dracula\|gruvbox\|solarized\|tokyo\|one"