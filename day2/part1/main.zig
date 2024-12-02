const std = @import("std");

pub fn main() !void {
    const reports = try readFileLineByLine("part1/input.txt");
    defer reports.deinit();

    const safe_levels = countSafeLevels(reports);
    std.log.info("{d}", .{safe_levels});
}

fn countSafeLevels(reports: std.ArrayList(std.ArrayList(i64))) usize {
    var safe_levels: usize = 0;
    for (reports.items) | levels | {
        const safety = isSafe(levels);
        if (safety)
            safe_levels += 1;
    }
    return safe_levels;
}

fn isSafe(levels: std.ArrayList(i64)) bool {
    
    {// Early check
        const diff = @abs(levels.items[0] - levels.items[1]);
        if (diff == 0 or diff > 3) { return false; }
    }

    const ascending = levels.items[0] < levels.items[1];
    for (1..levels.items.len - 1) | idx | {
        const diff = levels.items[idx] - levels.items[idx + 1];
        const absolute_diff = @abs(diff);
        if (absolute_diff > 3 or absolute_diff == 0) { return false; }
        else if (ascending and diff > 0) { return false; }
        else if (!ascending and diff < 0) { return false; }
    }
    return true;
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