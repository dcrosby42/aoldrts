CR =  require '../utils/component_register.coffee'
C = require './components.coffee'
ParkMillerRNG = require '../utils/pm_prng.coffee'
MapHelpers = require './map_helpers.coffee'

class EntityFactory
  constructor: (@ecs) ->

  generateRobotFrameList: (robotName) ->
    if robotName.indexOf("robot_4") == 0
      {
        down: ["#{robotName}_down_0","#{robotName}_down_1","#{robotName}_down_2", "#{robotName}_down_1"]
        left: ["#{robotName}_left_0","#{robotName}_left_1","#{robotName}_left_2", "#{robotName}_left_1"]
        up: ["#{robotName}_up_0","#{robotName}_up_1","#{robotName}_up_2", "#{robotName}_up_1"]
        right: ["#{robotName}_right_0","#{robotName}_right_1","#{robotName}_right_2", "#{robotName}_right_1"]
        downIdle: ["#{robotName}_down_0","#{robotName}_down_1","#{robotName}_down_2", "#{robotName}_down_1"]
        leftIdle: ["#{robotName}_left_0","#{robotName}_left_1","#{robotName}_left_2", "#{robotName}_left_1"]
        upIdle: ["#{robotName}_up_0","#{robotName}_up_1","#{robotName}_up_2", "#{robotName}_up_1"]
        rightIdle: ["#{robotName}_right_0","#{robotName}_right_1","#{robotName}_right_2", "#{robotName}_right_1"]
      }
    else
      {
        down: ["#{robotName}_down_0","#{robotName}_down_1","#{robotName}_down_2", "#{robotName}_down_1"]
        left: ["#{robotName}_left_0","#{robotName}_left_1","#{robotName}_left_2", "#{robotName}_left_1"]
        up: ["#{robotName}_up_0","#{robotName}_up_1","#{robotName}_up_2", "#{robotName}_up_1"]
        right: ["#{robotName}_right_0","#{robotName}_right_1","#{robotName}_right_2", "#{robotName}_right_1"]
        downIdle: ["#{robotName}_down_1"]
        leftIdle: ["#{robotName}_left_1"]
        upIdle: ["#{robotName}_up_1"]
        rightIdle: ["#{robotName}_right_1"]
      }

  robot: (x,y,robotName) ->
    console.log "robot", robotName
    robot = @ecs.create()
    robot.add(new C.Position(x: x, y: y), CR.get(C.Position))
    robot.add(new C.Sprite(name: robotName, framelist: @generateRobotFrameList(robotName)), CR.get(C.Sprite))
    robot.add(new C.Controls(), CR.get(C.Controls))
    robot.add(new C.Movement(vx: 0, vy: 0, speed:15), CR.get(C.Movement))
    robot.add(new C.Wander(range: 50), CR.get(C.Wander))
    robot.add(new C.Health(maxHealth: 100, health: 100), CR.get(C.Health))
    robot

  powerup: (x, y, powerup_type) ->
    crystal_frames = ("#{powerup_type}-crystal#{i}" for i in  [0..7])
    powerup_frames = {
      downIdle: crystal_frames
      down: crystal_frames
    }
    p = @ecs.create()
    p.add(new C.Position(x: x, y: y), CR.get(C.Position))
    # movement just added 
    p.add(new C.Movement(vx: 0, vy: 0), CR.get(C.Movement))
    p.add(new C.Powerup(powerup_type: powerup_type), CR.get(C.Powerup))
    p.add(new C.Sprite(name: "#{powerup_type}-crystal", framelist: powerup_frames), CR.get(C.Sprite))
    p

  mapTiles: (seed, width, height) ->
    mapTiles = @ecs.create()
    comp = new C.MapTiles(seed: seed, width: width, height: height)
    mapTiles.add(comp, CR.get(C.MapTiles))
    prng = new ParkMillerRNG(seed)
    MapHelpers.eachMapTile prng, width, height, (x, y, tile_set, base, feature, spare) =>
      sparePRNG = new ParkMillerRNG(spare)
      if feature == "crater"
        p = sparePRNG.weighted_choose([["blue", 25], ["green", 25], [null, 50]])
        if p?
          @powerup(x + 32, y + 32, p)

    mapTiles

module.exports = EntityFactory
