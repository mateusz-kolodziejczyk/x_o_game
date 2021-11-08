-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

mylib = require("mylib")
rng = require("rng")
colors = require("colorsRGB")
-- ai= require("first_space_player")
-- ai=require("rule_based_player")
-- ai = require("minimax_player")
rng.randomseed(os.time())

local backGround = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local board = {} -- 2d repressenation of game board (logic)
local squares = {} -- 1d represetation of game board (ui, events)


----------------
-- Logic functions
----------------
