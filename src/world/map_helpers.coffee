MapHelpers = {
  eachMapTile: (prng, width, height, f) ->
    tile_sets = ["gray", "dark_brown", "dark"]
    features = [[null, 200], ["stone0", 8], ["stone1", 8], ["crater", 2]]
    bases = [["small_crater", 5], ["basic0", 50], ["basic1", 50]]
    tile_set = prng.choose(tile_sets)
    tileSize = 31

    offset_x = (width / 2) * tileSize
    offset_y = (height / 2) * tileSize

    # tile backwards so that bigger features are overlaid right
    for x in [width*tileSize..0] by -tileSize
      for y in [height*tileSize..0] by -tileSize
        base = prng.weighted_choose(bases)
        feature = prng.weighted_choose(features)
        spare_seed = prng.gen()
        f(x - offset_x, y - offset_y, tile_set, base, feature, spare_seed)
}

module.exports = MapHelpers


