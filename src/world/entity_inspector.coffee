class EntityInspector
  constructor: ->
    @reset()

  reset: ->
    @_data = {}

  update: (entityId, component) ->
    eid = "#{entityId}"
    if component
      typeName = if component.constructor
                 component.constructor.name
               else
                 component.toString()
      @_data[eid] ||= {}
      @_data[eid][typeName] = component

  componentsByEntity: ->
    @_data

  entitiesWithComponent: (component_name) ->
    matches = {}
    for eid, component_hash of @_data
      matches[eid] = component_hash if component_hash[component_name]?
    matches

  getEntity: (entityId) ->
    @_data["#{entityId}"]

  entityCount: ->
    Object.keys(@_data).length




module.exports = EntityInspector
