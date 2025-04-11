Config = {}
Config.StartLocation = vector3(-842.18, -1205.39, 43.53)
Config.GameArea = vector3(-840.46, -1194.84, 43.57)
Config.BoxProp = 'p_crate01x'
Config.TargetProps = { 'p_bottlebrandy01x', 'p_bottlewine01x', 'p_bottlecognac01x', 'p_bottlechampagne01x' }
Config.GameDuration = 60
Config.MaxTargets = 5
Config.PromptText = 'Shoot the targets!'
Config.SpawnOffsets = {
    {x = -4, y = 0},  -- Leftmost (west)
    {x = -2, y = 0},
    {x = 0,  y = 0},  -- Center
    {x = 2,  y = 0},
    {x = 4,  y = 0}   -- Rightmost (east)
}