local wf = require("workflower")

---@diagnostic disable-next-line: undefined-global
describe("Bucket", function()
    it("should set and get value", function(done)
        local bucket, cell_fn = wf.bucket(nil)
        bucket:on("value", function()
            assert.equals(42, bucket:get())
            done()
        end)
        cell_fn(42)
    end)

    it("should trigger \"value\" event", function(done)
        local bucket, cell_fn = wf.bucket(nil)
        local received = nil
        bucket:on("value", function(value)
            received = value
            assert.equals(42, received)
            done()
        end)
        cell_fn(42)
    end)
end)
