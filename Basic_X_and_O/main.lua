-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

local mylib = require("mylib")
local rng = require("rng")
local colors = require("colorsRGB")
--ai= require("first_space_player")
--ai=require("random_impact_player")
ai = require("minimax_player")
rng.randomseed(os.time())

local backGroup = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local board = {} -- 2d repressenation of game board (logic)
local squares = {} -- 1d represetation of game board (ui, events)

local players = {
    {name="X", human=true, value=1, wins=0},
    {name="O", human=false, value=-1, wins=0},
}
local player = 1 -- current player
local gameCount = 0
local state -- 'waiting', 'thinking', 'over'

local gap = 6
local size = (math.min(display.contentWidth, display.contentHeight) - 4*gap) / 3

local background = display.newImageRect(backGroup,"assets/images/background.png", 444, 794)
background.x = display.contentCenterX
background.y = display.contentCenterY

local titleText, startsTest, turnText, gameOverText
local gameOverImage


-- Functions
local resetBoard, move
-----------------------------------------------------------------------------------------
-- audio setup
-----------------------------------------------------------------------------------------
local tapSound, winSound, buttonSound

audio.reserveChannels( 3 )

-- Reduce the overall volume of the channel
local bgMusic = audio.loadStream( "assets/audio/bgMusic.mp3" )

audio.setVolume( 0.4, { channel=1 } )
audio.setVolume( 0.8, { channel=2 } )
audio.setVolume( 0.9, { channel=3 } )
-- audio.play( bgMusic, { channel=1, loops=-1 } )

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
    gameOverText.text = message
    gameOverImage.alpha = 0.5
    timer.performWithDelay(2500,resetBoard)

end

-- Switch to next player or given player index
local function nextPlayer(value)
    player = value or (player%2 + 1)

    state = players[player].human and "waiting" or "thinking"

    if state == 'thinking' then
        i = ai.move(board, players, player)
        print("Chosen k: " .. i)
        move(i)
    end
end

-- carries out a valid move
move = function(k)
    -- determine location of valid move
    local square = squares[k]

    -- update ui and logic
    local filename = "assets/images/" .. players[player].name .. ".png"
    local symbol = display.newImageRect(mainGroup, filename, size-4*gap, size-4*gap)
    symbol.x = square.rect.x
    symbol.y = square.rect.y
    square.symbol = symbol
    board[k] = players[player].value
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
    -- determine location of tap on board
    print(players[player].name .. "'s move at square " .. event.target.k)
    -- current player must be human
    if state~="waiting" then
        print("\t not waiting for human input - ignore move")
        return false
    end
    -- current square must be empty
    if board[event.target.k] ~= 0 then
        print("\t cannot move to non empty space - ignore move")
        return false
    end
    -- implement valid move
    move(event.target.k)
end

-- reset game state (without unnecessary destroying)
resetBoard = function ()

    -- tidy up of UI elements
    for _, square in ipairs(squares) do
        display.remove(square.symbol)
        square.symbol = nil
    end
    local tieCount = gameCount - players[1].wins - players[2].wins
    local s = string.format("Games: %3d    %s: %d    %s: %d    tie: %d",
        gameCount, 
        players[1].name, players[1].wins, 
        players[2].name, players[2].wins, 
        tieCount
    )
    statsText.text = s
    gameOverImage.alpha = 0
    gameOverText.text = ""
    -- reset game logic
    board = {}
    for k = 1, 9 do
            board[k] = 0
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
    -- Transparent overlay
    gameOverImage = display.newRect(mainGroup, 0, 0, display.actualContentWidth, display.actualContentHeight)
    gameOverImage.x = display.contentCenterX
    gameOverImage.y = display.contentCenterY
    gameOverImage:setFillColor(colors.RGB("black"))
    gameOverImage.alpha = 0

    -- Instantiating text
    titleText = display.newText(uiGroup, "X's and O's", 100, 200, "assets/fonts/Bangers.ttf", 40)
    titleText.x = display.contentCenterX
    titleText.y = display.contentCenterY - 2.5*size
    titleText:setFillColor(colors.RGB("moccasin"))

    statsText = display.newText(uiGroup, "", 100, 200, "assets/fonts/Bangers.ttf", 26)
    statsText.x = display.contentCenterX
    statsText.y = display.contentCenterY - 2*size
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