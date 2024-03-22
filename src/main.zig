const std = @import("std");
const rl = @import("raylib");
const Render = @import("render.zig");

pub const GameObject = struct { model: rl.Model, position: rl.Vector3, tint: rl.Color = rl.WHITE };

pub fn main() anyerror!void {
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

    const cube = rl.LoadModelFromMesh(rl.GenMeshCube(1, 1, 1));
    shadowMapper.InjectShadowShader(cube);
    const cube_object = GameObject{ .model = cube, .position = .{ .x = 1.5, .y = 1.0, .z = -1.5 }, .tint = rl.BLUE };

    const robot = rl.LoadModel("resources/models/robot.glb");
    shadowMapper.InjectShadowShader(robot);
    const robot_object = GameObject{ .model = robot, .position = .{ .x = 0.0, .y = 0.5, .z = 0.0 } };

    var animCount: i32 = 0;
    const robotAnimations = rl.LoadModelAnimations("resources/models/robot.glb", @ptrCast(&animCount));
    var fc: i32 = 0;

    const gameObjects: [2]GameObject = [2]GameObject{ cube_object, robot_object };

    while (!rl.WindowShouldClose()) {
        shadowMapper.UpadateCamera(camera);
        rl.UpdateCamera(&camera, .CAMERA_ORBITAL);

        fc = fc + 1;
        fc = @mod(fc, robotAnimations.?[0].frameCount);
        rl.UpdateModelAnimation(robot, robotAnimations.?[0], fc);

        rl.BeginDrawing();
        defer rl.EndDrawing();

        shadowMapper.RenderGameObjects(gameObjects);

        rl.BeginMode3D(camera);
        Render.DrawScene(gameObjects);
        rl.EndMode3D();

        rl.DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, rl.GRAY);
        rl.DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, rl.RED);
    }

    rl.UnloadShader(shadowMapper.shadowShader);
    for (gameObjects) |object| {
        rl.UnloadModel(object.model);
    }
    rl.UnloadModelAnimations(robotAnimations, animCount);
    shadowMapper.UnloadShadowmapRenderTexture();
}
