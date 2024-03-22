const std = @import("std");
const raylib = @import("raylib/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // const exe = ...;

    const exe = b.addExecutable(.{ .name = "main", .root_source_file = .{ .path = "src/shadow-map.zig" }, .optimize = optimize, .target = target });
    raylib.addTo(b, exe, target.query, optimize, .{});
    // const exe2 = b.addExecutable(.{ .name = "spacelix-renderer", .root_source_file = .{ .path = "src/main.zig" }, .optimize = optimize, .target = target });

    // rl.link(b, exe, target, optimize);
    // exe.addModule("raylib", raylib);
    // exe.addModule("raylib-math", raylib_math);

    // const run_cmd = b.addRunArtifact(exe);
    // const run_step = b.step("run", "Run spacelix-renderer");
    // run_step.dependOn(&run_cmd.step);

    // b.installArtifact(exe);
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
