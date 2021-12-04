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
-- ai=require("random_impact_player")
local ai = require("minimax_player")
rng.randomseed(os.time())

local backGroup = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local board = {} -- 2d repressenation of game board (logic)
local subboards = {} -- Stores states of the subboards
local squares = {} -- 1d represetation of game board (ui, events)

-- This allows to draw boards with their centers in relation to the centerx/y values
local signs = {-1, 0, 1}
local players = {{
    name = "X",
    human = true,
    value = 1,
    wins = 0
}, {
    name = "O",
    human = false,
    value = -1,
    wins = 0
}}
local player = 1 -- current player
local gameCount = 0
local state -- 'waiting', 'thinking', 'over'

local gap = 6
local size = (math.min(display.contentWidth, display.contentHeight) - 4 * gap) / 3
local subboardScale = 1 / 3 - ((gap / size) / 2)
local background = display.newImageRect(backGroup, "assets/images/background.png", 444, 794)
background.x = display.contentCenterX
background.y = display.contentCenterY

local titleText, startsTest, turnText, gameOverText
local gameOverImage

local mainSquare, subSquare = 0, 0
-- Functions
local resetBoard, move, drawBoard
-----------------------------------------------------------------------------------------
-- audio setup
-----------------------------------------------------------------------------------------
local tapSound, winSound, buttonSound

audio.reserveChannels(3)

-- Reduce the overall volume of the channel
local bgMusic = audio.loadStream("assets/audio/bgMusic.mp3")

audio.setVolume(0.4, {
    channel = 1
})
audio.setVolume(0.8, {
    channel = 2
})
audio.setVolume(0.9, {
    channel = 3
})
-- audio.play( bgMusic, { channel=1, loops=-1 } )

---------------------------
-- UI and playing functions
---------------------------
display.setStatusBar(display.HiddenStatusBar)

-- Line relative to center
local function drawLine(x1, y1, x2, y2, width, color, centerPos, scale)
    if centerPos == nil then
        centerPos = {}
        centerPos.x = display.contentCenterX
        centerPos.y = display.contentCenterY
    end
    local line = display.newLine(backGroup, centerPos.x + x1 * size * scale, centerPos.y + y1 * size * scale,
        centerPos.x + x2 * size * scale, centerPos.y + y2 * size * scale)
    color = color or "black"
    line:setStrokeColor(colors.RGB(color))
    width = width or 8
    line.strokeWidth = width * scale
end
-- display end of game message
local function displayMessage(message)
    gameOverText.text = message
    gameOverImage.alpha = 0.5
    timer.performWithDelay(2500, resetBoard)

end

drawBoard = function(scale, color, centerPos)
    -- Vertical lines
    drawLine(-1 / 2, -3 / 2, -1 / 2, 3 / 2, 8, color, centerPos, scale)
    drawLine(1 / 2, -3 / 2, 1 / 2, 3 / 2, 8, color, centerPos, scale)
    -- Horizontal lines
    drawLine(-3 / 2, -1 / 2, 3 / 2, -1 / 2, 8, color, centerPos, scale)
    drawLine(-3 / 2, 1 / 2, 3 / 2, 1 / 2, 8, color, centerPos, scale)
end
-- Switch to next player or given player index
local function nextPlayer(value)
    player = value or (player % 2 + 1)

    state = players[player].human and "waiting" or "thinking"

    if state == 'thinking' then
        local k, kk = ai.move(board, subboards, players, player, mainSquare)
        print("Chosen k: " .. k .. "   Chosen kk: " .. kk)
        move(k, kk)
    end
end

-- carries out a valid move
move = function(k, kk)
    -- determine location of valid move
    local square = squares[k]

    -- update ui and logic
    local filename = "assets/images/" .. players[player].name .. ".png"

    -- Get the x/y of the suqare where the move is being made
    local row, col = mylib.k2rc(kk)
    local x = squares[k].rect.x + size*subboardScale*signs[col]
    local y = squares[k].rect.y + size*subboardScale*signs[row]
    print("xy: " .. "(" .. x .. "," .. y .. ")")
    print(squares[k].rect.x)
    local squareSize = 0
    local symbol = display.newImageRect(mainGroup, filename, size * subboardScale, size * subboardScale)
    symbol.x = x
    symbol.y = y
    square.subsquares[kk].symbol = symbol
    subboards[k][kk] = players[player].value

    -- Apply the graphic changes and handle the logic to make sure the player is free to chooose if an occupied main square was chosen with kk
    squares[k].rect.alpha = 0.05
    if board[kk] == 0 then
        print("Board at " .. kk .. " is empty")
        mainSquare = kk
        squares[kk].rect.alpha = 0.5
    else
        mainSquare = 0
    end
    -- check if subboard is won
    -- if it is fill in the board with the appropriate symbol
    if mylib.isWin(subboards[k]) then
        local filename = "assets/images/" .. players[player].name .. ".png"
        local symbol = display.newImageRect(mainGroup, filename, size-4*gap, size-4*gap)
        symbol.x = square.rect.x
        symbol.y = square.rect.y
        square.symbol = symbol
        board[k] = players[player].value
        if k == kk then
            mainSquare = 0
        end
    -- If the subboard is tied no symbol will be placed so the board will instead contain a new field.
    elseif mylib.isTie(subboards[k]) then
        board[k] = math.huge
        mainSquare = 0

        if k == kk then
            mainSquare = 0
        end
    end

    -- check if game win
    if mylib.isWin(board) then
        state = 'over'
        gameCount = gameCount + 1
        players[player].wins = players[player].wins + 1
        displayMessage("Player " .. players[player].name .. " Wins")
    elseif mylib.isTie(board) then
        state = 'over'
        gameCount = gameCount + 1
        displayMessage("Tie")
    else
        nextPlayer()
    end
    -- else check if game tie
    -- else switch to next player
end

-- Checks if a move caused by tap event is valid
-- False if invalid move
local function checkMove(event)
    print("main square: " .. mainSquare)
    -- determine location of tap on board
    print(players[player].name .. "'s move at square " .. event.target.k)
    -- current player must be human
    if state ~= "waiting" then
        print("\t not waiting for human input - ignore move")
        return false
    end
    -- check if the player can choose a square(mainsquare is 0 in that case)
    if mainSquare == 0 then
        -- current square must be empty if the player is choosing a new square
        if board[event.target.k] ~= 0 then
            print("\t cannot move to non empty space - ignore move")
            return false
        end
        mainSquare = event.target.k
        squares[event.target.k].rect.alpha = 0.5
        return true
    end

    -- check that the subsquare is empty
    -- this only runs if main square has already been chosen
    if subboards[mainSquare][event.target.k] ~= 0 then
        print("\t cannot move to non empty space - ignore move")
        return false
    end
    -- implement valid move
    move(mainSquare, event.target.k)
end

-- reset game state (without unnecessary destroying)
resetBoard = function()
    -- tidy up of UI elements
    for _, square in ipairs(squares) do
        display.remove(square.symbol)
        square.symbol = nil
        for _, subsquare in ipairs(square.subsquares) do
            display.remove(subsquare.symbol)
            subsquare.symbol = nil
        end
    end
    local tieCount = gameCount - players[1].wins - players[2].wins
    local s = string.format("Games: %3d    %s: %d    %s: %d    tie: %d", gameCount, players[1].name, players[1].wins,
        players[2].name, players[2].wins, tieCount)
    statsText.text = s
    gameOverImage.alpha = 0
    gameOverText.text = ""
    -- reset game logic
    board = {}
    for k = 1, 9 do
        board[k] = 0
        subboards[k] = {}
        for i = 1, 9 do
            subboards[k][i] = 0
        end
    end
    nextPlayer(1)
end

local function createBoard()
    for r = 1, 3 do
        for c = 1, 3 do
            -- Draw the subboards
            drawBoard(subboardScale, "slategray",
            {
                x = display.contentCenterX + size * signs[r],
                y = display.contentCenterY + size * signs[c]
            })
        end
    end
    drawBoard(1)

    for k = 1, 9 do
        local row, col = mylib.k2rc(k)
        local x = display.contentCenterX + (col - 4 / 2) * size
        local y = display.contentCenterY + (row - 4 / 2) * size
        local rect = display.newRect(uiGroup, x, y, size - gap, size - gap)
        rect.alpha = 0.05
        rect.k = k
        rect:addEventListener("tap", checkMove)
        squares[k] = {
            rect = rect,
            subsquares = {}
        }
        for i = 1, 9 do
            squares[k].subsquares[i] = {}
        end
    end
    -- Transparent overlay
    gameOverImage = display.newRect(mainGroup, 0, 0, display.actualContentWidth, display.actualContentHeight)
    gameOverImage.x = display.contentCenterX
    gameOverImage.y = display.contentCenterY
    gameOverImage:setFillColor(colors.RGB("black"))
    gameOverImage.alpha = 0

    -- Instantiating text
    titleText = display.newText(uiGroup, "X's and O's", 100, 200, "assets/fonts/Bangers.ttf", 40)
    titleText.x = display.contentCenterX
    titleText.y = display.contentCenterY - 2.5 * size
    titleText:setFillColor(colors.RGB("moccasin"))

    statsText = display.newText(uiGroup, "", 100, 200, "assets/fonts/Bangers.ttf", 26)
    statsText.x = display.contentCenterX
    statsText.y = display.contentCenterY - 2 * size
    -- Initiate game over text
    gameOverText = display.newText(uiGroup, "", 100, 200, "assets/fonts/Bangers.ttf", 40)
    gameOverText.x = display.contentCenterX
    gameOverText.y = display.contentCenterY - size
    gameOverText:setFillColor(colors.RGB("pink"))

    tapSound = audio.loadSound("assets/audio/tapSound.mp3")
    buttonSound = audio.loadSound("assets/audio/buttonSound.mp3")
    winSound = audio.loadSound("assets/audio/winSound.mp3")

    resetBoard()
end

createBoard()
