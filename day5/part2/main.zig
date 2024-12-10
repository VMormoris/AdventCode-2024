const std = @import("std");

pub fn main() !void {
    const input = try readFileAsSting("part2/input.txt");
    const orders = try parseOrders(input);
    var queues = try parseQueues(input);
    
    
    defer queues.deinit();
    // {// Debug:
    //     var it = orders.iterator();
    //     while(it.next()) |order_entry| {
    //         std.log.debug("{d}: [{d}]", .{order_entry.key_ptr.*, order_entry.value_ptr.items});
    //     }
    // }

    const validity = try checkQueuesValidity(queues, orders);
    var sum: i64 = 0;
    for (validity.items, 0..) |is_queue_valid, idx| {
        if (!is_queue_valid) {
            fixQueue(queues.items[idx].items, orders);
            
            var mid_idx =  queues.items[idx].items.len / 2;
            if (queues.items[idx].items.len % 2 == 0) { mid_idx += 1; } 

            const mid_page = queues.items[idx].items[mid_idx];
            // std.log.debug("{d}", .{mid_page});
            sum += mid_page;
        }
    }
    std.log.info("{d}", .{sum});

}

fn fixQueue(queue: []i64, orders: std.AutoHashMap(i64, std.ArrayList(i64))) void {
    var idx: usize = 0;
    while (idx < queue.len) {
        const page = queue[idx];
        if (orders.get(page)) |befores| {
            var max_idx: usize = 0;
            for (befores.items) |before| {
                if (std.mem.lastIndexOf(i64, queue[idx..], &[_]i64{before})) |index| {
                    max_idx = @max(index + idx, max_idx);
                }
            }
            if (max_idx > idx) {
                std.log.debug("swaping: {d} with {d}", .{idx, max_idx});
                swap(queue, idx, max_idx);
            } else { idx += 1; }
        } else { idx += 1; }
    }
}

fn swap(queue: []i64, idx0: usize, idx1: usize) void {
    const aux = queue[idx0];
    queue[idx0] = queue[idx1];
    queue[idx1] = aux;
}

fn checkQueuesValidity(queues: std.ArrayList(std.ArrayList(i64)), orders: std.AutoHashMap(i64, std.ArrayList(i64))) !std.ArrayList(bool) {
    var validity = std.ArrayList(bool).init(std.heap.page_allocator);
    for (queues.items) |queue| {
        var queue_result = true;
        for (queue.items, 0..) |page, idx| {
            var queue_diagnosis = false;
            if (orders.get(page)) |befores| {
                for (befores.items) |before| {
                    if (std.mem.indexOf(i64, queue.items[idx..], &[_]i64{before})) |_| {
                        queue_diagnosis = true;
                        queue_result = false;
                        break;
                    }
                }
                if (queue_diagnosis) break;
            }
        }
        try validity.append(queue_result);
    }
    return validity;
}

fn parseQueues(input: []const u8) !std.ArrayList(std.ArrayList(i64)) {
    var parts = std.mem.split(u8, input, "\n\n");
    _ = parts.next();
    
    var queues = std.ArrayList(std.ArrayList(i64)).init(std.heap.page_allocator);
    errdefer queues.deinit();

    if (parts.next()) |part| {
        var lines = std.mem.split(u8, part, "\n");
        while(lines.next()) |line| {
            var numbers = std.mem.split(u8, line, ",");
            var queue = std.ArrayList(i64).init(std.heap.page_allocator);
            while(numbers.next()) |str_number| {
                const number = try std.fmt.parseInt(i64, str_number, 10);
                try queue.append(number);
            }
            try queues.append(queue);
        }
    }

    return queues;
}

fn parseOrders(input: []const u8) !std.AutoHashMap(i64, std.ArrayList(i64)) {
    var map = std.AutoHashMap(i64, std.ArrayList(i64)).init(std.heap.page_allocator);
    errdefer {
        var it = map.iterator();
        while (it.next()) |entry| {
           entry.value_ptr.deinit();
        }
        map.deinit();
    }

    var parts = std.mem.split(u8, input, "\n\n");
    if (parts.next()) |part| {
        var lines = std.mem.split(u8, part, "\n");
        while (lines.next()) |line| {
            var numbers = std.mem.split(u8, line, "|");
            const before = if (numbers.next()) |str_number| try std.fmt.parseInt(i64, str_number, 10) else -1;
            const after = if (numbers.next()) |str_number| try std.fmt.parseInt(i64, str_number, 10) else -1;

            if (map.contains(after)) {
                var list = map.get(after).?;
                try list.append(before);
                try map.put(after, list);
            } else {
                var list = std.ArrayList(i64).init(std.heap.page_allocator);
                try list.append(before);
                try map.put(after, list);
            }
        }
    }
    return map;
}

fn readFileAsSting(filepath: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // Read big line
    var buffer: [240000]u8 = undefined;
    const maybe_line = try reader.readUntilDelimiterOrEof(&buffer, 0);
    return if (maybe_line) |line| line else &[_]u8{};
}