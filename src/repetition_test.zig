const std = @import("std");

const blankCr = "                                               \r";

pub const Mode = enum {
    complete,
    testing,
    err,
};

pub const Results = struct {
    count: u64 = 0,
    sumRdtsc: u64 = 0,
    maxRdtsc: u64 = 0,
    minRdtsc: u64 = std.math.maxInt(u64),

    pub fn print(self: *const Results, rdtscFreq: u64, bytes: u64) void
    {
        printTime("Min", self.minRdtsc, rdtscFreq, bytes);
        std.debug.print("\n", .{});
        printTime("Max", self.maxRdtsc, rdtscFreq, bytes);
        std.debug.print("\n", .{});
        if (self.count > 0) {
            printTime("Avg", self.sumRdtsc / self.count, rdtscFreq, bytes);
            std.debug.print("\n", .{});
        }
    }
};

pub const Tester = struct {
    rdtscFreq: u64,
    tryForRdtsc: u64 = 0,
    startRdtsc: u64 = 0,
    targetBytes: u64 = 0,

    mode: Mode = .complete,
    openedBlocks: u32 = 0,
    closedBlocks: u32 = 0,
    currentTestRdtsc: u64 = 0,
    currentTestBytes: u64 = 0,
    results: Results = .{},

    pub fn init(rdtscFreq: u64) Tester
    {
        return .{
            .rdtscFreq = rdtscFreq,
        };
    }

    pub fn reset(self: *Tester, tryForSeconds: u64, targetBytes: u64) void
    {
        self.mode = .testing;
        self.tryForRdtsc = tryForSeconds * self.rdtscFreq;
        self.startRdtsc = rdtsc();
        self.targetBytes = targetBytes;
        self.results = .{};
    }

    pub fn isTesting(self: *Tester) bool
    {
        if (self.mode == .testing) {
            const currentRdtsc = rdtsc();

            if (self.openedBlocks != 0) {
                if (self.openedBlocks != self.closedBlocks) {
                    self.err("Unbalanced beginTime/endTime", .{});
                }
                if (self.currentTestBytes != self.targetBytes) {
                    self.err("Processed byte count mismatch", .{});
                }
                if (self.mode == .testing) {
                    var results = &self.results;
                    const elapsed = self.currentTestRdtsc;
                    results.count += 1;
                    results.sumRdtsc += elapsed;
                    if (results.maxRdtsc < elapsed) {
                        results.maxRdtsc = elapsed;
                    }
                    if (results.minRdtsc > elapsed) {
                        results.minRdtsc = elapsed;
                        // Whenever we get a new minimum time, we reset the clock.
                        self.startRdtsc = currentRdtsc;

                        printTime("Min", results.minRdtsc, self.rdtscFreq, self.currentTestBytes);
                        std.debug.print(blankCr, .{});
                    }

                    self.openedBlocks = 0;
                    self.closedBlocks = 0;
                    self.currentTestRdtsc = 0;
                    self.currentTestBytes = 0;
                }
            }

            if ((currentRdtsc - self.startRdtsc) > self.tryForRdtsc) {
                self.mode = .complete;
                std.debug.print(blankCr, .{});
                self.results.print(self.rdtscFreq, self.targetBytes);
            }
        }

        return self.mode == .testing;
    }

    pub fn beginTime(self: *Tester) void
    {
        self.openedBlocks += 1;
        self.currentTestRdtsc -= rdtsc();
    }

    pub fn endTime(self: *Tester) void
    {
        self.closedBlocks += 1;
        self.currentTestRdtsc += rdtsc();
    }

    pub fn countBytes(self: *Tester, bytes: u64) void
    {
        self.currentTestBytes += bytes;
    }

    fn err(self: *Tester, comptime fmt: []const u8, args: anytype) void
    {
        self.mode = .err;
        std.log.err(fmt, args);
    }
};

pub fn rdtsc() u64
{
    var hi: u64 = 0;
    var low: u64 = 0;
    asm volatile (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi)
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

pub fn estimateRdtscFreq() u64
{
    const waitMs = 500;
    const waitNs = waitMs * std.time.ns_per_ms;

    const rdtscStart = rdtsc();
    var elapsedNs: u64 = 0;
    var timer = std.time.Timer.start() catch return 0;
    while (elapsedNs < waitNs) {
        elapsedNs = timer.read();
    }
    const rdtscEnd = rdtsc();

    if (elapsedNs == 0) {
        return 0;
    } else {
        return (rdtscEnd - rdtscStart) * std.time.ns_per_s / elapsedNs;
    }
}

fn secondsFromRdtsc(rdtscTime: u64, rdtscFreq: u64) f64
{
    return @as(f64, @floatFromInt(rdtscTime)) / @as(f64, @floatFromInt(rdtscFreq));
}

fn printTime(label: []const u8, rdtscTime: u64, rdtscFreq: u64, bytes: u64) void
{
    std.debug.print("{s}: {d:.0}", .{label, @as(f64, @floatFromInt(rdtscTime))});
    if (rdtscFreq != 0) {
        const seconds = secondsFromRdtsc(rdtscTime, rdtscFreq);
        std.debug.print(" ({d:.3}ms)", .{seconds * 1000});
    
        if (bytes != 0) {
            const gigabyte = 1024.0 * 1024.0 * 1024.0;
            const bestBandwidth = @as(f64, @floatFromInt(bytes)) / (seconds * gigabyte);
            std.debug.print(" {d:.3}gb/s", .{bestBandwidth});
        }
    }
}
