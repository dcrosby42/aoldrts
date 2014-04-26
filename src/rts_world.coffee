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

class Wander
  constructor: ({@id}) ->

class Player
  constructor: ({@id}) ->

class Position
  constructor: ({@x, @y}) ->

class Movement
  constructor: ({@vx, @vy}) ->

class Sprite
  constructor: ({@name}) ->
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
    entityControls = @rtsWorld.currentControls[entity._id] || []
    for [action, value] in entityControls
      controls[action] = value

    @rtsWorld.currentControls[entity._id] = []


class ControlMappingSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Movement))
    @registerComponent(ComponentRegister.get(Controls))
    @registerComponent(ComponentRegister.get(Player))

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

class WanderControlMappingSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(ComponentRegister.get(Movement))
    @registerComponent(ComponentRegister.get(Controls))
    @registerComponent(ComponentRegister.get(Wander))

    @timer = 0
    @direction = 0
    @setInterval()

  setInterval: () ->
    @timeInterval = (Math.random() * 10 |0) / 20

  process: (entity, elapsed) ->
    movement = entity.get(ComponentRegister.get(Movement))
    controls = entity.get(ComponentRegister.get(Controls))

    @timer += elapsed
    if @timer > @timeInterval
      @direction = ( Math.random() * 10 ) | 0 % 4
      @timer = 0
      @setInterval()

      movement.vx = 0
      movement.vy = 0
      switch @direction
        when 0
          movement.vy = -BUNNY_VEL
        when 1
          movement.vx = -BUNNY_VEL
        when 2
          movement.vy = BUNNY_VEL
        when 3
          movement.vx = BUNNY_VEL

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

    pixiSprite = @spriteCache[entity._id]
    unless pixiSprite?
      console.log "ADDING SPRITE FOR #{entity._id}"
      @buildSprite(entity, sprite, position)
    else if sprite.remove
      @removeSprite(entity, sprite)
    else
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
    bunny.add(new Position(x: x, y: y), ComponentRegister.get(Position))
    bunny.add(new Sprite(name: "images/bunny.png"), ComponentRegister.get(Sprite))
    bunny.add(new Controls(), ComponentRegister.get(Controls))
    bunny.add(new Movement(vx: 0, vy: 0), ComponentRegister.get(Movement))
    bunny

  autoBunny: (x,y) ->
    autoBunny = @ecs.create()
    autoBunny.add(new Position(x: x, y: y), ComponentRegister.get(Position))
    autoBunny.add(new Sprite(name: "images/bunny.png"), ComponentRegister.get(Sprite))
    autoBunny.add(new Controls(), ComponentRegister.get(Controls))
    autoBunny.add(new Movement(vx: 0, vy: 0), ComponentRegister.get(Movement))
    autoBunny

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
    ComponentRegister.register(Wander)
    ecs = new makr.World()
    ecs.registerSystem(new SpriteSyncSystem(@pixiWrapper))
    ecs.registerSystem(new ControlSystem(this))
    ecs.registerSystem(new MovementSystem())
    ecs.registerSystem(new ControlMappingSystem())
    ecs.registerSystem(new WanderControlMappingSystem())
    ecs

  playerJoined: (playerId) ->
    bunny = @entityFactory.bunny(400,400)
    bunny.add(new Player(id: playerId), ComponentRegister.get(Player))
    @players[playerId] = bunny._id
    console.log "Player #{playerId}, #{bunny._id} JOINED"

    autoBunny = @entityFactory.autoBunny(400, 400)
    autoBunny.add(new Wander(id: "Wander#{playerId}"), ComponentRegister.get(Wander))
    @players["Wander#{playerId}"] = autoBunny._id
    console.log "AutoBunny Wander#{playerId}, #{autoBunny._id} JOINED"


  playerLeft: (playerId) ->
    @ecs._alive.filter((ent) =>
      ent._id == @players[playerId]
    )[0].kill

    delete @players[playerId]
    console.log "Player #{playerId} LEFT"
    
  theEnd: ->
    @resetData()
    console.log "THE END"

  step: (dt) ->
    @ecs.update(dt)
  
  setData: (data) ->
    @players = data.players
    @ecs._nextEntityID = data.nextEntityId
    staleEnts = @ecs._alive.slice(0)
    for ent in staleEnts
      ent.kill

    for entId, components of data.componentBags
      entity = @ecs.resurrect(entId)
      comps = (@deserializeComponent(c) for c in components)
      for comp in comps
        entity.add(comp, ComponentRegister.get(comp.constructor))
    
  resetData: ->

  getData: ->
    componentBags = {}
    for entId, components of @ecs._componentBags
      componentBags[entId] = (@serializeComponent(c) for c in components)

    data =
      players: @players
      componentBags: componentBags
      nextEntityId: @ecs._nextEntityID

  serializeComponent: (component) ->
    serializedComponent = {}
    for name, value of component
      serializedComponent[name] = value
    serializedComponent['type'] = component.constructor.name
    serializedComponent

  deserializeComponent: (serializedComponent) ->
    eval("new #{serializedComponent.type}(serializedComponent)")

  getChecksum: ->
    # @checksumCalculator.calculate JSON.stringify(@getData())
    0

  #
  # Invocable via proxy:
  #
  updateControl: (id, action,value) ->
    @currentControls[@players[id]] ||= []
    @currentControls[@players[id]].push([action, value])

  addPlayer: (playerId) ->

  removePlayer: (playerId) ->

module.exports = RtsWorld
