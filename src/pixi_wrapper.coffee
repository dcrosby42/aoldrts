Viewport = require './viewport.coffee'
class PixiWrapper extends SimSim.EventEmitter
  constructor: (opts) ->
    @stage = new PIXI.Stage(0xDDDDDD, true)
    @renderer = PIXI.autoDetectRenderer(opts.width, opts.height, undefined, false)
    @loader = new PIXI.AssetLoader(opts.assets)
    @spriteSheetLoaders = (new PIXI.SpriteSheetLoader(sheet) for sheet in opts.spriteSheets)
    @sprites = new PIXI.DisplayObjectContainer()
    @sprites.setInteractive true
    @stage.addChild @sprites
    @viewport = new Viewport
      sprites: @sprites
      width: @renderer.width
      height: @renderer.height

    # @stage.mousedown = (data) ->
    #   console.log "Stage mouse down!", data, data.getLocalPosition(data.target)


  addMiddleGroundSprite: (sprite, entityId) ->
    endIndex = @sprites.children.length # ADD ON TOP
    @sprites.addChildAt sprite, endIndex
    sprite.mousedown = (data) =>
      @emit "spriteClicked", data, entityId

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

  setMouseScrollingOn: (onOff) ->
    @viewport.setMouseScrollingOn(onOff)
    
  fullscreen: ->
    @renderer.view.style.width = window.screen.width + "px"
    @renderer.view.style.height = window.screen.height + "px"

  smallscreen: ->
    @renderer.view.style.width = window.screen.width/2 + "px"
    @renderer.view.style.height = window.screen.height/2 + "px"

  loadAssets: (callback) ->
    @loader.onComplete = callback
    @loader.load()
    sheet.load() for sheet in @spriteSheetLoaders
    null

  render: ->
    @viewport.update()
    @renderer.render(@stage)

module.exports = PixiWrapper
