local wf = require("workflower")

---@diagnostic disable-next-line: undefined-global
describe("Observable Events", function()
    it("should register and dispatch events", function(done)
        local observable = wf.observable()
        local received = false
        observable:on("testEvent", function(data)
            received = data
            assert.is_true(received)
            done()
        end)
        observable:dispatch("testEvent", true)
    end)

    it("should register and trigger once events", function(done)
        local observable = wf.observable()
        local call_count = 0
        observable:once("testEvent", function()
            call_count = call_count + 1
            assert.equals(1, call_count)
            done()
        end)
        observable:dispatch("testEvent")
        observable:dispatch("testEvent")
    end)
end)
