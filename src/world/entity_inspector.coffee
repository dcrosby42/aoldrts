StatefulBinding = require '../ui/stateful_binding.coffee'

HaloView = Ember.Object.extend
  unit: null
  sprite: null
  entityIdBinding: 'unit.entityId'
  xBinding: 'unit.Position.x'
  yBinding: 'unit.Position.y'

  init: ->
    @_super()
    sprite = new PIXI.Graphics()
    sprite.lineStyle 1, 0x0099FF
    sprite.drawRect -15,-20,30,40
    @set 'sprite', sprite

  _syncPosition: (->
    if sprite = @get('sprite')
      sprite.position.x = @get('x')
      sprite.position.y = @get('y')
  ).observes('sprite', 'x', 'y')

HealthView = Ember.Object.extend
  unit: null
  sprite: null
  entityIdBinding: 'unit.entityId'
  xBinding: 'unit.Position.x'
  yBinding: 'unit.Position.y'

  healthRatio: (->
    if health = @get('unit.Health')
      health.get('health') / health.get('maxHealth')
    else
      0
  ).property('unit.Health', 'unit.Health.health', 'unit.Health.maxHealth')

  init: ->
    @_super()
    sprite = new PIXI.Graphics()
    @set 'sprite', sprite
    @get('healthRatio')

  _syncPosition: (->
    if sprite = @get('sprite')
      sprite.position.x = @get('x')
      sprite.position.y = @get('y')
  ).observes('sprite', 'x', 'y')

  _redraw: (->
    if sprite = @get('sprite')
      healthRatio = @get('healthRatio')
      sprite.clear()
      sprite.beginFill 0x009900
      sprite.lineStyle 1, 0x00FF00
      sprite.drawRect -15,20,(30*healthRatio),6
      sprite.endFill()
  ).observes('sprite', 'healthRatio')
  
UIState = Ember.Object.extend
  init: ->
    @_super()
    @get('selectedUnits')
    @get('entitiesWithHealth')

  pixiWrapper: null

  selectedEntityId: null

  entities: []

  selectedUnits: (->
    if selectedEntity = @get('entities').findBy('entityId', @get('selectedEntityId'))
      [
        selectedEntity
      ]
    else
      []
  ).property('entities.[]', 'selectedEntityId')

  entitiesWithHealth: (->
    @get('entities').map((entity) => entity if entity.get('Health')).compact()
  ).property('entities.[]')

  _ewh: (->
    console.log "entitiesWithHealth CHANGED:",@get('entitiesWithHealth')
  ).observes('entitiesWithHealth.[]')


  haloViews: []
  _syncHaloViews: StatefulBinding.create
    from: "selectedUnits"
    to: "haloViews"
    add: (unit) ->
      haloView = HaloView.create(unit: unit)
      @get('pixiWrapper').addUISprite haloView.get('sprite') # <-- External stateful sideeffect
      haloView
    find: (unit,col) ->
      col.findBy("entityId", unit.entityId)
    remove: (unit, haloView) ->
      @get('pixiWrapper').removeUISprite haloView.get('sprite') # <-- External stateful sideeffect

  healthViews: []
  _syncHealthViews: StatefulBinding.create
    from: "entitiesWithHealth"
    to: 'healthViews'
    add: (unit) ->
      view = HealthView.create(unit: unit)
      @get('pixiWrapper').addUISprite view.get('sprite') # <-- External stateful sideeffect
      view
    find: (unit,col) ->
      col.findBy("entityId", unit.entityId)
    remove: (unit, healthView) ->
      @get('pixiWrapper').removeUISprite healthView.get('sprite') # <-- External stateful sideeffect

class EntityInspector
  constructor: ->
    @reset()
    @uiState = UIState.create() # TODO: UIState requires pixiWrapper to operate.  In this experiment we're letting RtsUI set it later, but this should really be accomplished someplace earlier
    window.ui = @uiState


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
        console.log "Making uiEnt #{entityId}"
        uiEnt = Ember.Object.create(entityId: entityId)
        newEntity = true

      # Update the Entity object with the component data
      for compType, compData of componentsByType
        uiComp = null
        unless uiComp = uiEnt.get(compType)
          uiComp = Ember.Object.create(entityId: entityId)
          uiEnt.set(compType, uiComp)
        uiComp.setProperties compData
        # TODO: remove the UI Components for all components who are NO LONGER PRESENT IN UI WORLD
      entities.pushObject(uiEnt) if newEntity

    for entityId in watchList
      entities.removeObject entities.findBy('entityId', entityId)




module.exports = EntityInspector
