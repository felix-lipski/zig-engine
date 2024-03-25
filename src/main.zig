const std = @import("std");
const rl = @import("raylib");
const zphy = @import("zphysics");
const zm = @import("zmath");
const Render = @import("render.zig");
const Jolt = @import("jolt.zig");
const Colors = @import("colors.zig");
const game_world = @import("game_world.zig");

pub fn vec3jtr(in: [3]zphy.Real) rl.Vector3 {
    return rl.Vector3{ .x = in[0], .y = in[1], .z = in[2] };
}

const upVector = rl.Vector3{ .x = 0, .y = 1, .z = 0 };

const RndGen = std.rand.DefaultPrng;

const Player = struct {
    height: f32,
    radius: f32,
    halfHeight: f32,
    character: *zphy.Character,
    headCamera: *rl.Camera3D,
    firstPerson: bool = false,

    pub fn init(joltWrapper: *Jolt.JoltWrapper, inCamera: *rl.Camera3D) anyerror!Player {
        const height = 1.8;
        const radius = 0.25;
        const halfHeight = (height / 2.0) - radius;
        const capsuleSettings = try zphy.CapsuleShapeSettings.create(radius, halfHeight);
        defer capsuleSettings.release();
        const capsuleShape = try capsuleSettings.createShape();
        defer capsuleShape.release();

        const characterSettings = try zphy.CharacterSettings.create();
        defer characterSettings.release();
        characterSettings.base = .{
            .up = .{ 0, 1, 0, 0 },
            .supporting_volume = .{ 0, -1, 0, 0 },
            .max_slope_angle = 0.78,
            .shape = capsuleShape,
        };
        characterSettings.layer = Jolt.object_layers.moving;
        characterSettings.mass = 10.0;
        characterSettings.friction = 20.0;
        characterSettings.gravity_factor = 1.0;

        const character = try zphy.Character.create(characterSettings, .{ 0, 1, 0 }, .{ 0, 0, 0, 1 }, 0, joltWrapper.physics_system);
        character.addToPhysicsSystem(.{});

        return Player{ .character = character, .headCamera = inCamera, .height = height, .radius = radius, .halfHeight = halfHeight };
    }

    pub fn process(self: *Player) void {
        if (rl.IsKeyPressed(rl.KeyboardKey.KEY_W)) {
            self.firstPerson = !self.firstPerson;
        }
        self.moveHead();
        self.walk();
    }

    pub fn walk(self: *Player) void {
        const linVel = vec3jtr(self.character.getLinearVelocity());
        var linVelHorizontal = linVel;
        linVelHorizontal.y = 0;
        var forward = self.headCamera.target.sub(self.headCamera.position);
        forward.y = 0;
        forward = forward.normalize();
        // const forward = rl.Vector3Project(self.headCamera.target.sub(self.headCamera.position), upVector).normalize();
        const perp = rl.Vector3CrossProduct(forward, upVector).normalize();

        var desiredHorizontal = rl.Vector3Zero();
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_E)) {
            desiredHorizontal = desiredHorizontal.add(forward);
        }
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_D)) {
            desiredHorizontal = desiredHorizontal.sub(forward);
        }
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_F)) {
            desiredHorizontal = desiredHorizontal.add(perp);
        }
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_S)) {
            desiredHorizontal = desiredHorizontal.sub(perp);
        }
        desiredHorizontal = desiredHorizontal.normalize().scale(5);

        if (linVelHorizontal.length() < desiredHorizontal.length()) {
            self.character.setLinearVelocity(.{ desiredHorizontal.x, linVel.y, desiredHorizontal.z });
        }
    }

    pub fn moveHead(self: *Player) void {
        const mouseDelta = rl.GetMouseDelta();
        var arm = self.headCamera.target.sub(self.headCamera.position);
        arm = rl.Vector3RotateByAxisAngle(arm, .{ .y = 1 }, -mouseDelta.x / 100);

        const perp = rl.Vector3CrossProduct(arm, upVector).normalize();
        arm = rl.Vector3RotateByAxisAngle(arm, perp, -mouseDelta.y / 100);

        const position = self.character.getPosition();
        self.headCamera.target = vec3jtr(position);
        self.headCamera.position = self.headCamera.target.sub(arm);

        if (self.firstPerson) {
            var target = self.headCamera.target;
            target.y += 0.8;
            self.headCamera.position = target;
            self.headCamera.target = target.add(arm);
            self.headCamera.fovy = 80;
        } else {
            self.headCamera.fovy = 55;
        }
    }

    pub fn drawWires(self: *Player, joltWrapper: *Jolt.JoltWrapper) void {
        _ = joltWrapper;
        const position = self.character.getPosition();
        if (!self.firstPerson) {
            rl.DrawCapsuleWires(rl.Vector3{
                .x = position[0],
                .y = position[1] - self.halfHeight + self.radius,
                .z = position[2],
            }, rl.Vector3{
                .x = position[0],
                .y = position[1] + self.halfHeight - self.radius,
                .z = position[2],
            }, self.radius * 2, 8, 4, Colors.white);
        }
    }
};
// const name = rl.Color{.r=255, .g=255, .b=255};

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
    rl.DisableCursor();
    defer rl.CloseWindow();

    var camera = rl.Camera3D{
        .position = .{ .x = 10.0, .y = 10.0, .z = 10.0 },
        .target = .{ .x = 0.0, .y = 0.5, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        // .fovy = 45.0,
        .fovy = 45.0,
        .projection = .CAMERA_PERSPECTIVE,
    };

    var shadowMapper = Render.ShadowMapper.init();

    const body_interface = joltWrapper.physics_system.getBodyInterfaceMut();

    var player = try Player.init(joltWrapper, &camera);

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
        const floorObject = game_world.GameObject{ .model = floorModel, .tint = Colors.darkgreen, .bodyId = floorBodyId };
        try game_world.game_world.?.gameObjects.append(floorObject);
    }

    {
        var prng = std.rand.DefaultPrng.init(0);
        var buffer = [_]rl.Color{ Colors.yellow, Colors.blue, Colors.cyan, Colors.red, Colors.brown, Colors.green, Colors.verydarkblue, Colors.darkblue };
        // prng.random.float(f32)
        for (0..40) |i| {
            const size = prng.random().float(f32) * 0.3 + 0.1;
            // const scaleHalf = scale * 0.5;
            const box_shape_settings = try zphy.BoxShapeSettings.create(.{ size, size, size });
            defer box_shape_settings.release();
            const box_shape = try box_shape_settings.createShape();
            defer box_shape.release();
            const floatI: f32 = @floatFromInt(i);
            const body = try body_interface.createBody(.{
                // .position = .{ floatI * 0.1, floatI * 2.0 + 2.0, floatI * 0.1, 1.0 },
                .position = .{ prng.random().float(f32) * 10 - 5, floatI * 0.2, prng.random().float(f32) * 10 - 5, 1.0 },
                .rotation = .{ 0.0, 0.0, 0.0, 1.0 },
                .shape = box_shape,
                .motion_type = .dynamic,
                .object_layer = Jolt.object_layers.moving,
                .angular_velocity = .{ 0.0, 0.0, 0.0, 0 },
            });
            body_interface.addBody(body.id, .activate);

            // const cube1 = rl.LoadModelFromMesh(rl.GenMeshCube(1, 1, 1));
            const cube1 = rl.LoadModelFromMesh(rl.GenMeshCube(size * 2, size * 2, size * 2));
            shadowMapper.InjectShadowShader(cube1);
            prng.random().shuffle(rl.Color, &buffer);
            const cube1_object = game_world.GameObject{ .model = cube1, .tint = buffer[0], .bodyId = body.id };
            try game_world.game_world.?.gameObjects.append(cube1_object);
        }
    }

    joltWrapper.physics_system.optimizeBroadPhase();

    while (!rl.WindowShouldClose()) {
        joltWrapper.update();
        shadowMapper.UpadateCamera(player.headCamera.*);
        player.process();

        rl.BeginDrawing();
        defer rl.EndDrawing();

        shadowMapper.RenderGameObjects(joltWrapper);

        rl.BeginMode3D(player.headCamera.*);
        Render.DrawScene(joltWrapper);
        player.drawWires(joltWrapper);
        rl.EndMode3D();
    }

    rl.UnloadShader(shadowMapper.shadowShader);
    // FIX IT
    // for (game_world.game_world.gameObjects.items) |object| {
    //     rl.UnloadModel(object.model);
    // }
    shadowMapper.UnloadShadowmapRenderTexture();
    joltWrapper.destroy(allocator);
}
