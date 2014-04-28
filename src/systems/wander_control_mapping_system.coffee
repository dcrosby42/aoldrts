CR = require '../utils/component_register.coffee'
C = require('../components.coffee')
ParkMillerRNG = require '../pm_prng.coffee'

class WanderControlMappingSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Position))
    @registerComponent(CR.get(C.Wander))
    @randy =  new ParkMillerRNG(1234)

  process: (entity, elapsed) ->
    wander = entity.get(CR.get(C.Wander))
    position = entity.get(CR.get(C.Position))
    goto = entity.get(CR.get(C.Goto))
    unless goto?
      range = wander.range
      dx = @randy.nextInt(-range,range)
      dy = @randy.nextInt(-range,range)
      entity.add(new C.Goto(x: position.x + dx, y: position.y + dy), CR.get(C.Goto))
      console.log entity.get(CR.get(C.Goto))

module.exports = WanderControlMappingSystem
