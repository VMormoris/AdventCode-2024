const std = @import("std");

const Vec2 = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    const antenas_map = try readFileLineByLine("part2/input.txt");
    var antinode_map = try readFileLineByLine("part2/input.txt");
    // _ = &antinode_map;// I don't know why but it gives error that I'm not mutating
    defer {
        for (antinode_map.items) |line| {
            std.log.debug("{s}", .{line});
            std.heap.page_allocator.free(line);
        }
        antinode_map.deinit();

        for (antenas_map.items) |line| {
            std.heap.page_allocator.free(line);
        }
        antenas_map.deinit();
    }

    try createAntinodes(antenas_map.items, antinode_map.items);
    const antinode_count = countHashtags(antinode_map.items);
    std.log.info("Reslut: {d}", .{antinode_count});
}

fn countHashtags(antinode_map: [][]u8) usize {
    var count: usize = 0;
    for (antinode_map) |row| {
        for (row) |val| {
            if (val == '#') {
                count += 1;
            }
        }
    }
    return count;
}

fn createAntinodes(antenas_map: [][]const u8, antinode_map: [][]u8) !void {
    var proccesed_frequencies = std.ArrayList(u8).init(std.heap.page_allocator);
    defer proccesed_frequencies.deinit();

    for (antenas_map) |row| {
        for (row) |val| {
            if (val != '.' and !contains(proccesed_frequencies.items, val)) {
                try proccesFrequency(antenas_map, antinode_map, val);
                try proccesed_frequencies.append(val);
            }
        }
    }
}

fn proccesFrequency(antenas_map: [][]const u8, antinode_map: [][]u8, frequency: u8) !void {
    var positions = std.ArrayList(Vec2).init(std.heap.page_allocator);
    defer {
        std.log.debug("For frequency: {c} found {d} positions", .{frequency, positions.items.len});
        positions.deinit();
    }

    for (antenas_map, 0..) |row, y| {
        for (row, 0..) |val, x| {
            const pos = Vec2{.x = x, .y = y };
            if (val == frequency) {
                try positions.append(pos);
            }
        }
    }

    if(positions.items.len < 2) return;

    for (positions.items, 0..) |pos, idx| {
        for (positions.items, 0..) |next_pos, next_idx| {
            if (idx == next_idx) continue;
            const dist = distance(pos, next_pos);
            createAntinode(antinode_map, next_pos, dist);
            createAntinode(antinode_map, pos, .{-dist[0], -dist[1]});
        }
    }

    for (positions.items) |pos| {
        antinode_map[pos.y][pos.x] = '#';
    } 
}

fn createAntinode(antinode_map: [][]u8, pos: Vec2, dir: struct{i64, i64}) void {
    const new_x: i64 = @as(i64, @intCast(pos.x)) + dir[0];
    const new_y: i64 = @as(i64, @intCast(pos.y)) + dir[1];

    if (new_x < 0 or new_y < 0 or new_x >= antinode_map[0].len or new_y >= antinode_map.len) return;

    const x: usize = @intCast(new_x);
    const y: usize = @intCast(new_y);
    antinode_map[y][x] = '#'; 

    createAntinode(antinode_map, Vec2{.x = x, .y = y}, dir);
}

fn distance(point_a: Vec2, point_b: Vec2) struct{i64, i64}{
    const a_x: i64 = @intCast(point_a.x); const a_y: i64 = @intCast(point_a.y);
    const b_x: i64 = @intCast(point_b.x); const b_y: i64 = @intCast(point_b.y);

    return .{b_x - a_x, b_y - a_y};
}

fn contains(list: []const u8, query: u8) bool {
    for (list) |element| {
        if (element == query) {
            return true;
        }
    }
    return false;
}

fn readFileLineByLine(filepath: []const u8) !std.ArrayList([] u8) {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // lines will get read into this
    var lines = std.ArrayList([]u8).init(std.heap.page_allocator);
    errdefer {
        for(lines.items) |line| {
            std.heap.page_allocator.free(line);
        }
        lines.deinit();
    }

    var buffer: [4096]u8 = undefined;
    var idx: usize = 0;
    while (true) {
        const maybe_line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
        if (maybe_line) | line | {
            var line_copy = try std.heap.page_allocator.alloc(u8, line.len);
            @memcpy(line_copy[0..], line);
            try lines.append(line_copy);
            idx += 1;
        } else break;
    }
    return lines;
}