const std = @import("std");
const rl = @import("raylib");
const zphy = @import("zphysics");

pub const GameObject = struct { model: rl.Model, position: rl.Vector3, tint: rl.Color = rl.WHITE, bodyId: zphy.BodyId };

const ArrayList = std.ArrayList;

pub const GameWorld = struct {
    gameObjects: ArrayList(GameObject),
    pub fn init(allocator: std.mem.Allocator) GameWorld {
        return GameWorld{ .gameObjects = ArrayList(GameObject).init(allocator) };
    }
};

pub var game_world: ?GameWorld = null;
