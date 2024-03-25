// const characterVirtualSettings = try zphy.CharacterVirtualSettings.create();
// characterVirtualSettings.base.shape = capsuleShape;
// characterVirtualSettings.base.max_slope_angle = 0.78;
// characterVirtualSettings.max_strength = 100.0;
// characterVirtualSettings.back_face_mode = zphy.BackFaceMode.collide_with_back_faces;
// characterVirtualSettings.character_padding = 0.02;
// characterVirtualSettings.penetration_recovery_speed = 1.0;
// characterVirtualSettings.predictive_contact_distance = 0.1;
// // characterVirtualSettings.base.supporting_volume = .{ 0, 1, 0, 0 };
// // characterVirtualSettings.SupportingVolume = Plane(Vec3::sAxisY(), -cCharacterRadiusStanding);

// // static inline EBackFaceMode sBackFaceMode = EBackFaceMode::CollideWithBackFaces;
// // sUpRotationX = 0;
// // sUpRotationZ = 0;
// // sCharacterPadding = 0.02f;
// // sPenetrationRecoverySpeed = 1.0f;
// // sPredictiveContactDistance = 0.1f;
// // sEnableWalkStairs = true;
// // sEnableStickToFloor = true;

// defer characterVirtualSettings.release();
// const characterVirtual = try zphy.CharacterVirtual.create(characterVirtualSettings, .{ 0, 6, 0 }, .{ 0, 0, 0, 1 }, joltWrapper.physics_system);
