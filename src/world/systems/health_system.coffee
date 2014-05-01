CR = require '../../utils/component_register.coffee'
C = require('../components.coffee')
E = require('../events.coffee')

class HealthSystem extends makr.IteratingSystem
  constructor: (@eventBus) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Health))

  process: (entity, elapsed) ->
    health = entity.get(CR.get(C.Health))
    health.health -= elapsed*10
    if health.health < 0
      entity.kill() 
      @eventBus.push(E.Death, {entityId: entity.id})
      # sprite = entity.get(CR.get(C.Sprite))
      # pos = entity.get(CR.get(C.Position))
      # console.log @world
      # @world.entityFactory.robot(pos.x+10, pos.y, sprite.name)

module.exports = HealthSystem
