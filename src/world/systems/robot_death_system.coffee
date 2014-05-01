CR = require '../../utils/component_register.coffee'
C = require('../components.coffee')
E = require('../events.coffee')

# class EventIteratingSystem extends makr.IteratingSystem
#   constructor: (@eventBus) ->
# 

class RobotDeathSystem extends makr.IteratingSystem
  constructor: (@eventBus, @entityFinder, @entityFactory) ->
    super(@)

  processEntities: (entities, elapsed) ->
    for eventArgs in @eventBus.eventsFor(E.Death)
      entity = @entityFinder.findEntityById(eventArgs.entityId)
      if entity?
        pos = entity.get(CR.get(C.Position))
        @entityFactory.powerup(pos.x, pos.y, "grey")
      else
        console.log "RobotDeathSystem could not find entity corpse from args [#{eventArgs}]"
      

module.exports = RobotDeathSystem
