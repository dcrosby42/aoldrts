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

class Player
  constructor: (@id) ->

class Position
  constructor: (@x, @y) ->

class Movement
  constructor: (@vx, @vy) ->

class Sprite
  constructor: (@name) ->
    @remove = false
    @add = true

class Controls
  constructor: () ->
    @up = false
    @down = false
    @left = false
    @right = false

class ControlSystem extends makr.IteratingSystem
  constructor: (@rtsWorld) ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Controls))

  process: (entity, elapsed) ->
    controls = entity.get(ComponentRegister.get(Controls))
    entityControls = @rtsWorld.currentControls[entity._id]
    for [action, value] in entityControls
      controls[action] = value

    @rtsWorld.currentControls[entity._id] = []


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
    makr.IteratingSystem.call(@);
    @registerComponent(ComponentRegister.get(Sprite))
    @registerComponent(ComponentRegister.get(Position))
    @spriteCache = {}

  process: (entity, elapsed) ->
    position = entity.get(ComponentRegister.get(Position));
    sprite = entity.get(ComponentRegister.get(Sprite));

    if sprite.add
      @buildSprite(entity, sprite, position)
    else if sprite.remove
      @removeSprite(entity, sprite)
    else
      pixiSprite = @spriteCache[entity._id]
      pixiSprite.position.x = position.x
      pixiSprite.position.y = position.y
    
  buildSprite: (entity, sprite, position) ->
    pixiSprite = new PIXI.Sprite(PIXI.Texture.fromFrame(sprite.name))
    pixiSprite.anchor.x = pixiSprite.anchor.y = 0.5
    @pixiWrapper.stage.addChild pixiSprite
    @spriteCache[entity._id] = pixiSprite
    pixiSprite.position.x = position.x
    pixiSprite.position.y = position.y
    sprite.add = false

  removeSprite: (entity, sprite) ->
    @pixiWrapper.stage.removeChild @spriteCache[entity._id]
    delete @spriteCache[entity._id]
    sprite.remove = false


# vec2 = (x,y) -> new Box2D.Common.Math.b2Vec2(x,y)
fixFloat = SimSim.Util.fixFloat
HalfPI = Math.PI/2

class EntityFactory
  constructor: (@ecs) ->

  bunny: (x,y) ->
    bunny = @ecs.create()
    bunny.add(new Position(x,y), ComponentRegister.get(Position))
    bunny.add(new Sprite("images/bunny.png"), ComponentRegister.get(Sprite))
    bunny.add(new Controls(), ComponentRegister.get(Controls))
    bunny.add(new Movement(0,0), ComponentRegister.get(Movement))
    bunny


BUNNY_VEL = 3
class RtsWorld extends SimSim.WorldBase
  constructor: (opts={}) ->
    @checksumCalculator = new ChecksumCalculator()

    @pixiWrapper = opts.pixiWrapper or throw new Error("Need opts.pixiWrapper")
    @ecs = @setupECS(@pixieWrapper)
    @entityFactory = new EntityFactory(@ecs)
    @players = {}
    @currentControls = {}

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

  playerJoined: (playerId) ->
    bunny = @entityFactory.bunny(400,400)
    bunny.add(new Player(playerId), ComponentRegister.get(Player))
    @players[playerId] = bunny
    @currentControls[bunny._id] = []
    console.log "Player #{playerId}, #{bunny._id} JOINED"

  playerLeft: (playerId) ->
    @players[playerId].kill
    delete @players[playerId]
    console.log "Player #{playerId} LEFT"
    
  theEnd: ->
    @resetData()
    console.log "THE END"

  step: (dt) ->
    @ecs.update(dt)
  
  setData: (data) ->
    
  resetData: ->

  getData: ->
    componentBags = {}
    for entId, components of @ecs._componentBags
      componentBags[entId] = (@serializeComponent(c) for c in components)

    data =
      componentBags: componentBags
      nextEntityId: @ecs._nextEntityID

  serializeComponent: (component) ->
    serializedComponent = {}
    for name, value of component
      serializedComponent[name] = value
    serializedComponent['type'] = component.constructor.name
    serializedComponent


  getChecksum: ->
    # @checksumCalculator.calculate JSON.stringify(@getData())
    0

  #
  # Invocable via proxy:
  #
  updateControl: (id, action,value) ->
    @currentControls[@players[id]._id].push([action, value])

module.exports = RtsWorld
