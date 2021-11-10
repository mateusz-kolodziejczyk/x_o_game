-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

local mylib = require("mylib")
local rng = require("rng")
local colors = require("colorsRGB")
-- ai= require("first_space_player")
-- ai=require("rule_based_player")
-- ai = require("minimax_player")
rng.randomseed(os.time())

local backGroup = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local board = {} -- 2d repressenation of game board (logic)
local squares = {} -- 1d represetation of game board (ui, events)

local players = {
    {name="X", human=true, value=1, wins=0},
    {name="O", human=true, value=2, wins=0},
}
local player = 1 -- current player
local gameCount = 0
local state -- 'waiting', 'thinking', 'over'

local gap = 6
local size = (math.min(display.contentWidth, display.contentHeight) - 4*gap) / 3

local background = display.newImageRect(backGroup,"assets/images/background.png", 444, 794)
background.x = display.contentCenterX
background.y = display.contentCenterY

local titleText, startsTest, gameOverText, turnText

---------------
-- Audio
---------------
----------------
-- Logic functions
----------------

local function isRowWin()
    for r = 1, 3 do
        if board[r][1] ~= 0 and board[r][1]==board[r][2] and board[r][2]==board[r][3] then
            return r
        end
    end
    return 0
end

local function isColWin()
    for c = 1, 3 do
        if board[1][c] ~= 0 and board[1][c]==board[2][c] and board[2][c]==board[3][c] then
            return c
        end
    end
    return 0
end

local function isDiagonalWin()
    return board[1][1]~=0 and board[1][1]==board[2][2] and board[2][2]==board[3][3]
end

local function isAntiDiagonalWin()
    return board[1][3]~=0 and board[1][3]==board[2][2] and board[2][2]==board[3][1]
end

local function isWin()
    return isRowWin()>0 or isColWin()>0 or isDiagonalWin() or isAntiDiagonalWin()
end

local function isTie()
    for row = 1, 3 do
        for col = 1, 3 do
            if board[row][col] == 0 then
                return false
            end
        end
    end
    return true
end

---------------------------
-- UI and playing functions
---------------------------
display.setStatusBar(display.HiddenStatusBar)

-- Line relative to center
local function drawLine(x1, y1, x2, y2, width)
    local line = display.newLine(backGroup,
    display.contentCenterX + x1*size, display.contentCenterY + y1*size,
    display.contentCenterX + x2*size, display.contentCenterY + y2*size
    )
    color = color or "black"
    line:setStrokeColor(colors.RGB(color))
    width = width or 8
    line.strokeWidth = width
end
-- display end of game message
local function displayMessage(message) 

end

-- Switch to next player or given player index
local function nextPlayer(value)
    player = value or (player%2 + 1)

    state = players[player].human and "waiting" or "thinking"

end

-- carries out a valid move
function move(k)
    -- determine location of valid move
    local row, col = mylib.k2rc(k)
    local square = squares[k]

    -- update ui and logic
    local filename = "assets/images/" .. players[player].name .. ".png"
    local symbol = display.newImageRect(mainGroup, filename, size-4*gap, size-4*gap)
    symbol.x = square.rect.x
    symbol.y = square.rect.y
    square.symbol = symbol
    board[row][col] = players[player].value
    -- check if game win
    if isWin() then 
    elseif isTie() then
    else
        nextPlayer()
    end
    -- else check if game tie
    -- else switch to next player
end

-- Checks if a move caused by tap event is valid
-- False if invalid move
local function checkMove(event)
    -- determine location of tap on board
    print(players[player].name .. "'s move at square " .. event.target.k)
    local row, col = mylib.k2rc(event.target.k)
    -- current player must be human
    if state~="waiting" then
        print("\t not waiting for human input - ignore move")
        return false
    end
    -- current square must be empty
    if board[row][col] ~= 0 then
        print("\t cannot move to non empty space - ignore move")
        return false
    end
    -- implement valid move
    move(event.target.k)
end

-- reset game state (without unnecessary destroying)
local function resetBoard()
    -- tidy up of UI elements

    -- reset game logic
    board = {}
    for row = 1, 3 do
        board[row] = {}
        for col = 1, 3 do
            board[row][col] = 0
        end
    end
    nextPlayer(1)
end

local function createBoard()
    -- center board vertically and maximum width
    -- Vertical lines
    drawLine(-1/2, -3/2, -1/2, 3/2)
    drawLine(1/2, -3/2, 1/2, 3/2)
    -- Horizontal lines
    drawLine(-3/2, -1/2, 3/2, -1/2)
    drawLine(-3/2, 1/2, 3/2, 1/2)
    for k = 1, 9 do
        local row, col = mylib.k2rc(k)
        local x = display.contentCenterX + (col-4/2)*size
        local y = display.contentCenterY + (row-4/2)*size
        local rect = display.newRect(uiGroup, x, y, size-gap, size-gap)
        rect.alpha = 0.05
        rect.k = k
        rect:addEventListener("tap", checkMove )
        squares[k] = {rect=rect}
    end
    resetBoard()
end

createBoard()