class PixiWrapper
  constructor: (opts) ->
    @stage = new PIXI.Stage(0xDDDDDD, true)
    @renderer = PIXI.autoDetectRenderer(opts.width, opts.height, undefined, false)
    @spriteSheetLoader = new PIXI.SpriteSheetLoader("images/terrain.json")
    @loader = new PIXI.AssetLoader(opts.assets)

  appendViewTo: (el) ->
    el.appendChild(@renderer.view)

  loadAssets: (callback) ->
    @loader.onComplete = callback
    @loader.load()
    @spriteSheetLoader.load()

  render: ->
    @renderer.render(@stage)


module.exports = PixiWrapper
