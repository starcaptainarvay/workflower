local pipe = {}

function pipe.new(_next: string, fn: (any...) -> (any...)): (any...) -> (string, any...)
    local function cell_fn(...)
        fn(...)

        return _next, ...
    end

    return cell_fn
end

return pipe