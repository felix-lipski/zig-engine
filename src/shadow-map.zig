const std = @import("std");
const rl = @import("raylib");

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

    const shadowShader = rl.LoadShader("resources/shaders/shadowmap.vs", "resources/shaders/shadowmap.fs");
    shadowShader.locs.?[@intFromEnum(rl.ShaderLocationIndex.SHADER_LOC_VECTOR_VIEW)] = rl.GetShaderLocation(shadowShader, "viewPos");
    var lightDir = rl.Vector3Normalize(.{ .x = 0.35, .y = -1.0, .z = -0.35 });
    const lightColor = rl.WHITE;
    const lightColorNormalized = rl.ColorNormalize(lightColor);
    const lightDirLoc = rl.GetShaderLocation(shadowShader, "lightDir");
    const lightColLoc = rl.GetShaderLocation(shadowShader, "lightColor");
    rl.SetShaderValue(shadowShader, lightDirLoc, &lightDir, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC3);
    rl.SetShaderValue(shadowShader, lightColLoc, &lightColorNormalized, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4);
    const ambientLoc = rl.GetShaderLocation(shadowShader, "ambient");
    const ambient: [4]f32 = [4]f32{ 0.1, 0.1, 0.1, 1.0 };
    // const ambient: [4]f32 = [4]f32{ 0.1, 0.1, 0.1, 1.0 };
    rl.SetShaderValue(shadowShader, ambientLoc, &ambient, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4);

    const lightVPLoc = rl.GetShaderLocation(shadowShader, "lightVP");
    const shadowMapLoc = rl.GetShaderLocation(shadowShader, "shadowMap");
    const shadowMapResolution = 1024;
    const res: [1]i32 = [1]i32{shadowMapResolution};
    const shadowMapResolutionLoc = rl.GetShaderLocation(shadowShader, "shadowMapResolution");
    rl.SetShaderValue(shadowShader, shadowMapResolutionLoc, &res, rl.ShaderUniformDataType.SHADER_UNIFORM_INT);

    var cube = rl.LoadModelFromMesh(rl.GenMeshCube(1, 1, 1));
    cube.materials.?[0].shader = shadowShader;
    const robot = rl.LoadModel("resources/models/robot.glb");
    var i: usize = 0;
    while (i < robot.materialCount) : (i += 1) {
        robot.materials.?[i].shader = shadowShader;
    }

    var animCount: i32 = 0;
    const robotAnimations = rl.LoadModelAnimations("resources/models/robot.glb", @ptrCast(&animCount));

    const shadowMap = LoadShadowmapRenderTexture(shadowMapResolution, shadowMapResolution);

    var lightCam = rl.Camera3D{
        .position = rl.Vector3Scale(lightDir, -15.0),
        .target = rl.Vector3Zero(),
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 20.0,
        .projection = .CAMERA_ORTHOGRAPHIC,
    };
    var fc: i32 = 0;

    while (!rl.WindowShouldClose()) {
        const dt = rl.GetFrameTime();

        const cameraPos = camera.position;
        rl.SetShaderValue(shadowShader, shadowShader.locs.?[@intFromEnum(rl.ShaderLocationIndex.SHADER_LOC_VECTOR_VIEW)], &cameraPos, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC3);
        // rl.SetShaderValue(shadowShader, lightDirLoc, &lightDir, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC3);
        rl.UpdateCamera(&camera, .CAMERA_ORBITAL);

        fc = fc + 1;
        fc = @mod(fc, robotAnimations.?[0].frameCount);
        // fc %= (robotAnimations.?[0].frameCount);
        rl.UpdateModelAnimation(robot, robotAnimations.?[0], fc);

        const cameraSpeed = 0.05;
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT)) {
            if (lightDir.x < 0.6)
                lightDir.x += cameraSpeed * 60.0 * dt;
        }
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT)) {
            if (lightDir.x > -0.6)
                lightDir.x -= cameraSpeed * 60.0 * dt;
        }
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_UP)) {
            if (lightDir.z < 0.6)
                lightDir.z += cameraSpeed * 60.0 * dt;
        }
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_DOWN)) {
            if (lightDir.z > -0.6)
                lightDir.z -= cameraSpeed * 60.0 * dt;
        }
        lightDir = rl.Vector3Normalize(lightDir);
        lightCam.position = rl.Vector3Scale(lightDir, -15.0);
        rl.SetShaderValue(shadowShader, lightDirLoc, &lightDir, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC3);

        rl.BeginDrawing();
        defer rl.EndDrawing();

        var lightView: rl.Matrix = undefined;
        var lightProj: rl.Matrix = undefined;
        rl.BeginTextureMode(shadowMap);
        rl.ClearBackground(rl.WHITE);
        rl.BeginMode3D(lightCam);
        lightView = rl.rlGetMatrixModelview();
        lightProj = rl.rlGetMatrixProjection();
        DrawScene(cube, robot);
        rl.EndMode3D();
        rl.EndTextureMode();
        const lightViewProj: rl.Matrix = rl.MatrixMultiply(lightView, lightProj);

        rl.ClearBackground(rl.RAYWHITE);

        rl.SetShaderValueMatrix(shadowShader, lightVPLoc, lightViewProj);

        rl.rlEnableShader(shadowShader.id);
        var slot: i32 = 10;
        rl.rlActiveTextureSlot(10);
        rl.rlEnableTexture(shadowMap.depth.id);
        rl.rlSetUniform(shadowMapLoc, @ptrCast(&slot), @intFromEnum(rl.ShaderUniformDataType.SHADER_UNIFORM_INT), 1);

        rl.BeginMode3D(camera);
        DrawScene(cube, robot);
        rl.EndMode3D();

        rl.DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, rl.GRAY);
        rl.DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, rl.RED);
    }

    rl.UnloadShader(shadowShader);
    rl.UnloadModel(cube);
    rl.UnloadModel(robot);
    rl.UnloadModelAnimations(robotAnimations, animCount);
    UnloadShadowmapRenderTexture(shadowMap);
}

pub fn LoadShadowmapRenderTexture(width: i32, height: i32) rl.RenderTexture2D {
    var target: rl.RenderTexture2D = undefined;

    target.id = rl.rlLoadFramebuffer(width, height); // Load an empty framebuffer
    target.texture.width = width;
    target.texture.height = height;

    if (target.id > 0) {
        rl.rlEnableFramebuffer(target.id);

        // Create depth texture
        // We don't need a color texture for the shadowmap
        target.depth.id = rl.rlLoadTextureDepth(width, height, false);
        target.depth.width = width;
        target.depth.height = height;
        target.depth.format = 19; // DEPTH_COMPONENT_24BIT?
        target.depth.mipmaps = 1;

        // Attach depth texture to FBO
        rl.rlFramebufferAttach(target.id, target.depth.id, @intFromEnum(rl.rlFramebufferAttachType.RL_ATTACHMENT_DEPTH), @intFromEnum(rl.rlFramebufferAttachTextureType.RL_ATTACHMENT_TEXTURE2D), 0);

        // Check if FBO is complete with attachments (valid)
        if (rl.rlFramebufferComplete(target.id)) std.log.info("FBO: [ID {d}] Framebuffer object created successfully", .{target.id});

        rl.rlDisableFramebuffer();
    } else std.log.warn("FBO: Framebuffer object cannot be created", .{});

    return target;
}

pub fn UnloadShadowmapRenderTexture(target: rl.RenderTexture2D) void {
    if (target.id > 0) {
        rl.rlUnloadFramebuffer(target.id);
    }
}

pub fn DrawScene(cube: rl.Model, robot: rl.Model) void {
    const vecUp: rl.Vector3 = .{ .x = 0.0, .y = 1.0, .z = 0.0 };
    rl.DrawModelEx(cube, rl.Vector3Zero(), vecUp, 0.0, .{ .x = 10.0, .y = 1.0, .z = 10.0 }, rl.BLUE);
    rl.DrawModelEx(cube, .{ .x = 1.5, .y = 1.0, .z = -1.5 }, vecUp, 0.0, rl.Vector3One(), rl.WHITE);
    rl.DrawModelEx(robot, .{ .x = 0.0, .y = 0.5, .z = 0.0 }, vecUp, 0.0, .{ .x = 1.0, .y = 1.0, .z = 1.0 }, rl.RED);
}
