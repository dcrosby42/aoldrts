CR =                         require '../../utils/component_register.coffee'
C =                          require '../components.coffee'
E =                          require '../events.coffee'

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
      if @playerFinder.playerMetadata[owner.playerId]?
        pixiSprite.tint = @playerFinder.playerMetadata[owner.playerId].color
    pixiSprite.setInteractive(true)
    
    @pixiWrapper.addMiddleGroundSprite( pixiSprite, entity.id )

    sprite.add = false
    @spriteCache[entity.id] = pixiSprite

  removeSprite: (entity, sprite) ->
    @pixiWrapper.sprites.removeChild @spriteCache[entity.id]
    delete @spriteCache[entity.id]
    sprite.remove = false

module.exports = SpriteSyncSystem
