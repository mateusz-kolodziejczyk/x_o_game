local ai = {}
local mylib = require('mylib')
ai.move = function(board, players, player)
    for k = 1, 9 do
        if board[k] == 0 then return k end
    end
    -- Shouldn't happen, but if no empty spaces then return 0
    return 0
end


return ai