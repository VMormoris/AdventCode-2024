const std = @import("std");

pub fn main() !void {
    const line = try readFileLineByLine("part2/input.txt");    
    const tokens = try scanMemoryForAreas(line);
    
    var sum: i64 = 0;
    for (tokens.items) |token| {
        sum += token;
    }
    
    std.log.info("{d}", .{sum});
}

fn scanMemoryForAreas(line: []const u8) !std.ArrayList(i64) {
    var accumulator = std.ArrayList(i64).init(std.heap.page_allocator);
    var curr: usize = 0;
    { // Starting state handle
        const end = if (std.mem.indexOf(u8, line, "don't()")) |idx| idx else line.len;
        const tokens = try scanMemoryForTokens(line[0..end]);
        curr = end + 7;
        for (tokens.items) |token| {
            try accumulator.append(token);
        }
    }

    while(std.mem.indexOf(u8, line[curr..], "do()")) |first_idx| {
        const start = curr + first_idx + 4;
        const end = if (std.mem.indexOf(u8, line[start..], "don't()")) |idx| start + idx else line.len;
        const tokens = try scanMemoryForTokens(line[start..end]);
        for (tokens.items) |token| {
            try accumulator.append(token);
        }
        curr = end + 1;
        if (curr >= line.len) { break; }
    }

    return accumulator;
}

fn scanMemoryForTokens(line: []const u8) !std.ArrayList(i64) {
    var accumulator = std.ArrayList(i64).init(std.heap.page_allocator);
    var curr: usize = 0;
    while(std.mem.indexOf(u8, line[curr..], "mul(")) |first_idx| : (curr += first_idx + 4) {
        const start = curr + first_idx;
        if (std.mem.indexOf(u8, line[start..], ")")) | idx | {
            const end = start + idx + 1;
            const validity = isSliceValid(line[start+4..end-1]);
            if (validity) {
                const result = try multiple(line[start+4..end-1]);
                try accumulator.append(result);
            }
        }
    }
    return accumulator;
}

fn isSliceValid(slice: []const u8) bool {
    return slice.len > 0 and slice.len < 8 
        and std.mem.count(u8, slice, ",") == 1
        and everyCharIsDigitOrComa(slice);
}

fn everyCharIsDigitOrComa(slice: []const u8) bool {
    for (slice) |char| {
        if (char != ',' and (char < 48 or char > 57)) return false;
    }
    return true;
}

fn multiple(slice: []const u8) !i64 {
    var result: i64 = 1;
    var it = std.mem.split(u8, slice, ",");
    while (it.next()) |str_number| {
        const number: i64 = try std.fmt.parseInt(i64, str_number, 10);
        result *= number;
    }
    return result; 
}

fn readFileLineByLine(filepath: []const u8) ![]const u8 {
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

// 192767529
// 104083373
// 216011658