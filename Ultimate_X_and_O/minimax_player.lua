local ai = { }

local rng = require("rng")
local mylib = require("mylib")

local WON = 1000
local subboardWON = 100
local TIE = 500
local subboardTIE = 50

-- visible to game so that it modified by user
ai.maxDepth = 5

-- compute a score for current game state
function ai.eval(board)
    if mylib.isWin(board) then
        return WON
    elseif mylib.isTie(board) then
        return WON/2
    else
        return 0
    end
end

function ai.evalFull(board, subboards)
    -- Check state of full board
    local totalScore = 0
    if mylib.isWin(board) then
        totalScore = totalScore + WON
    elseif mylib.isTie(board) then
        totalScore = totalScore + WON/2
    end
    -- Check each subboard
    for k = 1, 9 do
        if mylib.isWin(subboards[k]) then
            totalScore = totalScore + subboardWON
        elseif mylib.isTie(subboards[k]) then
            totalScore = totalScore + subboardWON/2
        end
    end
    return totalScore
end

function ai.evalSubboard(subboard)
    if subboard ~= 0 then
        return subboardWON
    --elseif mylib.isTie(subboard) then
    --   return subboardWON/2
    else
        return 0
    end
end

-- recursive function to perform minimax search
-- returns score,move
function ai.search(board, subboards, players, player, mainSquare, depth, previousK)

    local debug = false

    depth = depth or 1
    local bestScore = -math.huge
    local bestMove = {k=0, kk=0}

    local indent = string.rep("  ", depth)

    --if debug then print(indent .. "SEARCHING at depth "..depth .." as PLAYER "..players[player].name) end

    -- Immediately return with score if it doesnt return 0


    if ai.eval(board) ~= 0 then
        return ai.eval(board)
    end



    -- check if search reached max depth
    if depth >= ai.maxDepth then
        return bestScore, bestMove
    end
    -- iterate over all possible moves
    for k = mainSquare, 9 do
        -- place piece 
        if board[k] == 0 then
            -- Go through each subboard square
            for kk = 1, 9 do
                -- Make sure its empty
                if subboards[k][kk] == 0 then
                    subboards[k][kk] = players[player].value
                    -- If the move wins the subboard, change the main board value to the player value
                    if mylib.isWin(subboards[k]) then
                        board[k] = players[player].value
                        if subboardWON > bestScore then
                            bestScore = subboardWON
                            bestMove.k = k
                            bestMove.kk = kk
                        end
                        --bestScore = subboardWON
                    -- If the move is a tie, change the value to math.huge
                    elseif mylib.isTie(subboards[k]) then
                        board[k] = math.huge
                        --bestScore = subboardWON/2
                    end
                    
                    if bestScore ~= -math.huge then 
                        print(indent .. "Move " .. k .. "," .. kk .. " with score " .. bestScore .. " by player " .. players[player].name) 
                    end

                    local nextSquare = 0

                    -- Set the next square to the subboard move if the main square is empty
                    if board[kk] == 0 then
                        nextSquare = kk
                    end
                    local score, _ = ai.search(board, subboards, players, player%2+1, nextSquare, depth+1, kk)

                    --if score ~= 0 and score ~= math.huge and score ~= -math.huge then print (indent .. "current score: " .. score) end
                    -- Remove piece from subboard and reset board to 0 
                    subboards[k][kk] = 0
                    board[k] = 0

                    -- if score better than found to date update best score and best move
                    if score > bestScore and score ~= math.huge then
                        bestScore = score
                        bestMove.k = k
                        bestMove.kk = kk
                    end
                end
            end
            -- This means that you only need one loop for both the ai selecting next square and being forced to move on one
            if k ~= 0 and k == mainSquare then
                break
            end
        end

    end

    if debug then print(indent .. "OPTIMAL MOVE "..bestMove.k .. "," .. bestMove.kk .. " with score " ..bestScore) end

    -- return best score and best move
    return -bestScore, bestMove
end



-- public interface to minimax search function
ai.move = function(board, subboards, players, player, nextSquare)
    print("nextSquare: " .. nextSquare)
    local score, move = ai.search(board, subboards, players, player, nextSquare)
    print("OPTIMAL MOVE ".. move.k .. "," .. move.kk .. " with score " .. score)
    return move.k, move.kk
end

return ai