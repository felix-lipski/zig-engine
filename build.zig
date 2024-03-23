const std = @import("std");
const raylib = @import("raylib/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{ .name = "main", .root_source_file = .{ .path = "src/main.zig" }, .optimize = optimize, .target = target });
    raylib.addTo(b, exe, target.query, optimize, .{});

    exe.linkLibC();

    const zmath = b.dependency("zmath", .{
        .target = target,
    });
    exe.root_module.addImport("zmath", zmath.module("root"));

    const zphysics = b.dependency("zphysics", .{
        .target = target,
        .use_double_precision = false,
        .enable_debug_renderer = true,
        .enable_asserts = true,
    });
    exe.root_module.addImport("zphysics", zphysics.module("root"));
    exe.linkLibrary(zphysics.artifact("joltc"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
