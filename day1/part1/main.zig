const std = @import("std");

pub fn main() !void {
    const inputs = try readFileLineByLine("part1/input.txt");
    defer inputs[0].deinit();
    defer inputs[1].deinit();
    std.mem.sort(i64, inputs[0].items, {}, comptime std.sort.asc(i64));
    std.mem.sort(i64, inputs[1].items, {}, comptime std.sort.asc(i64));

    var sum: u64 = 0;
    for (0.., inputs[0].items) |i, elem0| {
        const elem1 = inputs[1].items[i];
        const diff = @abs(elem0 - elem1);
        sum += diff;
    }
    std.log.info("{d}", .{sum});
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