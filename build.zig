const std = @import("std");

pub fn build(b: *std.Build) !void
{
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "asm-benchmarks",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    std.log.info("Assembling with nasm", .{});
    if (execCheckTermStdout(&[_][]const u8 {
        "nasm", "-f", "win64", "src/loops.asm", "-o", "zig-cache/loops.obj"
    }, b.allocator) == null) {
        return error.nativeCompile;
    }
    exe.addObjectFile(.{.path = "zig-cache/loops.obj"});
    // exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn isTermOk(term: std.ChildProcess.Term) bool
{
    switch (term) {
        std.ChildProcess.Term.Exited => |value| {
            return value == 0;
        },
        else => {
            return false;
        }
    }
}

fn checkTermStdout(execResult: std.ChildProcess.ExecResult) ?[]const u8
{
    const ok = isTermOk(execResult.term);
    if (!ok) {
        std.log.err("{}", .{execResult.term});
        if (execResult.stdout.len > 0) {
            std.log.info("{s}", .{execResult.stdout});
        }
        if (execResult.stderr.len > 0) {
            std.log.err("{s}", .{execResult.stderr});
        }
        return null;
    }
    return execResult.stdout;
}

fn execCheckTermStdoutWd(argv: []const []const u8, cwd: ?[]const u8, allocator: std.mem.Allocator) ?[]const u8
{
    const result = std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = cwd
    }) catch |err| {
        std.log.err("exec error: {}", .{err});
        return null;
    };
    return checkTermStdout(result);
}

fn execCheckTermStdout(argv: []const []const u8, allocator: std.mem.Allocator) ?[]const u8
{
    return execCheckTermStdoutWd(argv, null, allocator);
}
