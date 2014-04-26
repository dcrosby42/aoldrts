ChecksumCalculator = require './checksum_calculator.coffee'

# vec2 = (x,y) -> new Box2D.Common.Math.b2Vec2(x,y)
fixFloat = SimSim.Util.fixFloat
HalfPI = Math.PI/2

class RtsWorld extends SimSim.WorldBase
  constructor: (opts={}) ->
    @checksumCalculator = new ChecksumCalculator()
    @thrust = 0.2
    @turnSpeed = 0.06

    @pixiWrapper = opts.pixiWrapper or throw new Error("Need opts.pixiWrapper")
    @data = @defaultData()
    
    @gameObjects =
      boxes: {}
    # @setupPhysics()
    @syncNeeded = true

  defaultData: ->
    {
      nextId: 0
      players: {}
      boxes: {}
    }

  playerJoined: (id) ->
    boxId = "B#{@nextId()}"
    @data.boxes[boxId] = {
      x: 4.0
      y: 2.0
      angle: 0
      vx: 0.0
      vy: 0.0
    }
    @data.players[id] = { boxId: boxId, controls: {forward:false,left:false,right:false} }
    @syncNeeded = true
    console.log "Player #{id} JOINED, @data is now", @data

  playerLeft: (id) ->
    if boxId = @data.players[id].boxId
      delete @data.boxes[boxId]
    delete @data.players[id]
    @syncNeeded = true
    console.log "Player #{id} LEFT, @data is now", @data
    
  theEnd: ->
    @resetData()
    console.log "THE END"

  step: (dt) ->
    @syncDataToGameObjects()
    @applyControls()

    # Step the physics simulation:
    # @b2world.Step(dt,  3,  3)
    # @b2world.ClearForces()
    
    @moveSprites()
  
  setData: (data) ->
    @resetData()
    @data = data
    @syncNeeded = true
    
  resetData: ->
    @data = @defaultData()
    @syncNeeded = true
    @syncDataToGameObjects()

  getData: ->
    @captureGameObjectsAsData()
    @data

  getChecksum: ->
    @checksumCalculator.calculate JSON.stringify(@getData())

  #
  # Invocable via proxy:
  #

  updateControl: (id, action,value) ->
    @data.players[id].controls[action] = value
    

  #
  # Internal:
  #

  moveSprites: ->
    # for boxId,obj of @gameObjects.boxes
      # body = obj.body
      # sprite = obj.sprite
      # Update sprite locations based on their bodies:
      # position = body.GetPosition()
      # sprite.position.x = position.x * 100
      # sprite.position.y = position.y * 100
      # sprite.rotation = body.GetAngle() + HalfPI

  applyControls: ->
    for id,player of @data.players
      con = player.controls
      # body = @gameObjects.boxes[player.boxId].body
      # if con.forward
      #   r = body.GetAngle()
      #   f = @thrust * body.GetMass()
      #   v = vec2(f*Math.cos(r), f*Math.sin(r))
      #   body.ApplyImpulse(v, body.GetWorldCenter())
      # if con.left
      #   a = body.GetAngle()
      #   body.SetAngle(a - @turnSpeed)
      # if con.right
      #   a = body.GetAngle()
      #   body.SetAngle(a + @turnSpeed)

  nextId: ->
    nid = @data.nextId
    @data.nextId += 1
    nid

  # setupPhysics: ->
    # gravity = vec2(0,0)
    # @b2world = new Box2D.Dynamics.b2World(vec2(0,0), true)

  syncDataToGameObjects: ->
    return unless @syncNeeded
    @syncNeeded=false
    # Boxes:
    for boxId,boxData of @data.boxes
      if !@gameObjects.boxes[boxId]
        try
          # A box exists in @data that is NOT represented in game objects
          obj = {}

          # obj.body = @makeBoxBody(boxData)
          obj.sprite = @makeBoxSprite(boxData)
          @pixiWrapper.stage.addChild obj.sprite
          @gameObjects.boxes[boxId] = obj
        catch e
          console.log "OOPS adding box #{boxId}", e

    for boxId,obj of @gameObjects.boxes
      if !@data.boxes[boxId]
        try
          # A box game object exists for a box that has disappeared from @data
          # @b2world.DestroyBody(obj.body)
          @pixiWrapper.stage.removeChild(obj.sprite)
          delete @gameObjects.boxes[boxId]
        catch e
          console.log "OOPS removing box #{boxId}", e


  captureGameObjectsAsData: ->
    # Boxes:
    for boxId,boxData of @data.boxes
      obj = @gameObjects.boxes[boxId]
      # if obj
        # pos = obj.body.GetPosition()
        # vel = obj.body.GetLinearVelocity()
        # boxData.x = fixFloat(pos.x)
        # boxData.y = fixFloat(pos.y)
        # boxData.angle = fixFloat(obj.body.GetAngle())
        # boxData.vx = fixFloat(vel.x)
        # boxData.vy = fixFloat(vel.y)

        
  # makeBoxBody: (boxData) ->
    # size = 1
    # linearDamping = 3
    # angularDamping = 3

    # polyFixture = new Box2D.Dynamics.b2FixtureDef()
    # polyFixture.shape = new Box2D.Collision.Shapes.b2PolygonShape()
    # polyFixture.density = 1
    # polyFixture.shape.SetAsBox(0.71,0.4)

    # bodyDef = new Box2D.Dynamics.b2BodyDef()
    # bodyDef.type = Box2D.Dynamics.b2Body.b2_dynamicBody
    # bodyDef.position.Set(boxData.x, boxData.y)
    # bodyDef.angle = boxData.angle
    # bodyDef.linearVelocity = vec2(boxData.vx,boxData.vy)
    # bodyDef.awake = true

    # body = @b2world.CreateBody(bodyDef)
    # body.CreateFixture(polyFixture)
    # body.SetLinearDamping(linearDamping)
    # body.SetAngularDamping(angularDamping)

    # body
        
  makeBoxSprite: (boxData) ->
    size = 1
    box = new PIXI.Sprite(PIXI.Texture.fromFrame("images/bunny.png"))
    box.i = 0
    box.anchor.x = box.anchor.y = 0.5
    box.scale.x = size
    box.scale.y = size
    box

module.exports = RtsWorld
