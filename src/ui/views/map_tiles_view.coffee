ParkMillerRNG =              require '../../utils/pm_prng.coffee'
MapHelpers =                 require '../../world/map_helpers.coffee'

MapTilesView = Ember.Object.extend
  entity: null
  sprite: null
  entityIdBinding: 'entity.entityId'
  seedBinding: 'entity.MapTiles.seed'
  widthBinding: 'entity.MapTiles.width'
  heightBinding: 'entity.MapTiles.height'

  init: ->
    @_super()
    @set 'sprite', @createTiles(@get('seed'), @get('width'), @get('height'))

  createTile: (frame, x, y) ->
    tile = new PIXI.Sprite(PIXI.Texture.fromFrame(frame))
    tile.position.x = x
    tile.position.y = y
    tile

  createTiles: (seed, width, height) ->
    tiles = new PIXI.DisplayObjectContainer()
    tiles.position.x = 0
    tiles.position.y = 0

    prng = new ParkMillerRNG(seed)
    MapHelpers.eachMapTile prng, width, height, (x, y, tile_set, base, feature) =>
        frame = tile_set + "_set_" + base
        tiles.addChild(@createTile(frame, x, y))
        if feature?
          feature_frame = tile_set + "_set_" + feature
          tiles.addChild(@createTile(feature_frame, x, y))

    tiles.cacheAsBitmap = true
    tiles

module.exports = MapTilesView
