local debug = require(script.Parent.Parent.debug)
local event = require(script.Parent.Parent.event)
local util  = require(script.Parent.util)

local queue = {}
queue.__index = queue

type AbstractQueue = {
    list: { { any } },
    empty: (Queue) -> boolean,
    get: (Queue, number) -> any...,
    pop: (Queue) -> any...,
    peek: (Queue) -> any...,
    push: (Queue, any...) -> nil,
    size: (Queue) -> number,
    iterator: (Queue) -> (() -> any?),
    consume: (Queue) -> (() -> any?)
}

export type Queue = AbstractQueue & event.Observable

function queue.new(_next: string): (Queue, (any...) -> (string, any...))
    local _queue: Queue = setmetatable({ list = {}, _events = {} }, queue)

    local function cell_fn(...)
        _queue:push({...})

        return _next, ...
    end

    return _queue, cell_fn
end

function queue.size(self: Queue): number
    return #self.list
end

function queue.get(self: Queue, i: number)
    return unpack(self.list[i])
end

function queue.pop(self: Queue)
    return unpack(table.remove(self.list, 1))
end

function queue.peek(self: Queue)
    return unpack(self.list[1])
end

function queue.empty(self: Queue): boolean
    return #self.list == 0
end

function queue.push(self: Queue, item)
    table.insert(self.list, item)
    self:dispatch("value", unpack(item))
end

function queue.iterator(self: Queue): () -> any?
    local index = 0
    local function iterate()
        index = index + 1
        if index <= #self.list then return self:get(index) end
    end

    return iterate
end

function queue.consume(self: Queue): () -> any?
    local function iterate()
        if not self:empty() then return self:pop() end
    end

    return iterate
end

local function string_and_indent(v)
    return tostring(v):gsub("\n", "\n\t")
end

function queue.__tostring(self: Queue)
    local open, close = debug.format("Queue {", debug.formatting.presets.fg_green, debug.formatting.presets.bold),
        debug.format("}", debug.formatting.presets.fg_green, debug.formatting.presets.bold)

    local newline = "\n"
    if self:empty() then newline = "" end

    local content = newline
    for i = 1, self:size() do
        content = content .. debug.format("\t(  ", debug.formatting.presets.fg_blue)
        content = content .. debug.format(
            table.concat(util.map(self.list[i], string_and_indent), ",\t\t"),
            debug.formatting.presets.fg_white,
            debug.formatting.presets.bold)
        content = content .. debug.format("  )", debug.formatting.presets.fg_blue)

        if i < self:size() then
            content = content .. ",\n"
        end
    end

    content = content .. newline

    return open .. content .. close
end

queue.on           = event.observable.on
queue.once         = event.observable.once
queue.dispatch     = event.observable.dispatch

return queue