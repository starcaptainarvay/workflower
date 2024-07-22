--- Workflower module implementation

local event = require(script:WaitForChild("event"))
local debug = require(script:WaitForChild("debug"))
local stringify = require(script:WaitForChild("stringify"))

local collect = script:WaitForChild("collect")
local bucket, pipe, queue = require(collect.bucket),
                            require(collect.pipe),
                            require(collect.queue)

--[=[
    @module workflower
    Workflower 0.1.0 module documentation.
    The workflower library provides a structured way to define and execute a series of computational steps, or "cells," which can branch conditionally 
    based on the outputs of these cells. This is useful for workflows, pipelines, state machines, or any process where the flow of execution can change dynamically.
]=]
local workflower = {}

export type Observable = event.Observable
export type Observer = event.Observer
export type Bucket = bucket.Bucket
export type Queue = queue.Queue

export type Workflower = {
    _cells: { [string]: any },
    _entry: string,
    _graph: { any },
    _events: { [string]: any },
    __call: (self: Workflower, ...any) -> ...any
}

export type CellFunction = (any...) -> (string, any...)

export type Cell = {
    flower: Workflower,
    id: string,
    fn: CellFunction,
    pass: (self: Cell, call_index: number, ...any) -> (string?, { any })
}

local reserved_indexes = { [1] = true, [2] = true }
local get_instance_content = {}

--[=[
    Creates a new Workflower instance.
    @param options table The options table containing entry point and graph structure.
    @param ... any Any parent Workflower instances to inherit from.
    @return Flower The new Workflower instance.
]=]
function workflower.new(options: { [any]: any }, ...: Workflower): Workflower
    local parents: { Workflower } = { ... }
    local flower = setmetatable({
        _cells = {},
        _entry = options[1],
        _graph = options[2] or {},
        _events = {}
    }, get_instance_content) :: Workflower

    if #parents > 0 then
        for _, parent in pairs(parents) do
            for cell_id, cell_fn in pairs(parent._cells) do
                if not reserved_indexes[cell_id] then flower:cell(cell_id, cell_fn) end
            end
        end
    end

    if options then
        for cell_id, cell_fn in pairs(options) do
            if not reserved_indexes[cell_id] then flower:cell(cell_id, cell_fn) end
        end
    end

    return flower
end

local function create_key_function(next_cell: string | ((...any) -> string?)): (...any) -> string?
    if type(next_cell) == "string" then
        return function()
            return next_cell
        end
    elseif type(next_cell) == "function" then
        return function(...)
            return (next_cell :: (...any) -> string?)(...)
        end
    else
        return function()
            return nil
        end
    end
end

--[=[
    Converts a function into a cell function.
    @param cell_fn function The function to convert into a cell function.
    @param next_cell string|function The next cell or a function that returns the next cell.
    @return function The cell function.
]=]
function workflower.cellify(cell_fn: (...any) -> ...any, next_cell: string | ((...any) -> string?)): (...any) -> (string?, ...any)
    local key = create_key_function(next_cell)

    return function(...)
        return key(...), cell_fn(...)
    end
end

--[=[
    Adds a cell to the Workflower instance.
    @param flower Flower The Workflower instance.
    @param id string The cell identifier.
    @param fn function The function to execute for this cell.
    @return Cell The created cell.
]=]
function workflower.cell(flower: Workflower, id: string, fn: (...any) -> ...any): Cell
    if type(fn) == "table" and fn.is_debug_cell_container then
        fn = debug.debug_cell(fn, id, flower)
    end

    local function _pass(self: Cell, call_index: number, ...: any): (string?, { any } )
        local results = { fn(...) }
        local _next = table.remove(results, 1)

        return _next or self.flower._graph[call_index + 1], results
    end

    local cell = {
        flower = flower,
        id = id,
        fn = fn,
        pass = _pass
    } :: Cell

    flower._cells[id] = cell

    return cell
end

--[=[
    Retrieves a cell from the Workflower instance.
    @param flower Flower The Workflower instance.
    @param cell_id string The cell identifier.
    @return Cell The requested cell.
]=]
function workflower.get_cell(flower: Workflower, cell_id: string): Cell
    return flower._cells[cell_id]
end

local get_instance_content_defaults = {
    cell = true,
    get_cell = true,
    on = event.observable.on,
    once = event.observable.once,
    dispatch = event.observable.dispatch
}

local get_instance_content_raw = {
    _cells = true,
    _entry = true,
    _graph = true
}

function get_instance_content.__index(self: Workflower, key: string): any
    if get_instance_content_raw[key] then
        return rawget(self, key)
    elseif get_instance_content_defaults[key] then
        return workflower[key]
    end
end

function get_instance_content.__call(self: Workflower, ...: any): ...any
    return workflower.execute(self:get_cell(self._entry), 1, ...)
end

function get_instance_content.__tostring(self: Workflower): string
    return stringify(self)
end

--[=[
    Executes a cell and its subsequent cells based on the graph.
    @param cell Cell The cell to start execution from.
    @param call_index number The current index in the execution sequence.
    @param ... any Additional arguments to pass to the cell function.
    @return any The final results of the execution.
]=]
function workflower.execute(cell: Cell, call_index: number, ...: any): ...any
    local _next, results = cell:pass(call_index, ...)
    local _next_cell = workflower.get_cell(cell.flower, _next)

    if _next == "error" then
        local err_string = results[1]
        if not _next_cell then -- no error handler
            error(err_string, 2)
        end
    end

    if _next_cell then
        return workflower.execute(_next_cell, call_index + 1, unpack(results))
    end

    return unpack(results)
end

--[=[
    Creates a new Bucket instance.
    @param _next string The next cell identifier.
    @return table, function The new Bucket instance and its corresponding cell function.
]=]
function workflower.bucket(_next: string): (Bucket, CellFunction)
    return bucket.new(_next)
end

--[=[
    Creates a new Pipe instance.
    @param _next string The next cell identifier.
    @param fn function The function to execute for this pipe.
    @return function The new pipe function.
]=]
function workflower.pipe(_next: string, fn: (...any) -> ...any): (...any) -> (string?, ...any)
    return pipe.new(_next, fn)
end

--[=[
    Creates a new Queue instance.
    @param _next string The next cell identifier.
    @return table, function The new Queue instance and its corresponding cell function.
]=]
function workflower.queue(_next: string): (Queue, CellFunction)
    return queue.new(_next)
end

--[=[
    Wraps a Workflower cell into a debugger that outputs an accurate trace on error.
    @param fn function The function to debug.
    @return table The debug cell container.
]=]
function workflower.debug(fn: (...any) -> ...any): any
    return debug.debug_cell_container(fn)
end

--[=[
    Creates a new observable instance.
    @return table The new observable instance.
]=]
function workflower.observable(): Observable
    return event.observable.new()
end

workflower.debugging = {
    formatting = debug.formatting,
    format = debug.format
}

workflower.event = {
    _events = {},
    dispatch = event.dispatch,
    on = event.on,
    once = event.once,
    observable = event.observable
}

function get_lib_content(self: any, key: string): any
    return workflower[key]
end

local __meta = {
    __call = function(_, ...)
        return workflower.new(...)
    end,
    __index = get_lib_content,
    __newindex = function() end
}

return setmetatable({}, __meta) :: typeof(workflower)