# Workflower
#### by [starcaptainarvay](https://github.com/starcaptainarvay)
The `workflower` library is designed to create and manage a directed graph of computational cells, allowing conditional branching based on the return values of cell functions. This library is useful for workflows, state machines, or any process where the flow of execution can change dynamically.

## Table of Contents

- [Installation](#installation)
- [Key Concepts and Components](#key-concepts-and-components)
  - [Workflower Construction](#workflower-construction)
  - [Workflower Class](#workflower-class)
  - [Cells](#cells)
  - [Bucket Class](#bucket-class)
- [Usage](#usage)
  - [Creating a New Workflower Instance](#creating-a-new-workflower-instance)
  - [Adding and Retrieving Cells](#adding-and-retrieving-cells)
  - [Executing the Workflow](#executing-the-workflow)
  - [Using Buckets](#using-buckets)
- [Practical Example: Customer Order Processing Workflow](#example-customer-order-processing-workflow)
  - [Applying Buckets for Logging](#practical-example-logging-order-details)
- [Debugging](#debugging-cells)
  - [Debugging cells](#debugging-cells)
- [Events](#events-and-observables)
  - [Usage](#using-events-and-observables)
- [Using Queues](#queues)
- [License](#license)

## Installation

Include the `workflower` library in your project by copying the files into your project directory.

## Key Concepts and Components

### Workflower Construction
```lua
local workflower = require("workflower")

local workflowerOptions = {
    'entry', -- first cell that gets called
    {'entry', 'node2', 'node3', ...} --[[ 
        order of cells to call, although this can change dynamically based on the 
        first return value of each cell to create more complex state machines
    ]] 

    entry = entry_function: function,
    node2 = node2_function: function,
    ...
}

local workflow = workflower(workflowerOptions) -- pass the options into the workflower constructor
```
Defines the structure of the options table that initializes the workflower. It includes an entry point and a graph structure that specifies the order and possible branches of cells.

### Workflower Class
The main class that represents the directed graph of computational cells. It includes methods to create a new instance, add cells, retrieve cells, and execute the workflow.

### Cells
Individual computational steps within the workflower. Each cell has an identifier and a function that performs the computation and can return the next cell to execute, as well as the return values of the function itself.

```lua
local function example_cell(arg1, arg2, arg3)
    local result2 = arg2
    local result3 = arg3
    
    if arg1 > 3 then
        local result1 = "greater than 3"
        return 'example_cell_4', result1, result2, result3 
        -- the next cell, "example_cell_4" is passed result1, result2, and result3
    end

    local result1 = "less than 3"
    return 'example_cell_2', result1, result2
    -- the next cell, "example_cell_2" is passed result1 and result2
end
```

### Bucket Class
A simple state wrapper that can store and retrieve values during the workflow execution. It can be used to capture intermediate results without disrupting the flow.

### Pipes
`workflower.pipe(fn: function)` returns a cell that wraps the function `fn`, and calls `fn` on the side with whatever passes through the cell. 

## Usage

### Creating a New Workflower Instance

You can create a new workflower instance by specifying the entry point and the graph structure. The graph structure defines the order and possible branches of the cells.

```lua
local workflower = require("workflower")

local wf = workflower({
    "start", -- index [1] will always be the entry point
    {"start", "process", "end"}, -- index [2] will always be the directed graph of the flow
    
    ['start'] = start -- this is a function that takes the initial input,
    ['process'] = process -- this is a function that takes the output from 'start',
    ['end'] = finish -- this is a function that takes the output from 'process'
})
```

### Adding and Retrieving Cells

Cells can be added to the workflower with specific identifiers and functions. These functions define what each cell does and how it determines the next cell to execute.

```lua
local function start(...)
    print("Starting", ...)
    return "process", ...
end

local function process(...)
    print("Processing", ...)
    return "end", ...
end

local function finish(...)
    print("Ending", ...)
    return nil, ...
end
```

### Executing the Workflow

The workflower can be executed as a function. Starting from the entry point, each cell’s function is executed, and based on its return value, the next cell in the graph is determined and executed.

```lua
wf(...) -- Basically returns the result of finish(nil, process(nil, start(...)))
```
This is a pretty bare-bones case that only really demonstrates how Workflower can run a state machine in order, but the utility of the library comes from using a combination of the tools it offers.

Let's create a practical example of a simple workflow that models a real-world problem. Suppose we want to model a basic customer order processing system. 
The workflow will include steps such as receiving an order, processing payment, checking inventory, and shipping the order.
## Example: Customer Order Processing Workflow
### Cell Functions
- Receive Order: Start the workflow by receiving an order.
- Process Payment: Process the payment for the order.
- Check Inventory: Check if the ordered items are in stock.
- Ship Order: Ship the order if items are in stock.
- Out of Stock: Handle the case where items are out of stock.


```lua
-- Define cell functions
local function receive_order(order)
    print("Order received:", order)
    return "process_payment", order
end

local function process_payment(order)
    print("Processing payment for:", order)
    -- Simulate payment processing
    local payment_successful = true
    if payment_successful then
        return "check_inventory", order
    else
        return "payment_failed", order
    end
end

local function check_inventory(order)
    print("Checking inventory for:", order)
    -- Simulate inventory check
    local in_stock = true
    if in_stock then
        return "ship_order", order
    else
        return "out_of_stock", order
    end
end

local function ship_order(order)
    print("Shipping order:", order)
    -- Simulate order shipment
    return nil  -- End of the workflow
end

local function out_of_stock(order)
    print("Order is out of stock:", order)
    -- Handle out of stock situation
    return nil  -- End of the workflow
end
```
### Let's turn this into a workflow:

```lua
local workflower = require("workflower")

-- Create a new workflower instance
local processOrder = workflower({
    "receive_order",
    {"receive_order", "process_payment", "check_inventory", {"ship_order", "out_of_stock"}},
    receive_order = receive_order,
    process_payment = process_payment,
    check_inventory = check_inventory,
    ship_order = ship_order,
    out_of_stock = out_of_stock
})

-- Execute the workflower with an order
processOrder("Order #12345")
```

Note that `"ship order"` and `"out_of_stock"` are listed in a subarray. This is to declare that they are alternatives and the flow at that point will be decided in realtime based on the internal cell logic preceding it.

## Using Buckets
Buckets in the workflower library are simple state wrappers designed to store and retrieve values during the workflow execution.

You can make one like this:

```lua
local bucket_A, cell_A = workflower.bucket(next_cell_name: string)
```

To use it in a workflow, just pass `cell_A` as another cell and whenever it gets called in the flow, the bucket gets populated with the input at that point.

To access the value in the bucket you can just use `:get()` anywhere. Here's an example.
```lua
local bucket_A, cell_A = workflower.bucket('third_cell')

local flow = workflower({
    'first_cell'
    {'first_cell', 'second_cell', 'bucket_cell', 'third_cell'}
    first_cell = ...,
    ...
    bucket = cell_A,
    third_cell = ...
})

flow(1, 2, 3)
```
This passes through `first_cell` and `second_cell`. Assuming neither cell redirects the flow somewhere else, and doesn't mutate the input, `bucket_cell` would also receive `(1, 2, 3)` and store it in `bucket_A` before passing those values onto `third_cell`.

Which would mean:
```lua
flow(1, 2, 3)
print(bucket_A:get()) 
-- 1, 2, 3
```

## Practical Example: Logging Order Details
Going back to the order example, we can use a bucket to log the order details without affecting the main workflow.

### Cell Functions
- **Receive Order**: Start the workflow by receiving an order.
- **Log Order**: Log the order details using a bucket.
- **Process Payment**: Process the payment for the order.
- **Finish Order**: Complete the workflow.

```lua
-- Create a bucket for logging order details
local order_log_bucket, log_order = workflower.bucket("process_payment")

local processOrder = workflower({
    "receive_order",
    {"receive_order", "log_order", "process_payment", "finish_order"},
    receive_order = receive_order,
    log_order = log_order,
    process_payment = process_payment,
    finish_order = finish_order,
    payment_failed = payment_failed
})

-- Execute the workflower with an order
processOrder("Order #12345")

print("Bucket contents:", order_log_bucket:get())
--[[ 
Order received: Order #12345
Processing payment for: Order #12345
Checking inventory for: Order #12345
Shipping order: Order #12345
Bucket contents: Order #12345
]]
```
## Workflower Inheritance
Of course, since you can instantiate a `Workflower` with parents to inherit from, we can easily rewrite the above example to pass the original `processOrder` as a parent and create a new workflow where the only difference is `log_order`:
```lua
local order_log_bucket, log_order = workflower.bucket("process_payment")

local processOrderAndLog = workflower({
    "receive_order",
    {"receive_order", "log_order", "process_payment", "finish_order"},
    log_order = log_order,
}, processOrder)

processOrderAndLog("Order #12345")
order_log_bucket:get() -- Order #12345
```
**Note** that this would only work if `receive_order` didn't explicitly return its next cell, and instead returned `nil`. When a cell returns `nil` as the first value, the workflow defaults to the order specified in the options it is constructed with.

## Debugging Cells

The `workflower.debug` function allows you to debug individual cells by wrapping them in a debug container. This can help you trace errors and understand the flow of your workflower.

### Usage

To use the `workflower.debug` function, simply wrap your cell function with it when defining your workflower. Here is an example using the customer order processing workflow:

#### Example Workflow

```lua
local workflower = require("workflower")

local function process_payment(order)
    print("Processing payment for:", order)
    -- Simulate an error
    error("Payment processing failed!")
    return "finish_order", order
end

-- Create a new workflower instance
local wf = workflower({
    "receive_order",
    {"receive_order", "log_order", "process_payment", "finish_order"},
    process_payment = workflower.debug(process_payment),
}, processOrder)

-- Execute the workflower with an order
wf({id = "Order #12345", items = {"item1", "item2"}})
```

Output with `process_payment`: 
```
lua: main.lua:20: Payment processing failed!
stack traceback:
    [C]: in function 'error'
    [string "workflower"]:35: in function <[string "workflower"]:34>
    [string "workflower"]:50: in function 'execute'
    main.lua:20: in function <main.lua:15>
    ...
```

Output with `workflower.debug(process_payment)`:
```
Failure in Cell 'process_payment':
    process_payment.lua:5: Payment processing failed!
stack traceback:
    process_payment.lua:5: in function 'process_payment'
    ...
```

## Events and Observables
Workflower provides a powerful event system through observables. Observables allow you to register event listeners and dispatch events to those listeners. This can be particularly useful for managing asynchronous operations or reacting to changes in your application state.

### Using Events and Observables
You can create an observable and register event listeners for specific events. When an event is dispatched, all registered listeners for that event will be called with the provided arguments.

```lua
local wf = require("workflower")

-- Create an observable
local myObservable = wf.observable()

-- Register an event listener
myObservable:on("myEvent", function(data)
    print("myEvent triggered with data:", data)
end)

-- Dispatch the event
myObservable:dispatch("myEvent", "Hello, World!")
```

## Queues
Queues, like Buckets, iare used to collect output at some point in a flow. This happens in a first-in-first-out (FIFO) manner. They are also observable, meaning you can listen for events when items are pushed to the queue. 

Both Buckets and Queues come with a `"value"` event that gets dispatched when their values are updated. In the case of a `Bucket` it's when a new value is **set**, and in the case of a `Queue` it's when a new value is **pushed.**

### Creating and Using Queues
You can create a queue and register event listeners for when new values are pushed to the queue.

```lua
local wf = require("workflower")

-- Create a queue
local myQueue, cell_fn = wf.queue(nil) -- not in a workflow, so nil is passed since we have no next cell

-- Register an event listener for the "value" event
myQueue:on("value", function(...)
    print("New value pushed to the queue:", ...)
end)

-- Push values to the queue
cell_fn(1, 2, 3)
cell_fn("a", "b", "c")
```

### Iterating and Consuming Items in a Queue
You can iterate over the items in a queue using the iterator function, or you can consume (pop) each item using the consume function.


```lua
-- Iterate over the queue without removing items
for i, j, k in myQueue:iterator() do
    print("Queue item:", i, j, k)
end
print(myQueue)

--> Queue item: 1 2 3
--> Queue item: a b c
--> Queue {
--      ( 1, 2, 3 )
--      ( a, b, c )
-- }

-- Consume items from the queue
for i, j in myQueue:consume() do
    print("Consumed queue item:", i, j)
end
print(myQueue)

--> Queue item: 1 2
--> Queue item: a b
--> Queue {}
```


## License
Copyright (c) 2024 Avyay Natarajan. (@starcaptainarvay)

All rights reserved.

This software and associated documentation files (the "Software") may not be used, copied, modified, merged, published, distributed, sublicensed, or sold without prior written permission from the copyright holder.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.