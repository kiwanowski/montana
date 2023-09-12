function increment(var, value, limit)
    var = var + value
    if var > limit then
        var = limit
    end
    return var
end

function decrement(var, value, limit)
    var = var - value
    if var < limit then
        var = limit
    end
    return var
end