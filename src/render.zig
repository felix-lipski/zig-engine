const std = @import("std");
const rl = @import("raylib");
const zphy = @import("zphysics");
const Main = @import("main.zig");
const Jolt = @import("jolt.zig");
const Colors = @import("colors.zig");
const game_world = @import("game_world.zig");

const vecUp: rl.Vector3 = .{ .x = 0.0, .y = 1.0, .z = 0.0 };

pub const ShadowMapper = struct {
    lightCam: rl.Camera3D,
    lightVPLoc: i32,
    shadowMapLoc: i32,
    shadowMap: rl.RenderTexture2D,
    shadowMapResolution: i32,
    shadowShader: rl.Shader,

    pub fn init() ShadowMapper {
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
        rl.SetShaderValue(shadowShader, ambientLoc, &ambient, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4);

        const lightVPLoc = rl.GetShaderLocation(shadowShader, "lightVP");
        const shadowMapLoc = rl.GetShaderLocation(shadowShader, "shadowMap");
        const shadowMapResolution = 1024;
        const res: [1]i32 = [1]i32{shadowMapResolution};
        const shadowMapResolutionLoc = rl.GetShaderLocation(shadowShader, "shadowMapResolution");
        rl.SetShaderValue(shadowShader, shadowMapResolutionLoc, &res, rl.ShaderUniformDataType.SHADER_UNIFORM_INT);

        const shadowMap = LoadShadowmapRenderTexture(shadowMapResolution, shadowMapResolution);

        const lightCam = rl.Camera3D{
            .position = rl.Vector3Scale(lightDir, -15.0),
            .target = rl.Vector3Zero(),
            .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
            .fovy = 20.0,
            .projection = .CAMERA_ORTHOGRAPHIC,
        };

        return ShadowMapper{
            .lightCam = lightCam,
            .lightVPLoc = lightVPLoc,
            .shadowMapLoc = shadowMapLoc,
            .shadowMap = shadowMap,
            .shadowShader = shadowShader,
            .shadowMapResolution = shadowMapResolution,
        };
    }

    pub fn RenderGameObjects(self: *ShadowMapper, joltWrapper: *Jolt.JoltWrapper) void {
        var lightView: rl.Matrix = undefined;
        var lightProj: rl.Matrix = undefined;
        rl.BeginTextureMode(self.shadowMap);
        rl.ClearBackground(rl.WHITE);
        rl.BeginMode3D(self.lightCam);
        lightView = rl.rlGetMatrixModelview();
        lightProj = rl.rlGetMatrixProjection();
        DrawScene(joltWrapper);
        rl.EndMode3D();
        rl.EndTextureMode();
        const lightViewProj: rl.Matrix = rl.MatrixMultiply(lightView, lightProj);

        rl.ClearBackground(Colors.black);

        rl.SetShaderValueMatrix(self.shadowShader, self.lightVPLoc, lightViewProj);

        rl.rlEnableShader(self.shadowShader.id);
        var slot: i32 = 10;
        rl.rlActiveTextureSlot(10);
        rl.rlEnableTexture(self.shadowMap.depth.id);
        rl.rlSetUniform(self.shadowMapLoc, @ptrCast(&slot), @intFromEnum(rl.ShaderUniformDataType.SHADER_UNIFORM_INT), 1);
    }

    pub fn InjectShadowShader(self: *ShadowMapper, model: rl.Model) void {
        var i: usize = 0;
        while (i < model.materialCount) : (i += 1) {
            model.materials.?[i].shader = self.shadowShader;
        }
    }

    pub fn LoadShadowmapRenderTexture(width: i32, height: i32) rl.RenderTexture2D {
        var target: rl.RenderTexture2D = undefined;

        target.id = rl.rlLoadFramebuffer(); // Load an empty framebuffer
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

    pub fn UnloadShadowmapRenderTexture(self: *ShadowMapper) void {
        if (self.shadowMap.id > 0) {
            rl.rlUnloadFramebuffer(self.shadowMap.id);
        }
    }

    pub fn UpadateCamera(self: *ShadowMapper, camera: rl.Camera3D) void {
        rl.SetShaderValue(self.shadowShader, self.shadowShader.locs.?[@intFromEnum(rl.ShaderLocationIndex.SHADER_LOC_VECTOR_VIEW)], &camera.position, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC3);
    }
};

pub fn DrawScene(joltWrapper: *Jolt.JoltWrapper) void {
    const bodyInterface = joltWrapper.physics_system.getBodyInterface();
    if (game_world.game_world) |world| {
        for (world.gameObjects.items) |gameObject| {
            DrawBody(gameObject, bodyInterface);
        }
    }
}

pub fn DrawBody(object: game_world.GameObject, bodyInterface: *const zphy.BodyInterface) void {
    const radianScale = 57.295;
    const rotation = bodyInterface.getRotation(object.bodyId);
    const quat = .{ .x = rotation[0], .y = rotation[1], .z = rotation[2], .w = rotation[3] };
    var outAngle: f32 = 0;
    var outAxis = rl.Vector3{};
    rl.QuaternionToAxisAngle(quat, @ptrCast(&outAxis), @ptrCast(&outAngle));
    outAngle *= radianScale;

    const position = bodyInterface.getPosition(object.bodyId);
    const rlPosition = .{ .x = position[0], .y = position[1], .z = position[2] };
    rl.DrawModelEx(object.model, rlPosition, outAxis, outAngle, rl.Vector3One(), object.tint);
}
