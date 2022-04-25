local Settings = {}

Settings.SENSITIVITY = 1 -- how quick/snappy the sway movements are. Don't go above 2
Settings.SWAY_SIZE = 1 -- how large/powerful the sway is. Don't go above 2
Settings.INCLUDE_STRAFE = true -- if true the fps arms will sway when the character is strafing
Settings.INCLUDE_WALK_SWAY = true -- if true, fps arms will sway when you are walking
Settings.INCLUDE_CAMERA_SWAY = true -- if true, fps arms will sway when you move the camera
Settings.INCLUDE_JUMP_SWAY = true -- if true, jumping will have an effect on the viewmodel
Settings.RUNNING_SPEED = true -- if true, jumping will have an effect on the viewmodel
Settings.HEAD_OFFSET = Vector3.new(0,0,0) -- the offset from the default camera position of the head. (0,1,0) will put the camera one stud above the head.
Settings.ARM_TRANSPARENCY = 0 -- the transparency of the arms in first person; set to 1 for invisible and set to 0 for fully visible.
Settings.WAIST_MOVEMENTS = true -- if true, animations will affect the Uppertorso. If false, the uppertorso stays still while in first person (applies to R15 only)


return Settings