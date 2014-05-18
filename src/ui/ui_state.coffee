StatefulBinding = require './stateful_binding.coffee'
HaloView = require './views/halo_view.coffee'
HealthView = require './views/health_view.coffee'
  
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


module.exports = UIState
