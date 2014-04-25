class PixiWrapper
  constructor: (opts) ->
    @stage = new PIXI.Stage(0xDDDDDD, true)
    @renderer = PIXI.autoDetectRenderer(opts.width, opts.height, undefined, false)
    @loader = new PIXI.AssetLoader(opts.assets)

  appendViewTo: (el) ->
    el.appendChild(@renderer.view)

  loadAssets: (callback) ->
    @loader.onComplete = callback
    @loader.load()

  render: ->
    @renderer.render(@stage)


module.exports = PixiWrapper
