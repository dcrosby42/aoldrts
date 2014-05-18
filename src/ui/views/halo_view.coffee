
HaloView = Ember.Object.extend
  entity: null
  sprite: null
  entityIdBinding: 'entity.entityId'
  xBinding: 'entity.Position.x'
  yBinding: 'entity.Position.y'

  init: ->
    @_super()
    sprite = new PIXI.Graphics()
    sprite.lineStyle 1, 0x0099FF
    sprite.drawRect -15,-20,30,40
    @set 'sprite', sprite

  _syncPosition: (->
    if sprite = @get('sprite')
      sprite.position.x = @get('x')
      sprite.position.y = @get('y')
  ).observes('sprite', 'x', 'y')

module.exports = HaloView
