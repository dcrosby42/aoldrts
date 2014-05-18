
HaloView = Ember.Object.extend
  unit: null
  sprite: null
  entityIdBinding: 'unit.entityId'
  xBinding: 'unit.Position.x'
  yBinding: 'unit.Position.y'

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
