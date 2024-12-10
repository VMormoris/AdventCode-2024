const std = @import("std");

const Vec2 = struct {
    x: i64,
    y: i64,
};

pub fn main() !void {
    const input = try readFileLineByLine("part1/input.txt");
    defer {
        for (input.items) |line| {
            std.heap.page_allocator.free(line);
        }    
        input.deinit();
    }

    
    for (input.items) |line| {
        std.log.info("{s}", .{line});
    }

    const result = findXMASes(input.items);
    std.log.info("{d}", .{result});
}

fn findXMASes(input: [][]const u8) u64 {
    var sum: u64 = 0;
    for (input, 0..) | line, y | {
        for (line, 0..) | _, x | {
            if (x >= line.len - 2) break;
            const point = Vec2{.x=@intCast(x), .y=@intCast(y)};
            const next_point = Vec2{.x=point.x + 2, .y=point.y};
            if (
                (searchSliceOnDirection(input, "MAS", point, Vec2{.x =  1, .y =  1}) or // Down right for MAS
                    searchSliceOnDirection(input, "SAM", point, Vec2{.x =  1, .y =  1})) and // Down right for SAM
                (searchSliceOnDirection(input, "MAS", next_point, Vec2{.x = -1, .y =  1}) or // Down left for MAS
                    searchSliceOnDirection(input, "SAM", next_point, Vec2{.x = -1, .y =  1}) // Down right for SAM
                )
            ) sum += 1; // Down right
        }
    }
    return sum;
}

fn searchSliceOnDirection(input: [][]const u8, slice: []const u8, fromPos: Vec2, dir: Vec2) bool {
    if (slice.len == 0) return true;
    if (isPosOutOfBounds(input, fromPos)) return false;

    const y: usize = @intCast(fromPos.y); const x: usize = @intCast(fromPos.x); 
    if (slice[0] != input[y][x]) return false;
    const toPos = Vec2{.x = fromPos.x + dir.x, .y = fromPos.y + dir.y};
    return searchSliceOnDirection(input, slice[1..], toPos, dir);
}

fn isPosOutOfBounds(input: [][]const u8, pos: Vec2) bool { 
    if (pos.x < 0 or pos.y < 0) return true;
    const y: usize = @intCast(pos.y); const x: usize = @intCast(pos.x); 
    if (y >= input.len or x >= input[0].len) return true;
    return false;
}

fn readFileLineByLine(filepath: []const u8) !std.ArrayList([]u8) {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // lines will get read into this
    var lines = std.ArrayList([]u8).init(std.heap.page_allocator);
    errdefer lines.deinit();
    var buffer: [4096]u8 = undefined;
    while (true) {
        const maybe_line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
        if (maybe_line) | line | {
            var line_copy = try std.heap.page_allocator.alloc(u8, line.len);
            @memcpy(line_copy[0..], line);
            try lines.append(line_copy);
        } else break;
    }
    return lines;
}