const std = @import("std");

const Vec2 = struct {
    x: i64,
    y: i64,
};

const Quard = struct {
    pos: Vec2,
    dir: Vec2,
};

pub fn main() !void {
    var map = try readFileLineByLine("part1/input.txt");
    defer {
        for (map.items) |line| {
            std.heap.page_allocator.free(line);
        }    
        map.deinit();
    }

    const quard = findQuard(map.items);
    simulateQuardPatrol(map.items, quard);
    print(map.items);

    const result = countX(map.items);
    std.log.info("{d}", .{result});
    // const result = findXMASes(input.items);
    // std.log.info("{d}", .{result});
}

fn countX(map: [][]const u8) usize {
    var counter: usize = 1;
    for (map) |row| {
        for (row) |tile| {
            if (tile == 'X') { counter +=1; }
        }
    }
    return counter;
}

fn print(map: [][]u8) void {
    for (map) |line| {
        std.log.debug("{s}", .{line});
    }
}

fn simulateQuardPatrol(map: [][]u8, start_quard: Quard) void {
    var quard = start_quard;
    while(true) {
        var next_pos = nextTile(quard.pos, quard.dir);
        if (isPosOutOfBounds(map, next_pos)) return;

        var curr_dir = quard.dir; 
        while (map[@intCast(next_pos.y)][@intCast(next_pos.x)] == '#') {
            curr_dir = turnRight(curr_dir);
            next_pos = nextTile(quard.pos, curr_dir);
            if (isPosOutOfBounds(map, next_pos)) return;
        }
        
        map[@intCast(quard.pos.y)][@intCast(quard.pos.x)] = 'X';
        quard.pos = next_pos;
        quard.dir = curr_dir;
        // std.time.sleep(std.time.ns_per_s);
        print(map);
    }
    map[@intCast(quard.pos.y)][@intCast(quard.pos.x)] = 'X';
}

fn nextTile(pos: Vec2, dir: Vec2) Vec2 {
    return Vec2{.x = pos.x + dir.x, .y = pos.y + dir.y};
}

fn turnRight(dir: Vec2) Vec2 {
    if (dir.y == -1) return Vec2{.x =  1, .y =  0};
    if (dir.x ==  1) return Vec2{.x =  0, .y =  1};
    if (dir.y ==  1) return Vec2{.x = -1, .y =  0};
    if (dir.x == -1) return Vec2{.x =  0, .y = -1};

    return Vec2{.x = 0, .y = 0};
}

fn findQuard(map: [][]const u8) Quard {
    var pos = Vec2{.x = -1, .y = -1};
    var dir = Vec2{.x =  0, .y =  0};

    for (map, 0..) |row, y| {
        for (row, 0..) |tile, x| {
            const aux = Vec2{.x = @intCast(x), .y = @intCast(y)};
            if (tile == '^') { pos = aux; dir.y = -1; }
            else if (tile == 'v') { pos = aux; dir.y =  1; }
            else if (tile == '<') { pos = aux; dir.x = -1; }
            else if (tile == '>') { pos = aux; dir.x =  1; }
        }
    }

    return Quard{.pos = pos, .dir = dir};
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