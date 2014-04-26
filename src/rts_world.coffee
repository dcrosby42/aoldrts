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
  else
    entity = new makr.Entity(@, entId)

  @_alive.push(entity)
  entity


class Player
  constructor: ({@id}) ->

class Position
  constructor: ({@x, @y}) ->

class Movement
  constructor: ({@vx, @vy}) ->

class Sprite
  constructor: ({@name, @framelist}) ->
    @remove = false
    @add = true

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
    position.x += movement.vx
    position.y += movement.vy

class SpriteSyncSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Sprite))
    @registerComponent(ComponentRegister.get(Position))
    @spriteCache = {}

  onRemoved: (entity) ->
    @pixiWrapper.sprites.removeChild @spriteCache[entity.id]
    @spriteCache[entity.id] = undefined

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(Position))
    sprite = entity.get(ComponentRegister.get(Sprite))

    pixiSprite = @spriteCache[entity.id]
    unless pixiSprite?
      @buildSprite(entity, sprite, position)
    else if sprite.remove
      @removeSprite(entity, sprite)
    else
      deltaX = position.x - pixiSprite.position.x
      deltaY = position.y - pixiSprite.position.y

      pixiSprite.position.x = position.x
      pixiSprite.position.y = position.y
    
  buildSprite: (entity, sprite, position) ->
    console.log "ADDING SPRITE FOR #{entity.id}"
    pixiSprite = undefined
    if sprite.framelist
      spriteTextures = (new PIXI.Texture.fromFrame(frame) for frame in sprite.framelist.right)
      pixiSprite = new PIXI.MovieClip(spriteTextures)
      pixiSprite.animationSpeed = 0.05
      pixiSprite.play()
    else
      pixiSprite = new PIXI.Sprite(PIXI.Texture.fromFrame(sprite.name))
    pixiSprite.anchor.x = pixiSprite.anchor.y = 0.5
    @pixiWrapper.sprites.addChild pixiSprite
    @spriteCache[entity.id] = pixiSprite
    pixiSprite.position.x = position.x
    pixiSprite.position.y = position.y
    sprite.add = false

  removeSprite: (entity, sprite) ->
    @pixiWrapper.sprites.removeChild @spriteCache[entity.id]
    delete @spriteCache[entity.id]
    sprite.remove = false

# vec2 = (x,y) -> new Box2D.Common.Math.b2Vec2(x,y)
fixFloat = SimSim.Util.fixFloat
HalfPI = Math.PI/2

Robot0Framelist = {
  down: ["robot0_down_0.png","robot0_down_1.png","robot0_down_2.png", "robot0_down_1.png"]
  left: ["robot0_left_0.png","robot0_left_1.png","robot0_left_2.png", "robot0_left_1.png"]
  up: ["robot0_up_0.png","robot0_up_1.png","robot0_up_2.png", "robot0_up_1.png"]
  right: ["robot0_right_0.png","robot0_right_1.png","robot0_right_2.png", "robot0_right_1.png"]
}

class EntityFactory
  constructor: (@ecs) ->

  bunny: (x,y) ->
    bunny = @ecs.create()
    bunny.add(new Position(x: x, y: y), ComponentRegister.get(Position))
    bunny.add(new Sprite(framelist: Robot0Framelist), ComponentRegister.get(Sprite))
    bunny.add(new Controls(), ComponentRegister.get(Controls))
    bunny.add(new Movement(vx: 0, vy: 0), ComponentRegister.get(Movement))
    bunny


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

  setupECS: (pixieWrapper) ->
    ComponentRegister.register(Position)
    ComponentRegister.register(Sprite)
    ComponentRegister.register(Player)
    ComponentRegister.register(Movement)
    ComponentRegister.register(Controls)
    ecs = new makr.World()
    ecs.registerSystem(new SpriteSyncSystem(@pixiWrapper))
    ecs.registerSystem(new ControlSystem(this))
    ecs.registerSystem(new MovementSystem())
    ecs.registerSystem(new ControlMappingSystem())

    ecs

  setupEntityInspector: (ecs, entityInspector) ->
    for componentClass in [ Position,Player,Movement ]
      ecs.registerSystem(new EntityInspectorSystem(entityInspector, componentClass))
    entityInspector

  findEntityById: (id) ->
    (entity for entity in @ecs._alive when "#{entity.id}" == "#{id}")[0]

  resetData: ->

  serializeComponent: (component) ->
    serializedComponent = {}
    for name, value of component
      serializedComponent[name] = value
    serializedComponent['type'] = component.constructor.name
    serializedComponent

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
    bunny = @entityFactory.bunny(400,400)
    bunny.add(new Player(id: playerId), ComponentRegister.get(Player))
    @players[playerId] = bunny.id
    console.log "Player #{playerId}, #{bunny.id} JOINED"

  #### SimSim.WorldBase#playerLeft(id)
  playerLeft: (playerId) ->
    ent = @findEntityById(@players[playerId])
    console.log "KILLING: #{ent.id}"
    ent.kill()

    @players[playerId] = undefined
    console.log "Player #{playerId} LEFT"

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
    staleEnts = @ecs._alive.slice(0)
    for ent in staleEnts
      console.log "setData: killing entity #{ent.id}"
      ent.kill()

    for entId, components of data.componentBags
      entity = @ecs.resurrect(entId)
      console.log "setData: resurrected entity for entId=#{entId}:", entity
      comps = (@deserializeComponent(c) for c in components)
      for comp in comps
        console.log "setData: adding component to #{entity.id}:", comp
        entity.add(comp, ComponentRegister.get(comp.constructor))

  #### SimSim.WorldBase#getData()
  getData: ->
    componentBags = {}
    for entId, components of @ecs._componentBags
      ent = @findEntityById(entId)
      if ent? and ent.alive
        componentBags[entId] = (@serializeComponent(c) for c in components)

    data =
      players: @players
      componentBags: componentBags
      nextEntityId: @ecs._nextEntityID

  #### SimSim.WorldBase#getChecksum()
  getChecksum: ->
    # @checksumCalculator.calculate JSON.stringify(@getData())
    0

module.exports = RtsWorld
