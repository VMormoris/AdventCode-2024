const std = @import("std");

const sleep_time = 0.0 * std.time.ns_per_s;


const Vec2 = struct {
    x: i64,
    y: i64,
};

const Quard = struct {
    pos: Vec2,
    dir: Vec2,
};

pub fn main() !void {
    var map = try readFileLineByLine("part2/input.txt");
    var obstacles_map = try cloneMap(map.items);
    defer {
        for (map.items) |line| {
            std.heap.page_allocator.free(line);
        }    
        map.deinit();

        for (obstacles_map.items) |line| {
            std.heap.page_allocator.free(line);
        }
        obstacles_map.deinit();
    }

    const quard = findQuard(map.items);
    try simulateQuardPatrol(map.items, obstacles_map.items, quard);
    // findObstacles(map.items, obstacles_map.items, quard);

    const result = countO(obstacles_map.items);
    std.log.info("{d}", .{result});
    // const result = findXMASes(input.items);
    // std.log.info("{d}", .{result});
}

fn countO(map: [][]const u8) usize {
    var counter: usize = 0;
    for (map) |row| {
        for (row) |tile| {
            if (tile == 'O') { counter +=1; }
        }
    }
    return counter;
}

fn print(map: [][]const u8, obstacles_map: [][]const u8) !void {
    try writeMapToFile("part2/map.txt", map);
    try writeMapToFile("part2/obstacles.txt", obstacles_map);
}

fn simulateQuardPatrol(map: [][]u8, obstacles_map: [][]u8, start_quard: Quard) !void {
    defer std.log.debug("{}", .{obstacles_map[@intCast(start_quard.pos.y)][@intCast(start_quard.pos.x)]});
    var quard = start_quard;
    while(true) {
        try checkAndAddObstable(map, obstacles_map, quard);
        var next_pos = nextTile(quard.pos, quard.dir);
        if (isPosOutOfBounds(map, next_pos)) return;

        var curr_dir = quard.dir; 
        while (map[@intCast(next_pos.y)][@intCast(next_pos.x)] == '#') {
            curr_dir = turnRight(curr_dir);
            next_pos = nextTile(quard.pos, curr_dir);
            if (isPosOutOfBounds(map, next_pos)) return;
        }
        
        changeTile(map, quard.pos, curr_dir);

        if (quard.dir.x != curr_dir.x or quard.dir.y != curr_dir.y) {
            map[@intCast(quard.pos.y)][@intCast(quard.pos.x)] = '+';
        }
        quard.pos = next_pos;
        quard.dir = curr_dir;
        // std.time.sleep(@intFromFloat(sleep_time));
        // map[@intCast(quard.pos.y)][@intCast(quard.pos.x)] = '^';
        try checkAndAddObstable(map, obstacles_map, quard);
        // try print(map, obstacles_map);
    }
}

fn checkAndAddObstable(map: [][]const u8, obstacles_map: [][]u8, quard: Quard) !void {
    var dir = turnRight(quard.dir);
    var write_pos = nextTile(quard.pos, quard.dir);

    if (isPosOutOfBounds(map, write_pos)) return;
    var write_x: usize = @intCast(write_pos.x);
    var write_y: usize = @intCast(write_pos.y);

    while (map[write_y][write_x] == '#') {
        write_pos = nextTile(quard.pos, dir);
        dir = turnRight(dir);
        write_x = @intCast(write_pos.x);
        write_y = @intCast(write_pos.y);
    }

    var visited = std.ArrayList(Quard).init(std.heap.page_allocator);
    defer visited.deinit();
    try visited.append(Quard{.pos = quard.pos, .dir=quard.dir});

    const aux = obstacles_map[write_y][write_x];
    obstacles_map[write_y][write_x] = 'O';
    var curr_pos = quard.pos;
    while(true) {
        const new_pos = nextTile(curr_pos, dir);
        if (isPosOutOfBounds(map, new_pos)) {
            // {// Debug print
            //     var tmp = std.ArrayList(u8).init(std.heap.page_allocator);
            //     for (visited.items) |vec| {
            //         const x: usize = @intCast(vec.pos.x);
            //         const y: usize = @intCast(vec.pos.y);
            //         try tmp.append(obstacles_map[y][x]);
            //         obstacles_map[y][x] = '?';
            //     }
            //     try print(map, obstacles_map);
            //     std.time.sleep(@intFromFloat(sleep_time));
            //     clearMapFromQuery(obstacles_map);
            // }
            obstacles_map[write_y][write_x] = aux;
            return;
        }
        if (contains(visited.items, Quard{.pos = new_pos, .dir=dir})) break;
        
        const x: usize = @intCast(new_pos.x);
        const y: usize = @intCast(new_pos.y);

        if (map[y][x] == '#' or (y == write_y and x == write_x)) { dir = turnRight(dir); }
        else { curr_pos = new_pos; try visited.append(Quard{.pos = new_pos, .dir=dir}); }
    }

    
    if (map[write_y][write_x] == '#') return;
    // std.log.debug("{c}", .{obstacles_map[write_y][write_x]});

    // {// Debug print
    //     var tmp = std.ArrayList(u8).init(std.heap.page_allocator);
    //     for (visited.items) |vec| {
    //         const x: usize = @intCast(vec.pos.x);
    //         const y: usize = @intCast(vec.pos.y);
    //         try tmp.append(obstacles_map[y][x]);
    //         obstacles_map[y][x] = '*';
    //     }
    //     try print(map, obstacles_map);
    //     std.time.sleep(@intFromFloat(sleep_time));
    //     clearMapFromQuery(obstacles_map);
    // }

    obstacles_map[write_y][write_x] = 'O';
}

fn clearMapFromQuery(map: [][]u8) void {
    for(map, 0..) |row, y| {
        for (row, 0..) |tile, x| {
            if (tile == '*' or tile == '?') {
                map[y][x] = '.';
            }
        }
    }
}

fn contains(arr: []const Quard, query: Quard) bool {
    for (arr) |element| {
        if (element.pos.x == query.pos.x and element.pos.y == query.pos.y and
            element.dir.x == query.dir.x and element.dir.y == query.dir.y
        ) {
            return true;
        }
    }
    return false;
}

fn changeTile(map: [][]u8, pos: Vec2, dir: Vec2) void {
    const x: usize = @intCast(pos.x);
    const y: usize = @intCast(pos.y);

    if (dir.y == -1 and map[y][x] != '+') { map[y][x] = if (map[y][x] == '-') '+' else '|'; }
    else if (dir.x ==  1 and map[y][x] != '+') { map[y][x] = if (map[y][x] == '|') '+' else '-'; }
    else if (dir.y ==  1 and map[y][x] != '+') { map[y][x] = if (map[y][x] == '-') '+' else '|'; }
    else if (dir.x == -1 and map[y][x] != '+') { map[y][x] = if (map[y][x] == '|') '+' else '-'; }
}

fn cloneMap(original_map: [][]const u8) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(std.heap.page_allocator);
    errdefer lines.deinit();

    for (original_map) |line| {
        var line_copy = try std.heap.page_allocator.alloc(u8, line.len);
        @memcpy(line_copy[0..], line);
        try lines.append(line_copy);
    }
    
    return lines;
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

fn writeMapToFile(filepath: []const u8, map: [][]const u8) !void {
    // Open the file for writing
    var file = try std.fs.cwd().createFile(filepath, .{});
    defer file.close();
    for (map) |line| {
        try file.writer().print("{s}\n", .{line});
    }
}