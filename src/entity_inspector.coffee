class EntityInspector
  constructor: ->
    @reset()

  reset: ->
    @_data = {}

  update: (entityId, component) ->
    eid = "#{entityId}"
    typeName = if component
                 if component.constructor
                   component.constructor.name
                 else
                   component.toString()
               else
                 "(!undefined component!)"
    @_data[eid] ||= {}
    @_data[eid][typeName] = component

  componentsByEntity: ->
    @_data

  getEntity: (entityId) ->
    @_data["#{entityId}"]

  entityCount: ->
    Object.keys(@_data).length




module.exports = EntityInspector
