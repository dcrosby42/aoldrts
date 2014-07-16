ParkMillerRNG =              require '../../utils/pm_prng.coffee'
MapHelpers =                 require '../../world/map_helpers.coffee'

MapTilesView = Ember.Object.extend
  entity: null
  sprite: null
  entityIdBinding: 'entity.entityId'
  # xBinding: 'entity.Position.x'
  # yBinding: 'entity.Position.y'
  seedBinding: 'entity.MapTiles.seed'
  widthBinding: 'entity.MapTiles.width'
  heightBinding: 'entity.MapTiles.height'

  init: ->
    @_super()
    @set 'sprite', @createTiles(@get('seed'), @get('width'), @get('height'))
    #TODO @pixiWrapper.addBackgroundSprite(tilesSprites)

    # sprite = new PIXI.Graphics()
    # sprite.lineStyle 1, 0x0099FF
    # sprite.drawRect -15,-20,30,40
    # @set 'sprite', sprite

  # _syncPosition: (->
  #   if sprite = @get('sprite')
  #     sprite.position.x = @get('x')
  #     sprite.position.y = @get('y')
  # ).observes('sprite', 'x', 'y')

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
