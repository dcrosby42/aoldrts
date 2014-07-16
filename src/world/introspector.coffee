
class Introspector
  constructor: ({@uiState}) ->
    @reset()

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


  reset: ->
    @_data = {}

  beforeStep: ->
    @reset()

  afterStep: ->
    entities = @uiState.get('entities')
    watchList = entities.mapBy('entityId')
    for entityId, componentsByType of @_data
      entityId = "#{entityId}"
      watchList.removeObject entityId
      # Find or create an object in the UI to store this Entity's data
      uiEnt = null
      newEntity = null
      unless uiEnt = entities.findBy('entityId',entityId)
        uiEnt = Ember.Object.create(entityId: entityId)
        newEntity = true

      # Update the Entity object with the component data
      for compType, compData of componentsByType
        uiComp = null
        unless uiComp = uiEnt.get(compType)
          uiComp = Ember.Object.create(entityId: entityId)
          uiEnt.set(compType, uiComp)
        uiComp.setProperties compData
        # TODO: remove the UI Components for all components who are NO LONGER PRESENT IN WORLD
      entities.pushObject(uiEnt) if newEntity

    for entityId in watchList
      console.log "Introspector removing entity #{entityId}"
      entities.removeObject entities.findBy('entityId', entityId)


module.exports = Introspector
