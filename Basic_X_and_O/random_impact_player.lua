local ai = {}
local mylib = require('mylib')

ai.move = function(board, players, player)
    for row = 1, 3 do
        for col = 1, 3 do
            if board[row][col] == 0 then 
                return mylib.rc2k(row, col)
            end
        end
    end
    -- Shouldn't happen, but if no empty spaces then return 0
    return 0
end


return ai