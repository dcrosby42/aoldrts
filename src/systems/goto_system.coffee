CR = require '../utils/component_register.coffee'
C = require('../components.coffee')

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

    if Math.abs(dx) < 5 and Math.abs(dy) < 5
      entity.remove(CR.get(C.Goto))
      movement.vx = 0
      movement.vy = 0
      console.log "DONE GOTO!",goto
    else
      if dx > 0
        movement.vx = movement.speed
      else if dx < 0
        movement.vx = -movement.speed

      if dy > 0
        movement.vy = movement.speed
      else if dy < 0
        movement.vy = -movement.speed



module.exports = GotoSystem
