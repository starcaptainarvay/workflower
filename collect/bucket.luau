local debug = require(script.Parent.Parent.debug)
local event = require(script.Parent.Parent.event)
local util  = require(script.Parent.util)

local bucket = {}
bucket.__index = bucket

type AbstractBucket = {
    contents: { any },
    get: (Bucket) -> any...
}

export type Bucket = AbstractBucket & event.Observable

function bucket.new(_next): Bucket
    local _bucket = setmetatable({ contents = {}, _events = {} }, bucket)

    local function cell_fn(...)
        _bucket:set(...)

        return _next, ...
    end

    return _bucket, cell_fn
end

function bucket.get(self: Bucket): any...
    return unpack(self.contents)
end

function bucket.set(self: Bucket, ...)
    self.contents = {...}
    self:dispatch("value", ...)
end

local function string_and_indent(v)
    if v == nil then return "" end
    return tostring(v):gsub("\n", "\n\t")
end

function bucket.__tostring(self)
    local open, close = debug.format("Bucket {", debug.formatting.presets.fg_blue, debug.formatting.presets.bold),
        debug.format("}", debug.formatting.presets.fg_blue, debug.formatting.presets.bold)

    local content = "  " .. debug.format(
        table.concat(util.map(self.contents, string_and_indent), ",\t"),
            debug.formatting.presets.fg_white,
            debug.formatting.presets.bold) .. "  "

    return open .. content .. close
end

bucket.on           = event.observable.on
bucket.once         = event.observable.once
bucket.dispatch     = event.observable.dispatch

return bucket