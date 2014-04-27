RtsInterface = require './rts_interface.coffee'
class PixiWrapper
  constructor: (opts) ->
    @stage = new PIXI.Stage(0xDDDDDD, true)
    @renderer = PIXI.autoDetectRenderer(opts.width, opts.height, undefined, false)
    @spriteSheetLoader = new PIXI.SpriteSheetLoader("images/terrain.json")
    @loader = new PIXI.AssetLoader(opts.assets)
    @sprites = new PIXI.DisplayObjectContainer()
    @sprites.setInteractive true
    @stage.addChild @sprites
    @interface = new RtsInterface(sprites: @sprites, renderer: @renderer)

  appendViewTo: (el) ->
    @renderer.view.id = "game"
    el.appendChild(@renderer.view)

    onEnter = =>
      @fullscreen()

    onExit = =>
      @smallscreen()

    document.getElementById("fullscreen").addEventListener "click", (->
      element = document.getElementById("game")
      if BigScreen.enabled
        BigScreen.request element, onEnter, onExit
      else
      return
    ), false

  fullscreen: ->
    @renderer.view.style.width = window.screen.width + "px"
    @renderer.view.style.height = window.screen.height + "px"

  smallscreen: ->
    @renderer.view.style.width = window.screen.width/2 + "px"
    @renderer.view.style.height = window.screen.height/2 + "px"

  loadAssets: (callback) ->
    @loader.onComplete = callback
    @loader.load()
    @spriteSheetLoader.load()

  render: ->
    @interface.update()
    @renderer.render(@stage)

module.exports = PixiWrapper
