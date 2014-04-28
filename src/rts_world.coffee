Array::compact = ->
  (elem for elem in this when elem?)

ChecksumCalculator = require './checksum_calculator.coffee'
ParkMillerRNG = require './pm_prng.coffee'

ComponentRegister = (->
  nextType = 0
  ctors = []
  types = []
  register: (ctor) ->
    i = ctors.indexOf(ctor)
    if i < 0
      ctors.push ctor
      types.push nextType++
    return

  get: (ctor) ->
    i = ctors.indexOf(ctor)
    throw "Unknown type " + ctor  if i < 0
    types[i]
)()

makr.World.prototype.resurrect = (entId) ->
  entity = null
  if (@_dead.length > 0)
    entity = @_dead.pop()
    entity._alive = true
    entity._id = entId
    entity._componentMask.reset()
  else
    entity = new makr.Entity(@, +entId)

  @_alive.push(entity)
  entity

class Owned
  constructor: ({@playerId}) ->

class Position
  constructor: ({@x, @y}) ->

class Movement
  constructor: ({@vx, @vy}) ->

class MapTiles
  constructor: ({@seed, @width, @height}) ->

class MapTilesSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(MapTiles))
    @tilesSprites = undefined

  onRemoved: (entity) ->
    if @tilesSprites?
      @pixiWrapper.sprites.removeChild(@tilesSprites)
      @tilesSprites = undefined
    
  process: (entity, elapsed) ->
    unless @tilesSprites?
      component = entity.get(ComponentRegister.get(MapTiles))
      @tilesSprites = @createTiles(component.seed)
      @pixiWrapper.sprites.addChildAt(@tilesSprites,0) # ADD ALL THE WAY AT THE BOTTOM

  createTile: (tiles, frame, x, y) ->
    tile = new PIXI.Sprite(PIXI.Texture.fromFrame(frame))
    tile.position.x = x
    tile.position.y = y
    tile

  createTiles: (seed) ->
    tile_sets = ["gray_set_", "orange_set_", "dark_brown_set_", "dark_set_"]
    features = [["", 90], ["feature0", 4], ["feature1", 4], ["feature2", 2]]
    bases = [["basic0", 5], ["basic1", 50], ["basic2", 50]]

    tiles = new PIXI.DisplayObjectContainer()
    prng = new ParkMillerRNG(seed)
    tile_set = prng.choose(tile_sets)
    tiles.position.x = 0
    tiles.position.y = 0
    tileSize = 31
    # tile backwards so that bigger features are overlaid right
    for x in [3200..0] by -tileSize
      for y in [3200..0] by -tileSize
        base = prng.weighted_choose(bases)
        frame = tile_set + base + ".png"
        tiles.addChild(@createTile(tiles, frame, x, y))

        feature = prng.weighted_choose(features)
        if feature != ""
          feature_frame = tile_set + feature + ".png"
          tiles.addChild(@createTile(tiles, feature_frame, x, y))

    tiles.cacheAsBitmap = true
    tiles.position.x = -1600
    tiles.position.y = -1600
    tiles

class CommandQueueSystem extends makr.IteratingSystem
  constructor: (@commandQueue, @entityFinder) ->
    makr.IteratingSystem.call(@)
    
  processEntities: ->
    commands = []
    while cmd = @commandQueue.shift()
      commands.push(cmd)
    for cmd in commands
      # command, playerId, entityId
      targetEntity = @entityFinder.findEntityById(cmd.entityId)
      owned = targetEntity.get(ComponentRegister.get(Owned))
      if owned and (cmd.playerId == owned.playerId)
        if cmd.command == "march"
          movement = targetEntity.get(ComponentRegister.get(Movement))
          if cmd.args.direction == "left"
            movement.vx = -10
          else
            movement.vx = 10
        else
          console.log "CommandQueueSystem: UNKNOWN COMMAND:", cmd
      else
        console.log "CommandQueueSystem: ILLEGAL INSTRUCTION, player #{cmd.playerId} may not command entity #{cmd.entityId} because it's owned by #{owned.playerId}"
          

class Sprite
  constructor: ({@name, @framelist, @facing}) ->
    @remove = false
    @add = true
    @facing ||= "down"
    @idle = true

class Controls
  constructor: () ->
    @up = false
    @down = false
    @left = false
    @right = false

class EntityInspectorSystem extends makr.IteratingSystem
  constructor: (@inspector, @componentClass) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(@componentClass))

  process: (entity, elapsed) ->
    component = entity.get(ComponentRegister.get(@componentClass))
    @inspector.update entity.id, component # should be a COPY of the component?


class ControlSystem extends makr.IteratingSystem
  constructor: (@rtsWorld) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Controls))
    @registerComponent(ComponentRegister.get(Owned))

  process: (entity, elapsed) ->
    controls = entity.get(ComponentRegister.get(Controls))
    # owner = entity.get(ComponentRegister.get(Controls))

    entityControls = @rtsWorld.currentControls[entity.id] || []

    # If there are two events of the same type, only the last one in the list
    # will end up having an effect in the system.
    #
    # TODO: Consider figuring out a way to explicitly cycle these events
    # through the system.
    for [action, value] in entityControls
      controls[action] = value

    @rtsWorld.currentControls[entity.id] = []


class ControlMappingSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Movement))
    @registerComponent(ComponentRegister.get(Controls))

  process: (entity, elapsed) ->
    # movement = entity.get(ComponentRegister.get(Movement))
    # controls = entity.get(ComponentRegister.get(Controls))

    # if controls.up
    #   movement.vy = -BUNNY_VEL
    # else if controls.down
    #   movement.vy = BUNNY_VEL
    # else
    #   movement.vy = 0
    # if controls.left
    #   movement.vx = -BUNNY_VEL
    # else if controls.right
    #   movement.vx = BUNNY_VEL
    # else
    #   movement.vx = 0

class MovementSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Movement))
    @registerComponent(ComponentRegister.get(Position))

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(Position))
    movement = entity.get(ComponentRegister.get(Movement))
    console.log("Y NO Position?", entity) unless position?
    position.x += movement.vx * elapsed
    position.y += movement.vy * elapsed

class SpriteSyncSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Sprite))
    @registerComponent(ComponentRegister.get(Position))
    @registerComponent(ComponentRegister.get(Movement))
    @spriteCache = {}
    @spriteFrameCache = {}

  onRemoved: (entity) ->
    @pixiWrapper.sprites.removeChild(@spriteCache[entity.id])
    @spriteCache[entity.id] = undefined

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(Position))
    sprite = entity.get(ComponentRegister.get(Sprite))
    movement = entity.get(ComponentRegister.get(Movement))

    pixiSprite = @spriteCache[entity.id]
    unless pixiSprite?
      pixiSprite = @buildSprite(entity, sprite, position)
    else if sprite.remove
      @removeSprite(entity, sprite)
    else
      pixiSprite.position.x = position.x
      pixiSprite.position.y = position.y

    switch
      when movement.vx > 0
        sprite.facing = "right"
        sprite.idle = false
      when movement.vx < 0
        sprite.facing = "left"
        sprite.idle = false
      when movement.vy > 0
        sprite.facing = "down"
        sprite.idle = false
      when movement.vy < 0
        sprite.facing = "up"
        sprite.idle = false
      else
        sprite.idle = true

    if sprite.framelist
      if sprite.idle
        pixiSprite.textures = @spriteFrameCache[sprite.name]["#{sprite.facing}Idle"]
      else
        pixiSprite.textures = @spriteFrameCache[sprite.name][sprite.facing]
    
  buildSprite: (entity, sprite, position) ->
    pixiSprite = undefined
    if sprite.framelist
      unless @spriteFrameCache[sprite.name]
        frameCache = {}
        for pose, frames of sprite.framelist
          frameCache[pose] = (new PIXI.Texture.fromFrame(frame) for frame in frames)
        @spriteFrameCache[sprite.name] = frameCache
      pixiSprite = new PIXI.MovieClip(@spriteFrameCache[sprite.name][sprite.facing])
      pixiSprite.animationSpeed = 0.0825
      pixiSprite.play()
    else
      pixiSprite = new PIXI.Sprite(PIXI.Texture.fromFrame(sprite.name))
    pixiSprite.anchor.x = pixiSprite.anchor.y = 0.5
    pixiSprite.position.x = position.x
    pixiSprite.position.y = position.y
    pixiSprite.setInteractive(true)
    
    @pixiWrapper.addMiddleGroundSprite( pixiSprite, entity.id )

    sprite.add = false
    @spriteCache[entity.id] = pixiSprite

  removeSprite: (entity, sprite) ->
    @pixiWrapper.sprites.removeChild @spriteCache[entity.id]
    delete @spriteCache[entity.id]
    sprite.remove = false

# vec2 = (x,y) -> new Box2D.Common.Math.b2Vec2(x,y)
fixFloat = SimSim.Util.fixFloat
HalfPI = Math.PI/2

class EntityFactory
  constructor: (@ecs) ->

  generateRobotFrameList: (robotName) ->
    if robotName.indexOf("floaty") == 0
      {
        down: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        left: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        up: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        right: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        downIdle: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        leftIdle: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        upIdle: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
        rightIdle: ["#{robotName}_frame_0","#{robotName}_frame_1","#{robotName}_frame_2", "#{robotName}_frame_1"]
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
    robot.add(new Position(x: x, y: y), ComponentRegister.get(Position))
    robot.add(new Sprite(name: robotName, framelist: @generateRobotFrameList(robotName)), ComponentRegister.get(Sprite))
    robot.add(new Controls(), ComponentRegister.get(Controls))
    robot.add(new Movement(vx: 0, vy: 0), ComponentRegister.get(Movement))
    robot

  mapTiles: (seed, width, height) ->
    mapTiles = @ecs.create()
    comp = new MapTiles(seed: seed, width: width, height: height)
    mapTiles.add(comp, ComponentRegister.get(MapTiles))
    mapTiles

BUNNY_VEL = 3
class RtsWorld extends SimSim.WorldBase
  constructor: ({@pixiWrapper, @entityInspector}) ->
    @pixiWrapper or throw new Error("Need pixiWrapper")
    @commandQueue = []

    @checksumCalculator = new ChecksumCalculator()
    @ecs = @setupECS(@pixieWrapper)
    @entityFactory = new EntityFactory(@ecs)
    @currentControls = {}
    @setupEntityInspector(@ecs,@entityInspector) if @entityInspector
    @entityFactory.mapTiles((Math.random() * 1000)|0, 50, 50)

  setupECS: (pixieWrapper) ->
    ComponentRegister.register(Position)
    ComponentRegister.register(Sprite)
    ComponentRegister.register(Owned)
    ComponentRegister.register(Movement)
    ComponentRegister.register(Controls)
    ComponentRegister.register(MapTiles)
    ecs = new makr.World()
    ecs.registerSystem(new SpriteSyncSystem(@pixiWrapper))
    ecs.registerSystem(new MapTilesSystem(@pixiWrapper))
    ecs.registerSystem(new CommandQueueSystem(@commandQueue, @))  # passing "this" as the entityFinder
    ecs.registerSystem(new MovementSystem())
    ecs.registerSystem(new ControlMappingSystem())
    ecs

  setupEntityInspector: (ecs, entityInspector) ->
    for componentClass in [ Position,Movement,Owned,MapTiles ]
      ecs.registerSystem(new EntityInspectorSystem(entityInspector, componentClass))
    entityInspector

  findEntityById: (id) ->
    (entity for entity in @ecs._alive when "#{entity.id}" == "#{id}")[0]

  resetData: ->

  deserializeComponent: (serializedComponent) ->
    eval("new #{serializedComponent.type}(serializedComponent)")

  #
  # Invocable via proxy:
  #
  # XXX:
  summonMyRobot: (playerId, x, y) ->
    robot = @entityFactory.robot(x, y, "robot_1")
    robot.add(new Owned(playerId: playerId), ComponentRegister.get(Owned))

  # XXX:
  summonTheirRobot: (playerId, x, y) ->
    robot = @entityFactory.robot(x, y, "robot_2")
    robot.add(new Owned(playerId: "WAT"), ComponentRegister.get(Owned))

  commandUnit: (playerId, command, entityId, args={}) ->
    @commandQueue.push(
      command: command,
      playerId: playerId
      entityId: entityId
      args: args
    )
    
  #### SimSim.WorldBase#playerJoined(id)
  playerJoined: (playerId) ->

  #### SimSim.WorldBase#playerLeft(id)
  playerLeft: (playerId) ->
    console.log "Player #{playerId} LEFT"
    for ent in @ecs._alive
      owner = ent.get(ComponentRegister.get(Owned))
      ent.kill() if owner? && (owner.playerId == playerId)

  #### SimSim.WorldBase#theEnd()
  theEnd: ->
    @resetData()
    console.log "THE END"

  #### SimSim.WorldBase#step(data)
  step: (dt) ->
    @ecs.update(dt)
  
  #### SimSim.WorldBase#setData()
  setData: (data) ->
    @players = data.players
    @ecs._nextEntityID = data.nextEntityId
    console.log "setData: @ecs._nextEntityID set to #{@ecs._nextEntityID}"
    staleEnts = @ecs._alive[..]
    for ent in staleEnts
      console.log "setData: killing entity #{ent.id}", ent
      #XXX ent._componentMask.reset() # shouldn't be needed, kill() does this
      ent.kill()

    for entId, components of data.componentBags
      entity = @ecs.resurrect(entId)
      console.log "setData: resurrected entity for entId=#{entId}:", entity
      comps = (@deserializeComponent(c) for c in components)
      entity._componentMask.reset()
      for comp in comps
        console.log "setData: adding component to #{entity.id}:", comp
        entity.add(comp, ComponentRegister.get(comp.constructor))

  #### SimSim.WorldBase#getData()
  getData: ->
    componentBags = {}
    for entId, components of @ecs._componentBags
      ent = @findEntityById(entId)
      if ent? and ent.alive
        componentBags[entId] = (@serializeComponent(c) for c in components.compact())

    data =
      players: @players
      componentBags: componentBags
      nextEntityId: @ecs._nextEntityID
    console.log data
    data

  serializeComponent: (component) ->
    serializedComponent = {}
    if component
      for name, value of component
        serializedComponent[name] = value unless value instanceof Function
      serializedComponent['type'] = component.constructor.name
      serializedComponent
    else
      console.log "WTF serializeComponent got undefined component?!", component
      {type:'BROKEN'}


  deserializeComponent: (serializedComponent) ->
    eval("new #{serializedComponent.type}(serializedComponent)")

  #### SimSim.WorldBase#getChecksum()
  getChecksum: ->
    # @checksumCalculator.calculate JSON.stringify(@getData())
    0

module.exports = RtsWorld
