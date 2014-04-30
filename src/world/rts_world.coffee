Array::compact = ->
  (elem for elem in this when elem?)

PlayerColors = [ 0x99FF99, 0xFF99FF, 0xFFFF99, 0x9999FF, 0xFF9999, 0x99FFFF ]

ChecksumCalculator = require '../utils/checksum_calculator.coffee'
ParkMillerRNG =      require '../utils/pm_prng.coffee'
ComponentRegister =  require '../utils/component_register.coffee'

CommandQueueSystem =         require './systems/command_queue_system.coffee'
GotoSystem =                 require './systems/goto_system.coffee'
WanderControlMappingSystem = require './systems/wander_control_mapping_system.coffee'

C = require './components.coffee'

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


eachMapTile = (prng, width, height, f) ->
  tile_sets = ["gray", "dark_brown", "dark"]
  features = [[null, 200], ["stone0", 8], ["stone1", 8], ["crater", 2]]
  bases = [["small_crater", 5], ["basic0", 50], ["basic1", 50]]
  tile_set = prng.choose(tile_sets)
  tileSize = 31

  offset_x = (width / 2) * tileSize
  offset_y = (height / 2) * tileSize

  # tile backwards so that bigger features are overlaid right
  for x in [width*tileSize..0] by -tileSize
    for y in [height*tileSize..0] by -tileSize
      base = prng.weighted_choose(bases)
      feature = prng.weighted_choose(features)
      spare_seed = prng.gen()
      f(x - offset_x, y - offset_y, tile_set, base, feature, spare_seed)

class MapTilesSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(C.MapTiles))
    @tilesSprites = undefined

  onRemoved: (entity) ->
    if @tilesSprites?
      @pixiWrapper.sprites.removeChild(@tilesSprites)
      @tilesSprites = undefined
    
  process: (entity, elapsed) ->
    unless @tilesSprites?
      component = entity.get(ComponentRegister.get(C.MapTiles))
      @tilesSprites = @createTiles(component.seed, component.width, component.height)
      @pixiWrapper.addBackgroundSprite(@tilesSprites)

  createTile: (tiles, frame, x, y) ->
    tile = new PIXI.Sprite(PIXI.Texture.fromFrame(frame))
    tile.position.x = x
    tile.position.y = y
    tile

  createTiles: (seed, width, height) ->
    tiles = new PIXI.DisplayObjectContainer()
    tiles.position.x = 0
    tiles.position.y = 0

    prng = new ParkMillerRNG(seed)
    eachMapTile prng, width, height, (x, y, tile_set, base, feature) =>
        frame = tile_set + "_set_" + base
        tiles.addChild(@createTile(tiles, frame, x, y))
        if feature?
          feature_frame = tile_set + "_set_" + feature
          tiles.addChild(@createTile(tiles, feature_frame, x, y))

    tiles.cacheAsBitmap = true
    tiles


class EntityInspectorSystem extends makr.IteratingSystem
  constructor: (@entityInspector, @componentClass) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(@componentClass))

  process: (entity, elapsed) ->
    component = entity.get(ComponentRegister.get(@componentClass))
    @entityInspector.update entity.id, component # should be a COPY of the component?


class ControlSystem extends makr.IteratingSystem
  constructor: (@rtsWorld) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(C.Controls))
    @registerComponent(ComponentRegister.get(C.Owned))

  process: (entity, elapsed) ->
    controls = entity.get(ComponentRegister.get(C.Controls))
    # owner = entity.get(ComponentRegister.get(C.Controls))

    entityControls = @rtsWorld.currentControls[entity.id] || []

    # If there are two events of the same type, only the last one in the list
    # will end up having an effect in the system.
    #
    # TODO: Consider figuring out a way to explicitly cycle these events
    # through the system.
    for [action, value] in entityControls
      controls[action] = value

    @rtsWorld.currentControls[entity.id] = []


class MovementSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(C.Movement))
    @registerComponent(ComponentRegister.get(C.Position))

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(C.Position))
    movement = entity.get(ComponentRegister.get(C.Movement))
    console.log("Y NO Position?", entity) unless position?
    position.x += movement.vx * elapsed
    position.y += movement.vy * elapsed

class SpriteSyncSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper, @playerFinder) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(C.Sprite))
    @registerComponent(ComponentRegister.get(C.Position))
    @registerComponent(ComponentRegister.get(C.Movement))
    @spriteCache = {}
    @spriteFrameCache = {}

  onRemoved: (entity) ->
    @pixiWrapper.sprites.removeChild(@spriteCache[entity.id])
    @spriteCache[entity.id] = undefined

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(C.Position))
    sprite = entity.get(ComponentRegister.get(C.Sprite))
    movement = entity.get(ComponentRegister.get(C.Movement))
    owner = entity.get(ComponentRegister.get(C.Owned))

    pixiSprite = @spriteCache[entity.id]
    unless pixiSprite?
      pixiSprite = @buildSprite(entity, sprite, position, owner)
    else if sprite.remove
      @removeSprite(entity, sprite)
    else
      pixiSprite.position.x = position.x
      pixiSprite.position.y = position.y

    vx = movement.vx
    vy = movement.vy
    sprite.facing = "up" if vy < 0
    sprite.facing = "down" if vy > 0
    if Math.abs(vx) > Math.abs(vy)
      sprite.facing = "left" if vx < 0
      sprite.facing = "right" if vx > 0
    sprite.idle = vx == 0 and vy == 0


    if sprite.framelist
      if sprite.idle
        pixiSprite.textures = @spriteFrameCache[sprite.name]["#{sprite.facing}Idle"]
      else
        pixiSprite.textures = @spriteFrameCache[sprite.name][sprite.facing]
    
  buildSprite: (entity, sprite, position, owner) ->
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
    if owner?
      console.log owner.playerId
      console.log @playerFinder.playerMetadata
      pixiSprite.tint = @playerFinder.playerMetadata[owner.playerId].color
      # foo = Math.random() * 0xFFFFFF #
      # console.log foo
      # pixiSprite.tint = foo
      console.log pixiSprite.tint
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
    robot.add(new C.Position(x: x, y: y), ComponentRegister.get(C.Position))
    robot.add(new C.Sprite(name: robotName, framelist: @generateRobotFrameList(robotName)), ComponentRegister.get(C.Sprite))
    robot.add(new C.Controls(), ComponentRegister.get(C.Controls))
    robot.add(new C.Movement(vx: 0, vy: 0, speed:15), ComponentRegister.get(C.Movement))
    robot.add(new C.Wander(range: 50), ComponentRegister.get(C.Wander))
    robot

  powerup: (x, y, powerup_type) ->
    crystal_frames = ["#{powerup_type}-crystal0", "#{powerup_type}-crystal1", "#{powerup_type}-crystal2", "#{powerup_type}-crystal3", "#{powerup_type}-crystal4", "#{powerup_type}-crystal5", "#{powerup_type}-crystal6", "#{powerup_type}-crystal7"]
    powerup_frames = {
      downIdle: crystal_frames
      down: crystal_frames
    }
    p = @ecs.create()
    p.add(new C.Position(x: x, y: y), ComponentRegister.get(C.Position))
    # movement just added 
    p.add(new C.Movement(vx: 0, vy: 0), ComponentRegister.get(C.Movement))
    p.add(new C.Powerup(powerup_type: powerup_type), ComponentRegister.get(C.Powerup))
    p.add(new C.Sprite(name: "#{powerup_type}-crystal", framelist: powerup_frames), ComponentRegister.get(C.Sprite))
    p

  mapTiles: (seed, width, height) ->
    mapTiles = @ecs.create()
    comp = new C.MapTiles(seed: seed, width: width, height: height)
    mapTiles.add(comp, ComponentRegister.get(C.MapTiles))
    prng = new ParkMillerRNG(seed)
    eachMapTile prng, width, height, (x, y, tile_set, base, feature, spare) =>
      sparePRNG = new ParkMillerRNG(spare)
      if feature == "crater"
        p = sparePRNG.weighted_choose([["blue", 25], ["green", 25], [null, 50]])
        if p?
          @powerup(x + 32, y + 32, p)

    mapTiles

class RtsWorld extends SimSim.WorldBase
  constructor: ({@pixiWrapper, @introspector}) ->
    @pixiWrapper or throw new Error("Need pixiWrapper")
    @introspector or throw new Error("Need an introspector, eg, EntityInspector")

    @playerMetadata = {}
    @currentControls = {}
    @commandQueue = []

    @randomNumberGenerator = new ParkMillerRNG((Math.random() * 1000)|0)
    @checksumCalculator = new ChecksumCalculator()
    @ecs = @_setupECS(@pixieWrapper)
    @entityFactory = new EntityFactory(@ecs)
    @_setupIntrospector(@ecs,@introspector)

    @entityFactory.mapTiles((Math.random() * 1000)|0, 100, 100)

  _setupECS: (pixieWrapper) ->
    ComponentRegister.register(C.Position)
    ComponentRegister.register(C.Sprite)
    ComponentRegister.register(C.Owned)
    ComponentRegister.register(C.Movement)
    ComponentRegister.register(C.Controls)
    ComponentRegister.register(C.MapTiles)
    ComponentRegister.register(C.Powerup)
    ComponentRegister.register(C.Goto)
    ComponentRegister.register(C.Wander)
    ecs = new makr.World()
    ecs.registerSystem(new WanderControlMappingSystem(@randomNumberGenerator))
    ecs.registerSystem(new GotoSystem())
    ecs.registerSystem(new SpriteSyncSystem(@pixiWrapper, @))
    ecs.registerSystem(new MapTilesSystem(@pixiWrapper))
    ecs.registerSystem(new CommandQueueSystem(@commandQueue, @))  # passing "this" as the entityFinder
    ecs.registerSystem(new MovementSystem())
    ecs

  _setupIntrospector: (ecs, introspector) ->
    for componentClass in [ C.Position,C.Movement,C.Owned,C.MapTiles ]
      ecs.registerSystem(new EntityInspectorSystem(introspector, componentClass))

  findEntityById: (id) ->
    (entity for entity in @ecs._alive when "#{entity.id}" == "#{id}")[0]

  resetData: ->

  deserializeComponent: (serializedComponent) ->
    new C[serializedComponent.type](serializedComponent)
    # eval("new C.#{serializedComponent.type}(serializedComponent)")

  #
  # Invocable via proxy:
  #
  summonRobot: (playerId, robotType, args={}) ->
    robot = @entityFactory.robot(args.x, args.y, robotType)
    robot.add(new C.Owned(playerId: playerId), ComponentRegister.get(C.Owned))
    
  commandUnit: (playerId, command, args={}) ->
    @commandQueue.push(
      command: command,
      playerId: playerId
      args: args
    )
    
  #### SimSim.WorldBase#getInspector()
  getIntrospector: -> @introspector

  #### SimSim.WorldBase#playerJoined(id)
  playerJoined: (playerId) ->
    console.log "Player #{playerId} JOINED"
    @playerMetadata[playerId] ||= {}
    @playerMetadata[playerId].color = @randomNumberGenerator.choose(PlayerColors)

  #### SimSim.WorldBase#playerLeft(id)
  playerLeft: (playerId) ->
    console.log "Player #{playerId} LEFT"
    for ent in @ecs._alive
      owner = ent.get(ComponentRegister.get(C.Owned))
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
    @playerMetadata = data.playerMetadata
    @ecs._nextEntityID = data.nextEntityId
    @randomNumberGenerator.seed = data.sacredSeed
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
        # for c in components
        #   componentBags[entId] = @serializeComponent(c) if c?

    data =
      playerMetadata: @playerMetadata
      componentBags: componentBags
      nextEntityId: @ecs._nextEntityID
      sacredSeed: @randomNumberGenerator.seed
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


  #### SimSim.WorldBase#getChecksum()
  getChecksum: ->
    # @checksumCalculator.calculate JSON.stringify(@getData())
    0

module.exports = RtsWorld
