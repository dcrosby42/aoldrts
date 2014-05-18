
HealthView = Ember.Object.extend
  unit: null
  sprite: null
  entityIdBinding: 'unit.entityId'
  xBinding: 'unit.Position.x'
  yBinding: 'unit.Position.y'

  healthRatio: (->
    if health = @get('unit.Health')
      health.get('health') / health.get('maxHealth')
    else
      0
  ).property('unit.Health', 'unit.Health.health', 'unit.Health.maxHealth')

  init: ->
    @_super()
    sprite = new PIXI.Graphics()
    @set 'sprite', sprite
    @get('healthRatio')

  _syncPosition: (->
    if sprite = @get('sprite')
      sprite.position.x = @get('x')
      sprite.position.y = @get('y')
  ).observes('sprite', 'x', 'y')

  _redraw: (->
    if sprite = @get('sprite')
      healthRatio = @get('healthRatio')
      sprite.clear()
      sprite.beginFill 0x009900
      sprite.lineStyle 1, 0x00FF00
      sprite.drawRect -15,20,(30*healthRatio),6
      sprite.endFill()
  ).observes('sprite', 'healthRatio')


module.exports = HealthView
