const std = @import("std");

const Equation = struct {
    lhs: i64,
    rhs: std.ArrayList(i64),
};

pub fn main() !void {   
    const equations = try readFileAsSting("part1/input.txt");
    var sum: i64 = 0;
    for(equations.items) |equation| {
        // std.log.debug("{d} = {d}", .{equation.lhs, equation.rhs.items});
        if (try hasSolution(equation)) { sum += equation.lhs; }
    }
    std.log.info("{d}", .{sum});
}

fn hasSolution(equation: Equation) !bool {
    var results = std.ArrayList(i64).init(std.heap.page_allocator);
    defer results.deinit();

    const numbers = equation.rhs.items;
    try results.append(numbers[0]);
    for (numbers[1..]) |number| {
        const res_clone = try results.clone();
        while(results.items.len > 0) {
            _ = results.orderedRemove(results.items.len - 1);
        }
        for (res_clone.items) |result| {
            try results.append(result * number);
            try results.append(result + number);
        }
    }

    return contains(results.items, equation.lhs);
}

fn contains(list: []const i64, query: i64) bool {
    for (list) |element| {
        if (element == query)
            return true;
    } 
    return false;
}

fn readFileAsSting(filepath: []const u8) !std.ArrayList(Equation) {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var equations = std.ArrayList(Equation).init(std.heap.page_allocator);
    errdefer equations.deinit();
    // Read big line
    var buffer: [240000]u8 = undefined;
    while (true) {
        const maybe_line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
        if (maybe_line) |line| {
            var it = std.mem.split(u8, line, ": ");
            var result: i64 = 0;
            var numbers = std.ArrayList(i64).init(std.heap.page_allocator);
            errdefer numbers.deinit();
            if (it.next()) |lhs| {
                result = try std.fmt.parseInt(i64, lhs, 10);
            }
            if (it.next()) |rhs| {
                var numbers_iterator = std.mem.split(u8, rhs, " ");
                while(numbers_iterator.next()) |str_number| {
                    const number = try std.fmt.parseInt(i64, str_number, 10);
                    try numbers.append(number);
                }
            }
            try equations.append(Equation{
                .lhs = result,
                .rhs = numbers
            });
        } else break;
    }

    return equations;
}