EntityViewBinding = require './utils/entity_view_binding.coffee'

HaloView = require './views/halo_view.coffee'
HealthView = require './views/health_view.coffee'
MapTilesView = require './views/map_tiles_view.coffee'
ActorView = require './views/actor_view.coffee'

UIState = Ember.Object.extend
  init: ->
    @_super()
    # See the "Unconsumed computed properties" section of http://emberjs.com/guides/object-model/observers/
    @get('selectedUnits')
    @get('unitsWithHealth')
    @get('mapTiles')
    @get('actors')

  # Graphics environment, used by EntityViewBinding, set by RtsUi at setup.
  pixiWrapper: null

  # Set by RtsUi when selecting/deselecting units:
  selectedEntityId: null

  # Maintained by Introspector as world state changes:
  entities: []

  ##
  ## UI-related computed properties:
  ## 

  # All currently selected entities:
  selectedUnits: (->
    if selectedEntity = @get('entities').findBy('entityId', @get('selectedEntityId'))
      [
        selectedEntity
      ]
    else
      []
  ).property('entities.[]', 'selectedEntityId')

  # Units on the field that have Health components:
  unitsWithHealth: (->
    @get('entities').map((entity) => entity if entity.get('Health')).compact()
  ).property('entities.[]')

  # The map (entity(ies) with MapTiles components)
  mapTiles: (->
    @get('entities').map((entity) => entity if entity.get('MapTiles')).compact()
  ).property('entities.[]')

  # Robtos, powerup etc (anything with Sprite, Position and Movement)
  actors: (->
    @get('entities').map((entity) =>
      if entity.get('Sprite') and entity.get('Position') and entity.get('Movement')
        entity
    ).compact()
  ).property('entities.[]')

  ##
  ## BIND GRAPHICS TO UI STATE:
  ##

  haloViews: []
  _syncHaloViews: EntityViewBinding.create HaloView,
    from: "selectedUnits"
    to: "haloViews"
    layer: 'ui'

  healthViews: []
  _syncHealthViews: EntityViewBinding.create HealthView,
    from: "unitsWithHealth"
    to: 'healthViews'
    layer: 'ui'

  mapBackgroundViews: []
  _syncMapBackgroundViews: EntityViewBinding.create MapTilesView,
    from: 'mapTiles'
    to: 'mapBackgroundViews'
    layer: 'background'

  actorViews: []
  _syncActorViews: EntityViewBinding.create ActorView,
    from: 'actors'
    to: 'actorViews'
    layer: 'middle' # default 

module.exports = UIState
