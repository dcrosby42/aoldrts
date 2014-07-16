CR =                         require '../../utils/component_register.coffee'
C =                          require '../components.coffee'
E =                          require '../events.coffee'

class MovementSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Movement))
    @registerComponent(CR.get(C.Position))

  process: (entity, elapsed) ->
    position = entity.get(CR.get(C.Position))
    movement = entity.get(CR.get(C.Movement))
    console.log("Y NO Position?", entity) unless position?
    position.x += movement.vx * elapsed
    position.y += movement.vy * elapsed

module.exports = MovementSystem
