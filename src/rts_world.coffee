Array::compact = ->
  (elem for elem in this when elem?)

ChecksumCalculator = require './checksum_calculator.coffee'

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


class Player
  constructor: ({@id}) ->

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

  createTiles: (seed) ->
    tiles = new PIXI.DisplayObjectContainer()
    tiles.position.x = 0
    tiles.position.y = 0
    tileSize = 31
    for x in [0..3200] by tileSize
      for y in [0..3200] by tileSize
        index = (seed + x*y) % 3
        tile = new PIXI.Sprite(PIXI.Texture.fromFrame("dirt#{index}.png"))
        tile.position.x = x
        tile.position.y = y
        tiles.addChild(tile)
    tiles.cacheAsBitmap = true
    tiles.position.x = -1600
    tiles.position.y = -1600
    tiles


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

  process: (entity, elapsed) ->
    controls = entity.get(ComponentRegister.get(Controls))
    entityControls = @rtsWorld.currentControls[entity.id] || []
    for [action, value] in entityControls
      controls[action] = value

    @rtsWorld.currentControls[entity.id] = []


class ControlMappingSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Movement))
    @registerComponent(ComponentRegister.get(Controls))

  process: (entity, elapsed) ->
    movement = entity.get(ComponentRegister.get(Movement))
    controls = entity.get(ComponentRegister.get(Controls))

    if controls.up
      movement.vy = -BUNNY_VEL
    else if controls.down
      movement.vy = BUNNY_VEL
    else
      movement.vy = 0
    if controls.left
      movement.vx = -BUNNY_VEL
    else if controls.right
      movement.vx = BUNNY_VEL
    else
      movement.vx = 0

class MovementSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Movement))
    @registerComponent(ComponentRegister.get(Position))

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(Position))
    movement = entity.get(ComponentRegister.get(Movement))
    console.log entity unless position?
    position.x += movement.vx
    position.y += movement.vy

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
    console.log "ADDING SPRITE FOR #{entity.id}"
    pixiSprite = undefined
    if sprite.framelist
      unless @spriteFrameCache[sprite.name]
        frameCache = {}
        for pose, frames of sprite.framelist
          frameCache[pose] = (new PIXI.Texture.fromFrame(frame) for frame in frames)
        @spriteFrameCache[sprite.name] = frameCache
      pixiSprite = new PIXI.MovieClip(@spriteFrameCache[sprite.name][sprite.facing])
      pixiSprite.animationSpeed = 0.05
      pixiSprite.play()
    else
      pixiSprite = new PIXI.Sprite(PIXI.Texture.fromFrame(sprite.name))
    pixiSprite.anchor.x = pixiSprite.anchor.y = 0.5
    pixiSprite.position.x = position.x
    pixiSprite.position.y = position.y
    container = @pixiWrapper.sprites
    
    endIndex = container.children.length # ADD ON TOP
    container.addChildAt pixiSprite, endIndex
    console.log "ADDING SPRITE FOR #{entity.id} at child index #{endIndex}"

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
    robot = @ecs.create()
    robot.add(new Position(x: x, y: y), ComponentRegister.get(Position))
    robot.add(new Sprite(name: robotName, framelist: @generateRobotFrameList(robotName)), ComponentRegister.get(Sprite))
    robot.add(new Controls(), ComponentRegister.get(Controls))
    robot.add(new Movement(vx: 0, vy: 0), ComponentRegister.get(Movement))
    robot

  mapTiles: (seed, width, height) ->
    mapTiles = @ecs.create()
    # mapTiles.add(new Position(x: 0, y: 0), ComponentRegister.get(Position))
    comp = new MapTiles(seed: seed, width: width, height: height)
    mapTiles.add(comp, ComponentRegister.get(MapTiles))
    # mapTiles.add(new Position(x: 1, y:2), ComponentRegister.get(Position))
    mapTiles

BUNNY_VEL = 3
class RtsWorld extends SimSim.WorldBase
  constructor: ({@pixiWrapper, @entityInspector}) ->
    @pixiWrapper or throw new Error("Need pixiWrapper")

    @checksumCalculator = new ChecksumCalculator()
    @ecs = @setupECS(@pixieWrapper)
    @entityFactory = new EntityFactory(@ecs)
    @players = {}
    @currentControls = {}
    @setupEntityInspector(@ecs,@entityInspector) if @entityInspector
    @entityFactory.mapTiles((Math.random() * 1000)|0, 50, 50)

  setupECS: (pixieWrapper) ->
    ComponentRegister.register(Position)
    ComponentRegister.register(Sprite)
    ComponentRegister.register(Player)
    ComponentRegister.register(Movement)
    ComponentRegister.register(Controls)
    ComponentRegister.register(MapTiles)
    ecs = new makr.World()
    ecs.registerSystem(new SpriteSyncSystem(@pixiWrapper))
    ecs.registerSystem(new MapTilesSystem(@pixiWrapper))
    ecs.registerSystem(new ControlSystem(this))
    ecs.registerSystem(new MovementSystem())
    ecs.registerSystem(new ControlMappingSystem())
    ecs

  setupEntityInspector: (ecs, entityInspector) ->
    for componentClass in [ Position,Player,MapTiles ]
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
  updateControl: (id, action,value) ->
    @currentControls[@players[id]] ||= []
    @currentControls[@players[id]].push([action, value])

  addPlayer: (playerId) ->

  removePlayer: (playerId) ->
    
  #### SimSim.WorldBase#playerJoined(id)
  playerJoined: (playerId) ->
    robot = @entityFactory.robot(320,224,"robot_0")
    robot.add(new Player(id: playerId), ComponentRegister.get(Player))
    @players[playerId] = robot.id
    console.log "Player #{playerId}, JOINED, entity id #{robot.id}"

  #### SimSim.WorldBase#playerLeft(id)
  playerLeft: (playerId) ->
    ent = @findEntityById(@players[playerId])
    console.log "Player #{playerId} LEFT, killing entity id #{ent.id}"
    ent.kill()
    @players[playerId] = undefined

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
