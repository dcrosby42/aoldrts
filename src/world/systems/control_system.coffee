CR =                         require '../../utils/component_register.coffee'
C =                          require '../components.coffee'
E =                          require '../events.coffee'

class ControlSystem extends makr.IteratingSystem
  constructor: (@rtsWorld) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.Controls))
    @registerComponent(CR.get(C.Owned))

  process: (entity, elapsed) ->
    controls = entity.get(CR.get(C.Controls))
    # owner = entity.get(CR.get(C.Controls))

    entityControls = @rtsWorld.currentControls[entity.id] || []

    # If there are two events of the same type, only the last one in the list
    # will end up having an effect in the system.
    #
    # TODO: Consider figuring out a way to explicitly cycle these events
    # through the system.
    for [action, value] in entityControls
      controls[action] = value

    @rtsWorld.currentControls[entity.id] = []

module.exports = ControlSystem
