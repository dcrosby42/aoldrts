MapHelpers =                 require '../map_helpers.coffee'
ParkMillerRNG =              require '../../utils/pm_prng.coffee'
CR =                         require '../../utils/component_register.coffee'
C =                          require '../components.coffee'
E =                          require '../events.coffee'

class MapTilesSystem extends makr.IteratingSystem
  constructor: (@pixiWrapper) ->
    makr.IteratingSystem.call(@)
    @registerComponent(CR.get(C.MapTiles))
    @tilesSprites = undefined

  onRemoved: (entity) ->
    if @tilesSprites?
      @pixiWrapper.sprites.removeChild(@tilesSprites)
      @tilesSprites = undefined
    
  process: (entity, elapsed) ->
    unless @tilesSprites?
      component = entity.get(CR.get(C.MapTiles))
      @tilesSprites = @createTiles(component.seed, component.width, component.height)
      @pixiWrapper.addBackgroundSprite(@tilesSprites)

  createTile: (tiles, frame, x, y) ->
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
        tiles.addChild(@createTile(tiles, frame, x, y))
        if feature?
          feature_frame = tile_set + "_set_" + feature
          tiles.addChild(@createTile(tiles, feature_frame, x, y))

    tiles.cacheAsBitmap = true
    tiles

module.exports = MapTilesSystem
