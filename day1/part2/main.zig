const std = @import("std");

pub fn main() !void {
    const inputs = try readFileLineByLine("part1/input.txt");

    defer inputs[0].deinit();
    defer inputs[1].deinit();

    std.mem.sort(i64, inputs[0].items, {}, comptime std.sort.asc(i64));
    std.mem.sort(i64, inputs[1].items, {}, comptime std.sort.asc(i64));
    //std.log.info("{d}", .{inputs[0].items});
    //std.log.info("{d}", .{inputs[1].items});

    var sum: u64 = 0;
    for (inputs[0].items) |elem| {
        const idx = binarySearch(inputs[1].items, elem);
        const count = countOccuruncies(inputs[1].items, idx, elem);
        sum += @as(usize, @intCast(elem)) * count;
    }
    std.log.info("{d}", .{sum});
}

fn countOccuruncies(list: []const i64, index: i64, search_term: i64) u64 {
    if (index < 0 ) { return 0; }
    
    var idx = index;
    while(idx >= 0) : (idx -= 1) { if(list[@as(usize, @intCast(idx))] != search_term) break; }
    idx += 1;

    var count: u64 = 0;
    while (list[@as(usize, @intCast(idx))] == search_term): (idx += 1) {
        count += 1;
    }
    return count;
}

fn binarySearch(list: []const i64, search_term: i64) i64 {
    var low: i64 = 0;
    var high: i64 = @intCast(list.len);
    while (low <= high) {
        const mid: i64 = low + @divFloor(high - low, 2);
        const idx: usize = @intCast(mid);
        if (list[idx] == search_term) { return mid; }
        else if (list[idx] < search_term) { low = mid + 1; }
        else { high = mid - 1; }
    }
    return -1;
}

fn readFileLineByLine(filepath: []const u8) !struct {std.ArrayList(i64), std.ArrayList(i64)} {    
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // lines will get read into this
    var first_list = std.ArrayList(i64).init(std.heap.page_allocator);
    errdefer first_list.deinit();
    var second_list = std.ArrayList(i64).init(std.heap.page_allocator);
    errdefer second_list.deinit();
    var buffer: [4096]u8 = undefined;
    while (true) {
        const maybe_line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
        if (maybe_line) | line | {
            var it = std.mem.split(u8, line, " ");
            if (it.next()) | str_number | {
                const number: i64 = try std.fmt.parseInt(i64, str_number, 10);
                try first_list.append(number);
            }
            _ = it.next();
            _ = it.next();
            if (it.next()) | str_number | {
                const number: i64 = try std.fmt.parseInt(i64, str_number, 10);
                try second_list.append(number);
            }
        } else break;
    }
    return .{first_list, second_list};
}