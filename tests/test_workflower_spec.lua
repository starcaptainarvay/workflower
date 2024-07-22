local wf = require("workflower")

---@diagnostic disable-next-line: undefined-global
describe("Workflower", function()
    it("should create a new Workflower instance", function()
        local flower = wf.new({ "start" })
        assert.is_not_nil(flower)
    end)

    it("should create a new cell", function()
        local flower = wf.new({ "start" })
        local cell = wf.cell(flower, "start", function() return "next" end)
        assert.is_not_nil(cell)
        assert.equals("start", cell.id)
    end)

    it("should execute a Workflower", function()
        local flower = wf.new({
            "start",
            { "start", "end" },
            start = function() return "end" end,
            ["end"] = function() return nil, "finished" end
        })
        local result = { flower() }
        assert.equals("finished", result[1])
    end)

    it("should fire \"value\" when pushing items", function(done)
        local queue, cell_fn = wf.queue(nil)
        queue:on("value", function()
            assert.equals(1, queue:size())
            assert.same({1, 2, 3}, {queue:pop()})
            done()
        end)
        cell_fn(1, 2, 3)
    end)
end)
