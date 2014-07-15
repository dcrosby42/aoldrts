Array::compact = ->
  (elem for elem in this when elem?)

PlayerColors = [ 0x99FF99, 0xFF99FF, 0xFFFF99, 0x9999FF, 0xFF9999, 0x99FFFF ]

ChecksumCalculator = require '../utils/checksum_calculator.coffee'
ParkMillerRNG =      require '../utils/pm_prng.coffee'
CR =  require '../utils/component_register.coffee'
C = require './components.coffee'
EventBus = require './event_bus.coffee'

CommandQueueSystem =         require './systems/command_queue_system.coffee'
GotoSystem =                 require './systems/goto_system.coffee'
WanderControlMappingSystem = require './systems/wander_control_mapping_system.coffee'
HealthSystem =               require './systems/health_system.coffee'
RobotDeathSystem =           require './systems/robot_death_system.coffee'
MapTilesSystem =             require './systems/map_tiles_system.coffee'
EntityFactory =              require './entity_factory.coffee'
require '../utils/makr_extensions.coffee'




class EntityInspectorSystem extends makr.IteratingSystem
  constructor: (@entityInspector, @componentClass) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(@componentClass))

  process: (entity, elapsed) ->
    component = entity.get(CR.get(@componentClass))
    @entityInspector.update entity.id, component # should be a COPY of the component?


class ControlSystem extends makr.IteratingSystem
  constructor: (@rtsWorld) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Controls))
    @registerComponent(CR.get(C.Owned))

  process: (entity, elapsed) ->
    controls = entity.get(CR.get(C.Controls))
    # owner = entity.get(CR.get(C.Controls))

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
    @registerComponent(CR.get(C.Movement))
    @registerComponent(CR.get(C.Position))

  process: (entity, elapsed) ->
    position = entity.get(CR.get(C.Position))
    movement = entity.get(CR.get(C.Movement))
    console.log("Y NO Position?", entity) unless position?
    position.x += movement.vx * elapsed
    position.y += movement.vy * elapsed

class SpriteSyncSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper, @playerFinder) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Sprite))
    @registerComponent(CR.get(C.Position))
    @registerComponent(CR.get(C.Movement))
    @spriteCache = {}
    @spriteFrameCache = {}

  onRemoved: (entity) ->
    @pixiWrapper.sprites.removeChild(@spriteCache[entity.id])
    @spriteCache[entity.id] = undefined

  process: (entity, elapsed) ->
    position = entity.get(CR.get(C.Position))
    sprite = entity.get(CR.get(C.Sprite))
    movement = entity.get(CR.get(C.Movement))
    owner = entity.get(CR.get(C.Owned))

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
      if @playerFinder.playerMetadata[owner.playerId]?
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

class RtsWorld extends SimSim.WorldBase
  constructor: ({@pixiWrapper, @introspector}) ->
    @pixiWrapper or throw new Error("Need pixiWrapper")
    @introspector or throw new Error("Need an introspector, eg, EntityInspector")

    @playerMetadata = {}
    @currentControls = {}
    @commandQueue = []
    @eventBus = new EventBus()

    @randomNumberGenerator = new ParkMillerRNG((Math.random() * 1000)|0)
    @checksumCalculator = new ChecksumCalculator()
    @ecs = new makr.World()
    @entityFactory = new EntityFactory(@ecs)
    @_setupECS(@ecs, @pixieWrapper)
    @_setupIntrospector(@ecs, @introspector)

    @map = @entityFactory.mapTiles((Math.random() * 1000)|0, 100, 100)

  _setupECS: (ecs, pixieWrapper) ->
    CR.register(C.Position)
    CR.register(C.Sprite)
    CR.register(C.Owned)
    CR.register(C.Movement)
    CR.register(C.Controls)
    CR.register(C.MapTiles)
    CR.register(C.Powerup)
    CR.register(C.Goto)
    CR.register(C.Wander)
    CR.register(C.Health)
    ecs.registerSystem(new WanderControlMappingSystem(@randomNumberGenerator))
    ecs.registerSystem(new GotoSystem())
    ecs.registerSystem(new SpriteSyncSystem(@pixiWrapper, @))
    ecs.registerSystem(new MapTilesSystem(@pixiWrapper))
    ecs.registerSystem(new CommandQueueSystem(@commandQueue, @))  # passing "this" as the entityFinder
    ecs.registerSystem(new MovementSystem())
    ecs.registerSystem(new HealthSystem(@eventBus))
    ecs.registerSystem(new RobotDeathSystem(@eventBus, @, @entityFactory))

  _setupIntrospector: (ecs, introspector) ->
    for componentClass in [ C.Position,C.Movement,C.Owned,C.MapTiles, C.Health ]
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
    robot.add(new C.Owned(playerId: playerId), CR.get(C.Owned))
    
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
    mapInfo = @map.get C.MapTiles
    v = @pixiWrapper.viewport

    # 1. choose random initial map location and set player's viewport to see it
    # 2. set a beacon in the center, spawn three bots and get them moving
    
    @playerMetadata[playerId].viewport =
      x: @randomNumberGenerator.nextInt(v.width, mapInfo.width - v.width)
      y: @randomNumberGenerator.nextInt(v.height, mapInfo.height - v.height)

  #### SimSim.WorldBase#playerLeft(id)
  playerLeft: (playerId) ->
    console.log "Player #{playerId} LEFT"
    for ent in @ecs._alive
      owner = ent.get(CR.get(C.Owned))
      ent.kill() if owner? && (owner.playerId == playerId)

  #### SimSim.WorldBase#theEnd()
  theEnd: ->
    @resetData()
    console.log "THE END"

  #### SimSim.WorldBase#step(dtInFractionalSeconds)
  step: (dt) ->
    # @entityInspector.markIn()
    # @resetTimer ||= 0
    # @resetTimer += dt
    # if @resetTimer > 500
      # @entityInspector.reset()
      # @resetTimer = 0
    @introspector.beforeStep()
    @ecs.update(dt)
    @eventBus.clear()
    @introspector.afterStep()
    # if @entityInspector
    #   @entityInspector.markOut()
  
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
        entity.add(comp, CR.get(comp.constructor))

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
