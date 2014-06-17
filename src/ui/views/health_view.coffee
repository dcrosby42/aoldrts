
HealthView = Ember.Object.extend
  entity: null
  sprite: null
  entityIdBinding: 'entity.entityId'
  xBinding: 'entity.Position.x'
  yBinding: 'entity.Position.y'

  healthRatio: (->
    if health = @get('entity.Health')
      health.get('health') / health.get('maxHealth')
    else
      0
  ).property('entity.Health', 'entity.Health.health', 'entity.Health.maxHealth')

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
      sprite.lineStyle 1, 0x00d000
      sprite.drawRect -15,20,30,6
      sprite.beginFill 0x009900
      sprite.lineStyle 1, 0x00FF00
      sprite.drawRect -15,20,(30*healthRatio),6
      sprite.endFill()
  ).observes('sprite', 'healthRatio')


module.exports = HealthView
