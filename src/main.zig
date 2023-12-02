const std = @import("std");

const rep = @import("repetition_test.zig");

const testTimeSeconds = 5;

extern fn movLoop(count: u64, ptr: [*]u8) void;
extern fn nop3x1Loop(count: u64, ptr: [*]u8) void;
extern fn nop1x3Loop(count: u64, ptr: [*]u8) void;
extern fn nop1xNLoop(count: u64, ptr: [*]u8) void;
extern fn cmpLoop(count: u64, ptr: [*]u8) void;
extern fn decLoop(count: u64, ptr: [*]u8) void;
extern fn jumpyLoop(count: u64, ptr: [*]u8) void;

const Test = struct {
    name: []const u8,
    func: *const fn(u64, [*]u8) callconv(.C)void,
};

const TESTS = [_]Test {
    .{.name = "mov", .func = movLoop},
    .{.name = "nop3x1", .func = nop3x1Loop},
    .{.name = "nop1x3", .func = nop1x3Loop},
    .{.name = "nop1xN", .func = nop1xNLoop},
    .{.name = "cmp", .func = cmpLoop},
    .{.name = "dec", .func = decLoop},
    .{.name = "jumpy", .func = jumpyLoop},
};

fn runTest(t: Test, tester: *rep.Tester, buf: []u8) void
{
    tester.reset(t.name, testTimeSeconds, buf.len);
    while (tester.isTesting()) {
        tester.beginTime();
        t.func(buf.len, buf.ptr);
        tester.endTime();

        tester.countBytes(buf.len);
    }
}

pub fn main() !void
{
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const cpuFreq = rep.estimateRdtscFreq();
    std.log.info("RDTSC frequency {}", .{cpuFreq});
    var tester = rep.Tester.init(cpuFreq);

    var prng = std.rand.DefaultPrng.init(12839547838);
    const random = prng.random();

    var buf = try allocator.alloc(u8, 256 * 1024 * 1024);
    for (0..buf.len) |i| {
        const zeroChanceIn256 = 128;
        buf[i] = if (random.int(u8) < zeroChanceIn256) 0 else 1;
    }

    for (TESTS) |t| {
        runTest(t, &tester, buf);
    }

    std.debug.print("Successfully called ASM\n", .{});
}
