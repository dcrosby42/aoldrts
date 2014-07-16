CR =                         require '../../utils/component_register.coffee'
C =                          require '../components.coffee'
E =                          require '../events.coffee'

class EntityInspectorSystem extends makr.IteratingSystem
  constructor: (@entityInspector, @componentClass) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(@componentClass))

  process: (entity, elapsed) ->
    component = entity.get(CR.get(@componentClass))
    @entityInspector.update entity.id, component # should be a COPY of the component?

module.exports = EntityInspectorSystem
