local wf = require("workflower")

---@diagnostic disable-next-line: undefined-global
describe("Queue", function()
    it("should push and pop items", function()
        local queue, cell_fn = wf.queue(nil)
        cell_fn(1, 2, 3)
        assert.equals(1, queue:size())
        assert.same({1, 2, 3}, {queue:pop()})
    end)

    it("should iterate over items", function()
        local queue, cell_fn = wf.queue(nil)
        cell_fn(1, 2, 3)
        cell_fn(4, 5, 6)
        local items = {}
        for a, b, c in queue:iterator() do
            table.insert(items, {a, b, c})
        end
        assert.same({{1, 2, 3}, {4, 5, 6}}, items)
    end)

    it("should consume items", function()
        local queue, cell_fn = wf.queue(nil)
        cell_fn(1, 2, 3)
        cell_fn(4, 5, 6)
        local items = {}
        for a, b, c in queue:consume() do
            table.insert(items, {a, b, c})
        end
        assert.same({{1, 2, 3}, {4, 5, 6}}, items)
        assert.equals(0, queue:size())
    end)
end)
