ComponentRegister = require('../utils/component_register.coffee')
C = require('../components.coffee')

class CommandQueueSystem extends makr.IteratingSystem
  constructor: (@commandQueue, @entityFinder) ->
    makr.IteratingSystem.call(@)
    
  processEntities: ->
    # Copy and clear the Q:
    commands = []
    while cmd = @commandQueue.shift()
      commands.push(cmd)

    for cmd in commands
      if cmd.args.entityId?
        targetEntity = @entityFinder.findEntityById(cmd.args.entityId)
        owned = targetEntity.get(ComponentRegister.get(C.Owned))
        if owned and (cmd.playerId == owned.playerId)
          if cmd.command == "march"
            movement = targetEntity.get(ComponentRegister.get(C.Movement))
            if cmd.args.direction == "left"
              movement.vx = -10
            else if cmd.args.direction == "right"
              movement.vx = 10
            else if cmd.args.direction == "stop"
              movement.vx = 0
          else
            console.log "CommandQueueSystem: UNKNOWN COMMAND:", cmd
        else
          console.log "CommandQueueSystem: ILLEGAL INSTRUCTION, player #{cmd.playerId} may not command entity #{cmd.args.entityId} because it's owned by #{owned.playerId}"
          
module.exports = CommandQueueSystem
