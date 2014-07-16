EntityViewBinding = require './utils/entity_view_binding.coffee'

HaloView = require './views/halo_view.coffee'
HealthView = require './views/health_view.coffee'
MapTilesView = require './views/map_tiles_view.coffee'
ActorView = require './views/actor_view.coffee'

UIState = Ember.Object.extend
  init: ->
    @_super()
    @get('selectedUnits')
    @get('unitsWithHealth')
    @get('mapTiles')
    @get('actors')

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

  unitsWithHealth: (->
    @get('entities').map((entity) => entity if entity.get('Health')).compact()
  ).property('entities.[]')

  mapTiles: (->
    @get('entities').map((entity) => entity if entity.get('MapTiles')).compact()
  ).property('entities.[]')

  actors: (->
    @get('entities').map((entity) =>
      if entity.get('Sprite') and entity.get('Position') and entity.get('Movement')
        entity
    ).compact()
  ).property('entities.[]')

  haloViews: []
  _syncHaloViews: EntityViewBinding.create HaloView,
    from: "selectedUnits"
    to: "haloViews"

  healthViews: []
  _syncHealthViews: EntityViewBinding.create HealthView,
    from: "unitsWithHealth"
    to: 'healthViews'

  mapBackgroundViews: []
  _syncMapBackgroundViews: EntityViewBinding.create MapTilesView,
    from: 'mapTiles'
    to: 'mapBackgroundViews'
    layer: 'background'

  actorViews: []
  _syncActorViews: EntityViewBinding.create ActorView,
    from: 'actors'
    to: 'actorViews'
    layer: 'middle'

module.exports = UIState
