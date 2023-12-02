const std = @import("std");

const rep = @import("repetition_test.zig");

const testTimeSeconds = 5;

extern fn MOVAllBytesASM(count: u64, ptr: [*]u8) void;
extern fn NOPAllBytesASM(count: u64) void;
extern fn CMPAllBytesASM(count: u64) void;
extern fn DECAllBytesASM(count: u64) void;

fn testMov(tester: *rep.Tester, buf: []u8) void
{
    tester.reset(testTimeSeconds, buf.len);
    while (tester.isTesting()) {
        tester.beginTime();
        MOVAllBytesASM(buf.len, buf.ptr);
        tester.endTime();

        tester.countBytes(buf.len);
    }
}

fn testNop(tester: *rep.Tester, buf: []u8) void
{
    tester.reset(testTimeSeconds, buf.len);
    while (tester.isTesting()) {
        tester.beginTime();
        NOPAllBytesASM(buf.len);
        tester.endTime();

        tester.countBytes(buf.len);
    }
}

fn testCmp(tester: *rep.Tester, buf: []u8) void
{
    tester.reset(testTimeSeconds, buf.len);
    while (tester.isTesting()) {
        tester.beginTime();
        CMPAllBytesASM(buf.len);
        tester.endTime();

        tester.countBytes(buf.len);
    }
}

fn testDec(tester: *rep.Tester, buf: []u8) void
{
    tester.reset(testTimeSeconds, buf.len);
    while (tester.isTesting()) {
        tester.beginTime();
        DECAllBytesASM(buf.len);
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

    var buf = try allocator.alloc(u8, 256 * 1024 * 1024);
    std.debug.print("mov\n", .{});
    testMov(&tester, buf);
    std.debug.print("nop\n", .{});
    testNop(&tester, buf);
    std.debug.print("cmp\n", .{});
    testCmp(&tester, buf);
    std.debug.print("dec\n", .{});
    testDec(&tester, buf);

    std.debug.print("Successfully called ASM\n", .{});
}
