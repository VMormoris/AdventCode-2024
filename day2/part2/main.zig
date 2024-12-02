const std = @import("std");

pub fn main() !void {
    const reports = try readFileLineByLine("part2/input.txt");
    defer reports.deinit();

    const safe_levels = try countSafeLevels(reports);
    std.log.info("{d}", .{safe_levels});
}

fn countSafeLevels(reports: std.ArrayList(std.ArrayList(i64))) !usize {
    var safe_levels: usize = 0;
    for (reports.items) | levels | {
        const result = checkSafetyWithErrorIndex(levels);
        if (result[0]) { safe_levels += 1; }
        else {
            const safety = try checkSafetyForErrorIndex(levels, result[1]);
            if (safety) { safe_levels += 1; }
        }
    }
    return safe_levels;
}

fn checkSafetyForErrorIndex(levels: std.ArrayList(i64), index: i64) !bool {
    const idx: u64 = @intCast(index);
    if (idx > 0) {
        var left_candidate = try levels.clone();
        _ = left_candidate.orderedRemove(idx - 1);
        const result = checkSafetyWithErrorIndex(left_candidate);
        if (result[0]) { return true; }
    }
    var first_candidate = try levels.clone();
    _ = first_candidate.orderedRemove(idx);
    var second_candidate = try levels.clone();
    _ = second_candidate.orderedRemove(idx + 1);

    {
        const result = checkSafetyWithErrorIndex(first_candidate);
        if (result[0]) { return true; }
    }

    {
        const result = checkSafetyWithErrorIndex(second_candidate);
        if (result[0]) { return true; }
    }

    return false;
}

fn checkSafetyWithErrorIndex(levels: std.ArrayList(i64)) struct { bool, i64 } {
    
    {// Early check
        const diff = @abs(levels.items[0] - levels.items[1]);
        if (diff == 0 or diff > 3) { return .{ false, 0 }; }
    }

    const ascending = levels.items[0] < levels.items[1];
    for (1..levels.items.len - 1) | idx | {
        const diff = levels.items[idx] - levels.items[idx + 1];
        const absolute_diff = @abs(diff);
        if (absolute_diff > 3 or absolute_diff == 0) { return .{ false, @intCast(idx) }; }
        else if (ascending and diff > 0) { return .{ false, @intCast(idx) }; }
        else if (!ascending and diff < 0) { return .{ false, @intCast(idx) }; }
    }
    return .{ true, -1 };
}

fn readFileLineByLine(filepath: []const u8) !std.ArrayList(std.ArrayList(i64)) {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // lines will get read into this
    var reports = std.ArrayList(std.ArrayList(i64)).init(std.heap.page_allocator);
    errdefer reports.deinit();
    var buffer: [4096]u8 = undefined;
    while (true) {
        var levels = std.ArrayList(i64).init(std.heap.page_allocator);
        const maybe_line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
        if (maybe_line) | line | {
            var it = std.mem.split(u8, line, " ");
            while (it.next()) | str_number | {
                const number: i64 = try std.fmt.parseInt(i64, str_number, 10);
                try levels.append(number);
            }
        } else break;
        try reports.append(levels);
    }
    return reports;
}