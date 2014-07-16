# TODO  @playerFinder.playerMetadata[playerId].color
# TODO  @spriteFromCache
# TODO CLICK entity.id
SpriteFrameCache = require '../utils/sprite_frame_cache.coffee'

ActorView = Ember.Object.extend
  entity: null
  sprite: null
  entityIdBinding: 'entity.entityId'

  xBinding: 'entity.Position.x'
  yBinding: 'entity.Position.y'

  relayClicks: true

  init: ->
    @_super()
    @spriteFrameCache = SpriteFrameCache
    sprite = @_buildSprite(
      @get('entity.Sprite')
      # @get('entity.Owned') # this was really for coloring via playerMetaData
    )

    @set 'sprite', sprite
    @_syncPosition()


  _buildSprite: (spriteComp, ownedComp) ->
    sprite = undefined
    framelist = spriteComp.get('framelist')
    spriteName = spriteComp.get('name')
    spriteFacing = spriteComp.get('facing')
    if framelist
      unless @spriteFrameCache[spriteName]
        frameCache = {}
        for pose, frames of framelist
          frameCache[pose] = (new PIXI.Texture.fromFrame(frame) for frame in frames)
        @spriteFrameCache[spriteName] = frameCache
      sprite = new PIXI.MovieClip(@spriteFrameCache[spriteName][spriteFacing])
      sprite.animationSpeed = 0.0825
      sprite.play()
    else
      sprite = new PIXI.Sprite(PIXI.Texture.fromFrame(spriteName))
    sprite.anchor.x = sprite.anchor.y = 0.5
    
    # TODO - PLAYER COLOR TINT!
    # if ownedComp?
    #   playerId = ownedComp.get('playerId')
    #   if @playerFinder.playerMetadata[playerId]?
    #     sprite.tint = @playerFinder.playerMetadata[playerId].color
    sprite.setInteractive(true)
    sprite
    
  _syncPosition: (->
    if sprite = @get('sprite')
      sprite.position.x = @get('x')
      sprite.position.y = @get('y')
  ).observes('sprite', 'x', 'y')

module.exports = ActorView

# Sprite
#   name
#   framelist
#   facing
#   idle
#   remove
#   add
#
# Position
#   x
#   y
#
# Movement
#   vx
#   vy
#   speed
#
# Owned
#   playerId
