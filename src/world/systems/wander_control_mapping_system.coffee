CR = require '../../utils/component_register.coffee'
C = require('../components.coffee')
ParkMillerRNG = require '../../utils/pm_prng.coffee'

class WanderControlMappingSystem extends makr.IteratingSystem
  constructor: (@randomNumberGenerator) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Position))
    @registerComponent(CR.get(C.Wander))

  process: (entity, elapsed) ->
    wander = entity.get(CR.get(C.Wander))
    position = entity.get(CR.get(C.Position))
    goto = entity.get(CR.get(C.Goto))
    unless goto?
      range = wander.range
      dx = @randomNumberGenerator.nextInt(-range,range)
      dy = @randomNumberGenerator.nextInt(-range,range)
      entity.add(new C.Goto(x: position.x + dx, y: position.y + dy), CR.get(C.Goto))

module.exports = WanderControlMappingSystem
