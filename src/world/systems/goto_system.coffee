CR = require '../../utils/component_register.coffee'
C = require('../components.coffee')
Vec2D.useObjects()

class GotoSystem extends makr.IteratingSystem
  constructor: () ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Goto))
    @registerComponent(CR.get(C.Position))
    @registerComponent(CR.get(C.Movement))

  process: (entity, elapsed) ->
    goto = entity.get(CR.get(C.Goto))
    position = entity.get(CR.get(C.Position))
    movement = entity.get(CR.get(C.Movement))

    dx = goto.x - position.x
    dy = goto.y - position.y
    target = Vec2D.create(dx,dy)

    magnitude = target.magnitude()
    if magnitude < 5
      entity.remove(CR.get(C.Goto))
      movement.vx = 0
      movement.vy = 0
    else
      velocity = target.unit().multiplyByScalar(movement.speed)
      movement.vx = velocity.getX()
      movement.vy = velocity.getY()

module.exports = GotoSystem
