VERSION = "1.0.0"

local micro = import("micro")
local shell = import("micro/shell")
local buffer = import("micro/buffer")
local action = import("action")
local config = import("micro/config")
local clipboard = import("micro/clipboard")
local fmt = import("fmt")
local os = import("os")

function init()
    config.MakeCommand("grep", grepCommand, config.NoComplete)
    config.MakeCommand("greppath", grepShowPath, config.NoComplete)
    -- Register syntax file
    config.AddRuntimeFile("microgrep", config.RTHelp, "microgrep.md")
    config.AddRuntimeFile("microgrep", config.RTSyntax, "grep.yaml")


end

-- Not used
function iterateTabs()
    local tabs = micro.Tabs()
    for i = 1,#tabs.List do
        tab = tabs.List[i]
        for j = 1,#tab.Panes do
            micro.Log(i, j)
        end
    end
end

function stdoutCallback(out)
    local buf = micro.CurPane().Buf
    local loc = buf:GetActiveCursor().Loc
    buf:Insert(buffer.Loc(loc.X, loc.Y), out)
end

function stderrCallback(out)
    local buf = micro.CurPane().Buf
    local loc = buf:GetActiveCursor().Loc
     -- TODO: In the future, consider setting cursor location at buffer end,
     -- in cases of long running grep command, while user modifies CurPane()
    -- Right now we assume the insertion point is unchanged and at the end
    buf:Insert(buffer.Loc(loc.X, loc.Y), out)
end

function onExitCallback(out)
    local buf = micro.CurPane().Buf
    local loc = buf:GetActiveCursor().Loc
    buf:Insert(buffer.Loc(loc.X, loc.Y), "DONE\n")
    -- On exit, set buffer to read only
    cmd ={}
    cmd[1] = "readonly"
    cmd[2] = "true"
    micro.CurPane():SetCmd(cmd)

end

-- Runs grep command in the background and outputs results into a separate tab
function grepCommand(bp, name)
    if #name < 1 then
        micro.InfoBar():Error("No argument provided to grep")
        micro.Log("No argument provided to grep")
        return
    end
    bp:AddTab()  -- This updates CurPane

    cmd = {}
    cmd[1] = "filetype"
    cmd[2] = "grep"
    bp:SetCmd(cmd)  -- Enable custom grep coloring for this buffer
    
    local options = {"-rn", name[1]} -- recursive with line number
    local job = shell.JobSpawn("grep", options, stdoutCallback, stderrCallback, onExitCallback )

    local buf = micro.CurPane().Buf
    buf:SetName("grep:" .. name[1])
        
end

-- Copy path of the current buffer to system clipboard
function grepShowPath(bp)
    local buf = micro.CurPane().Buf
    micro.InfoBar():Message(buf:GetName())
    -- clipboard.Write("AAA", -1)  -- clipboard:ClipboardReg : -1

    -- NOTE: All below is a workaround to put a string into a system clipboard
    
    -- Split pane in half and add some text
    micro.CurPane():HSplitAction()
    local absPath = os.Getwd() .. "/" .. buf:GetName()
    micro.InfoBar():Message(absPath)

    local buf,err = buffer.NewBuffer(absPath, "")
    -- Workaround to copy path to clioboard
    micro.CurPane():OpenBuffer(buf)
    micro.CurPane():CopyLine()
    micro.CurPane():ForceQuit() -- Close current buffer pane

end

-- If the active cursor is pointing at a valid path, open it
function grepOpen(bp)
    local buf = bp.Buf

    -- Record start/end positions 
    bp:StartOfText()
    local loc = buf:GetActiveCursor().Loc
    local s_loc = buffer.Loc(loc.X, loc.Y)
    bp:EndOfLine()
    local locEnd = buf:GetActiveCursor().Loc
    local e_loc = buffer.Loc(loc.X, loc.Y)

    -- Search for the text between colons according to
    -- the following grep pattern:  ./file_path:line_number:
    path_loc, found, err = buf:FindNext("(.*?):", s_loc, e_loc, s_loc, true , true)
    startLoc = buffer.Loc(path_loc[1].X, path_loc[1].Y)
    endLoc = buffer.Loc(path_loc[2].X-1, path_loc[2].Y)
    local pathByte = buf:Substr(startLoc, endLoc)

    s_loc = path_loc[2]  -- Use end location as the next starting point
    line_loc, found, err = buf:FindNext("(.*?):", s_loc, e_loc, s_loc, true , true)
    startLoc = buffer.Loc(line_loc[1].X, line_loc[1].Y)
    endLoc = buffer.Loc(line_loc[2].X-1, line_loc[2].Y)
    local lineNumByte = buf:Substr(startLoc, endLoc)
    local lineNum = tonumber(fmt.Sprintf("%s", lineNumByte))

    if lineNum == nil then -- If not a path
        micro.InfoBar():Message("This line does not contain a valid file path")
        buf:GetActiveCursor():GotoLoc(buffer.Loc(0, s_loc.Y)) 
        return
    end
    -- Once we know the linNum is not nil
    lineNum = lineNum - 1

    local pathArr = {}
    pathArr[1] = pathByte

    -- Close previous split if already open 
    if #micro.CurTab().Panes == 2 then
        micro.CurPane():NextSplit()
        micro.CurPane():Unsplit()
    end
    micro.CurPane():HSplitCmd(pathArr)

    -- Move to correct line number in the new split
    local subbuf = micro.CurPane().Buf
    local subCursor = subbuf:GetActiveCursor()
    subCursor:GotoLoc(buffer.Loc(0, lineNum))
    micro.CurPane():Center()  -- Center view
    micro.CurPane():NextSplit()  -- Toggle back to grep buffer
    
    -- Use start location but set column 0 so that Cursor is on the valid path string.
    -- This is only for convenience before the next user action.
    buf:GetActiveCursor():GotoLoc(buffer.Loc(0, s_loc.Y)) 

end

-- Events

function onInsertTab(bp)
    -- First, limit effect of this event to
    -- buffer names which begin with 'grep'
    local buf = bp.Buf
    if buf:GetName():find("^grep") == nil then
        return
    end
    cmd = {}
    cmd[1]="readonly"
    local readonly = bp:ShowCmd(cmd)

    -- TODO: undo only if we press tab in a non-readonly buffer
    -- right now we set buffer to readonly in onExit() callback.
    -- If we remove the read-only flag, uncomment the next line
    -- as in this event we insert <tab> each time.
    -- bp:Undo() -- Undo inserted indent
    
    grepOpen(bp) -- Run open function
end