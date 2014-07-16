require '../utils/array_extensions.coffee'
require '../utils/makr_extensions.coffee'

PlayerColors = [ 0x99FF99, 0xFF99FF, 0xFFFF99, 0x9999FF, 0xFF9999, 0x99FFFF ]

ChecksumCalculator = require '../utils/checksum_calculator.coffee'
ParkMillerRNG =      require '../utils/pm_prng.coffee'
CR =                 require '../utils/component_register.coffee'
C =                  require './components.coffee'
EventBus =           require './event_bus.coffee'
EntityFactory =      require './entity_factory.coffee'

CommandQueueSystem =         require './systems/command_queue_system.coffee'
GotoSystem =                 require './systems/goto_system.coffee'
WanderControlMappingSystem = require './systems/wander_control_mapping_system.coffee'
HealthSystem =               require './systems/health_system.coffee'
RobotDeathSystem =           require './systems/robot_death_system.coffee'
ControlSystem =              require './systems/control_system.coffee'
MovementSystem =             require './systems/movement_system.coffee'
IntrospectorSystem =         require './systems/introspector_system.coffee'
# SpriteSyncSystem =           require './systems/sprite_sync_system.coffee'

class RtsWorld extends SimSim.WorldBase
  constructor: ({@introspector}) ->
    @introspector or throw new Error("Need an Introspector")

    @playerMetadata = {}
    @currentControls = {}
    @commandQueue = []
    @eventBus = new EventBus()

    @randomNumberGenerator = new ParkMillerRNG((Math.random() * 1000)|0)
    @checksumCalculator = new ChecksumCalculator()
    @ecs = new makr.World()
    @entityFactory = new EntityFactory(@ecs)
    @_setupECS(@ecs)
    @_setupIntrospector(@ecs, @introspector)

    @map = @entityFactory.mapTiles((Math.random() * 1000)|0, 100, 100)

  _setupECS: (ecs) ->
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
    ecs.registerSystem(new CommandQueueSystem(@commandQueue, @))  # passing "this" as the entityFinder
    ecs.registerSystem(new MovementSystem())
    ecs.registerSystem(new HealthSystem(@eventBus))
    ecs.registerSystem(new RobotDeathSystem(@eventBus, @, @entityFactory))

  _setupIntrospector: (ecs, introspector) ->
    for componentClass in [ C.Position,C.Movement,C.Owned,C.MapTiles,C.Health,C.Sprite ]
      ecs.registerSystem(new IntrospectorSystem(introspector, componentClass))

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
    # console.log "setData: @ecs._nextEntityID set to #{@ecs._nextEntityID}"
    staleEnts = @ecs._alive[..]
    for ent in staleEnts
      # console.log "setData: killing entity #{ent.id}", ent
      ent.kill()

    for entId, components of data.componentBags
      entity = @ecs.resurrect(entId)
      # console.log "setData: resurrected entity for entId=#{entId}:", entity
      comps = (@deserializeComponent(c) for c in components)
      entity._componentMask.reset()
      for comp in comps
        # console.log "setData: adding component to #{entity.id}:", comp
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
