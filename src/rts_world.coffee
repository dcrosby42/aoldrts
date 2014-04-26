ChecksumCalculator = require './checksum_calculator.coffee'

# vec2 = (x,y) -> new Box2D.Common.Math.b2Vec2(x,y)
fixFloat = SimSim.Util.fixFloat
HalfPI = Math.PI/2

BUNNY_VEL = 3
class RtsWorld extends SimSim.WorldBase
  constructor: (opts={}) ->
    @checksumCalculator = new ChecksumCalculator()

    @pixiWrapper = opts.pixiWrapper or throw new Error("Need opts.pixiWrapper")
    @data = @defaultData()

    @gameObjects =
      bunnies: {}

    @syncNeeded = true

  defaultData: ->
    {
      nextId: 0
      players: {}
      bunnies: {}
    }

  playerJoined: (playerId) ->
    bunnyId = "Bunny#{@nextId()}"
    @data.bunnies[bunnyId] = {
      x: 400
      y: 200
      vx: 0
      vy: 0
    }
    @data.players[playerId] = { bunnyId: bunnyId, controls: {up:false,down:false,left:false,right:false} }
    @syncNeeded = true
    console.log "Player #{playerId} JOINED, @data is now", @data

  playerLeft: (playerId) ->
    if bunnyId = @data.players[playerId].bunnyId
      delete @data.bunnies[bunnyId]
    delete @data.players[playerId]
    @syncNeeded = true
    console.log "Player #{playerId} LEFT, @data is now", @data

  theEnd: ->
    @resetData()
    console.log "THE END"

  step: (dt) ->
    @syncDataToGameObjects()
    @applyControls()
    @moveBunnies()
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

  moveBunnies: ->
    for bunnyId,bunny of @data.bunnies
      bunny.x += bunny.vx
      bunny.y += bunny.vy
      # console.log bunny

  moveSprites: ->
    for bunnyId,obj of @gameObjects.bunnies
      bunny = @data.bunnies[bunnyId]
      obj.sprite.position.x = bunny.x
      obj.sprite.position.y = bunny.y

  applyControls: ->
    for playerId,player of @data.players
      con = player.controls
      bunny = @data.bunnies[player.bunnyId]
      # body = @gameObjects.boxes[player.boxId].body
      if con.up
        bunny.vy = -BUNNY_VEL
      else if con.down
        bunny.vy = BUNNY_VEL
        new Howl({urls: ['sounds/affirm.ogg']}).play() #silly example
      else
        bunny.vy = 0
      if con.left
        bunny.vx = -BUNNY_VEL
      else if con.right
        bunny.vx = BUNNY_VEL
      else
        bunny.vx = 0

  nextId: ->
    nid = @data.nextId
    @data.nextId += 1
    nid

  syncDataToGameObjects: ->
    return unless @syncNeeded
    @syncNeeded=false
    # Boxes:
    for bunnyId,bunnyData of @data.bunnies
      if !@gameObjects.bunnies[bunnyId]
        try
          # A bunny exists in @data that is NOT represented in game objects
          obj = {}

          # obj.body = @makeBoxBody(boxData)
          obj.sprite = @makeBoxSprite(bunnyData)
          @pixiWrapper.stage.addChild obj.sprite
          @gameObjects.bunnies[bunnyId] = obj
        catch e
          console.log "OOPS adding box #{bunnyId}", e

    for bunnyId,obj of @gameObjects.bunnies
      if !@data.bunnies[bunnyId]
        try
          # A bunny game object exists for a box that has disappeared from @data
          @pixiWrapper.stage.removeChild(obj.sprite)
          delete @gameObjects.bunnies[bunnyId]
        catch e
          console.log "OOPS removing box #{bunnyId}", e

  makeBoxSprite: (boxData) ->
    size = 1
    box = new PIXI.Sprite(PIXI.Texture.fromFrame("images/bunny.png"))
    box.i = 0
    box.anchor.x = box.anchor.y = 0.5
    box.scale.x = size
    box.scale.y = size
    box

module.exports = RtsWorld
