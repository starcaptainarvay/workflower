local observable = {}
observable.__index = observable

export type Callback = (any...) -> any...

export type Observer = {
    id: number,
    callback: Callback,
    disabled: boolean?,
    executeOnce: boolean?,
    disconnect: (self: Observer) -> boolean
}

export type Observable = {
    _events: { [string]: { Observer } },
    on: (self: Observable, event: string, callback: Callback) -> Observer,
    once: (self: Observable, event: string, callback: Callback) -> Observer,
    dispatch: (self: Observable, string, any...) -> nil,
}

function observable.new(): Observable
    return setmetatable({ _events = {} }, observable)
end

local function initialize_and_get_event_connections(obs: Observable, event: string): { Observer }
    obs._events[event] = obs._events[event] or {}
    return obs._events[event]
end

local function disconnect_and_shift_list(list, handle): boolean
    if table.remove(list, handle.id) then
        for i = handle.id, #list do
            list[i].id = list[i].id - 1
        end
        return true
    end
    return false
end

local function create_and_insert_handle(list, fn, executeOnce): Observer
    local handle = {
        id = #list + 1,
        callback = fn,
        disconnect = function(self)
            self.disabled = true
            return disconnect_and_shift_list(list, self)
        end,
        executeOnce = executeOnce
    }

    table.insert(list, handle)
    return handle
end

function observable.on(self: Observable, event: string, callback: Callback): Observer
    local event_list = initialize_and_get_event_connections(self, event)
    return create_and_insert_handle(event_list, callback, false)
end

function observable.once(self: Observable, event: string, callback: Callback): Observer
    local event_list = initialize_and_get_event_connections(self, event)
    return create_and_insert_handle(event_list, callback, true)
end

function observable.dispatch(self: Observable, event: string, ...: any)
    if not self._events[event] then return end

    for _, handle in pairs(self._events[event]) do
        if not handle.disabled then
            task.spawn(handle.callback, ...)

            if handle.executeOnce then
                handle:disconnect()
            end
        end
    end
end

local GLOBAL_EVENT_DISPATCHER = observable.new()

return {
    _events = GLOBAL_EVENT_DISPATCHER._events,
    observable = observable,
    on = observable.on,
    once = observable.once,
    dispatch = observable.dispatch
}