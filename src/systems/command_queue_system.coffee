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
        @_handleEntityCommand cmd
      else
        @_handleCommand cmd

  _handleCommands: (cmd) ->
    commandFn = Commands[cmd.command]
    if commandFn?
      commandFn(cmd)
    else
      console.log "CommandQueueSystem: No Command defined for #{cmd.command}", cmd

  _handleEntityCommand: (cmd) ->
    targetEntity = @entityFinder.findEntityById(cmd.args.entityId)
    owned = targetEntity.get(ComponentRegister.get(C.Owned))
    if owned and (cmd.playerId == owned.playerId)
      commandFn = Commands.Entity[cmd.command]
      if commandFn?
        commandFn(targetEntity, cmd)
      else
        console.log "CommandQueueSystem: No Entity Command defined for #{cmd.command}", cmd
    else
      console.log "CommandQueueSystem: ILLEGAL INSTRUCTION, player #{cmd.playerId} may not command entity #{cmd.args.entityId} because it's owned by #{owned.playerId}"
          
Commands = {}
Commands.Entity = {}

Commands.Entity.march = (entity, cmd) ->
  movement = entity.get(ComponentRegister.get(C.Movement))
  if cmd.args.direction == "left"
    movement.vx = -movement.speed
  else if cmd.args.direction == "right"
    movement.vx = movement.speed
  else if cmd.args.direction == "stop"
    movement.vx = 0

Commands.Entity.goto = (entity, cmd) ->
  comp = new C.Goto(x: cmd.args.x, y: cmd.args.y)
  entity.add comp, ComponentRegister.get(C.Goto)
  
  


  

module.exports = CommandQueueSystem
