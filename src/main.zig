const std = @import("std");
const rl = @import("raylib");
const zphy = @import("zphysics");
const zm = @import("zmath");
const Render = @import("render.zig");
const Jolt = @import("jolt.zig");
const game_world = @import("game_world.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    game_world.game_world = game_world.GameWorld.init(allocator);

    const joltWrapper = try Jolt.JoltWrapper.init(allocator);
    const screenWidth = 800;
    const screenHeight = 800;
    rl.InitWindow(screenWidth, screenHeight, "hello world!");
    rl.SetTargetFPS(60);
    defer rl.CloseWindow();

    var camera = rl.Camera3D{
        .position = .{ .x = 10.0, .y = 10.0, .z = 10.0 },
        .target = .{ .x = 0.0, .y = 0.5, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = .CAMERA_PERSPECTIVE,
    };

    var shadowMapper = Render.ShadowMapper.init();

    const body_interface = joltWrapper.physics_system.getBodyInterfaceMut();

    {
        const floor_shape_settings = try zphy.BoxShapeSettings.create(.{ 5.0, 0.5, 5.0 });
        defer floor_shape_settings.release();

        const floor_shape = try floor_shape_settings.createShape();
        defer floor_shape.release();

        const floorBodyId = try body_interface.createAndAddBody(.{
            .position = .{ 0.0, -1.0, 0.0, 1.0 },
            .rotation = .{ 0.0, 0.0, 0.0, 1.0 },
            .shape = floor_shape,
            .motion_type = .static,
            .object_layer = Jolt.object_layers.non_moving,
        }, .activate);

        const floorModel = rl.LoadModelFromMesh(rl.GenMeshCube(10.0, 1.0, 10.0));
        shadowMapper.InjectShadowShader(floorModel);
        const floorObject = game_world.GameObject{ .model = floorModel, .position = .{ .x = 0.0, .y = -1.0, .z = 0.0 }, .tint = rl.RAYWHITE, .bodyId = floorBodyId };
        try game_world.game_world.?.gameObjects.append(floorObject);
    }

    {
        const box_shape_settings = try zphy.BoxShapeSettings.create(.{ 0.5, 0.5, 0.5 });
        defer box_shape_settings.release();
        const box_shape = try box_shape_settings.createShape();
        defer box_shape.release();

        for (0..7) |i| {
            const floatI: f32 = @floatFromInt(i);
            const cube1BodyId = try body_interface.createAndAddBody(.{
                .position = .{ floatI * 0.1, floatI * 2.0 + 2.0, floatI * 0.1, 1.0 },
                .rotation = .{ 0.0, 0.0, 0.0, 1.0 },
                .shape = box_shape,
                .motion_type = .dynamic,
                .object_layer = Jolt.object_layers.moving,
                .angular_velocity = .{ 0.0, 0.0, 0.0, 0 },
            }, .activate);

            const cube1 = rl.LoadModelFromMesh(rl.GenMeshCube(1, 1, 1));
            shadowMapper.InjectShadowShader(cube1);
            const cube1_object = game_world.GameObject{ .model = cube1, .position = .{ .x = 1.5, .y = 1.0, .z = -1.5 }, .tint = rl.RED, .bodyId = cube1BodyId };
            try game_world.game_world.?.gameObjects.append(cube1_object);
        }
    }

    joltWrapper.physics_system.optimizeBroadPhase();

    // const robot = rl.LoadModel("resources/models/robot.glb");
    // shadowMapper.InjectShadowShader(robot);
    // const robot_object = GameObject{ .model = robot, .position = .{ .x = 0.0, .y = 0.5, .z = 0.0 } };

    // var animCount: i32 = 0;
    // const robotAnimations = rl.LoadModelAnimations("resources/models/robot.glb", @ptrCast(&animCount));
    // var fc: i32 = 0;

    while (!rl.WindowShouldClose()) {
        joltWrapper.update();
        shadowMapper.UpadateCamera(camera);
        rl.UpdateCamera(&camera, .CAMERA_ORBITAL);

        // fc = fc + 1;
        // fc = @mod(fc, robotAnimations.?[0].frameCount);
        // rl.UpdateModelAnimation(robot, robotAnimations.?[0], fc);

        rl.BeginDrawing();
        defer rl.EndDrawing();

        shadowMapper.RenderGameObjects(joltWrapper);

        rl.BeginMode3D(camera);
        Render.DrawScene(joltWrapper);
        rl.EndMode3D();

        rl.DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, rl.GRAY);
        rl.DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, rl.RED);
    }

    rl.UnloadShader(shadowMapper.shadowShader);
    // FIX IT
    // for (game_world.game_world.gameObjects.items) |object| {
    //     rl.UnloadModel(object.model);
    // }
    // rl.UnloadModelAnimations(robotAnimations, animCount);
    shadowMapper.UnloadShadowmapRenderTexture();
    joltWrapper.destroy(allocator);
}
