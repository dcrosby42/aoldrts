class EntityInspector
  constructor: ->
    @reset()

  reset: ->
    @_data = {}

  update: (entityId, component) ->
    eid = "#{entityId}"
    typeName = component.constructor.name
    @_data[eid] ||= {}
    @_data[eid][typeName] = component

  componentsByEntity: ->
    @_data





module.exports = EntityInspector
