HaloView = require './views/halo_view.coffee'
HealthView = require './views/health_view.coffee'
EntityViewBinding = require './utils/entity_view_binding.coffee'

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

  haloViews: []
  _syncHaloViews: EntityViewBinding.create HaloView,
    from: "selectedUnits"
    to: "haloViews"

  healthViews: []
  _syncHealthViews: EntityViewBinding.create HealthView,
    from: "entitiesWithHealth"
    to: 'healthViews'

module.exports = UIState
