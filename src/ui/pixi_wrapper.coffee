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

    @bgSprites = new PIXI.DisplayObjectContainer()
    @bgSprites.setInteractive true
    @stage.addChildAt @bgSprites, 0

    @uiSprites = new PIXI.DisplayObjectContainer()
    @uiSprites.setInteractive true
    @stage.addChild @uiSprites

    @layers =
      background: @bgSprites
      middle:     @sprites
      ui:         @uiSprites

    # TODO can this use a DisplayObjectContainer to contain the sprite groups?
    @viewport = new Viewport
      spriteGroups: [@sprites, @bgSprites, @uiSprites]
      width: @renderer.width
      height: @renderer.height

    @stage.mousedown = (data) => @emit "stageClicked", data
    @bgSprites.mousedown = (data) => @emit "worldClicked", data
    @sprites.mousedown = (data) => @emit "worldClicked", data

    # MINIMAP
    # minimapWidth = opts.width
    # minimapHeight = opts.height
    # @minimapRenderer = new PIXI.RenderTexture(opts.width, opts.height)
    # @minimapRenderer.render @sprites # your main world / display object
    # map = new PIXI.Sprite(@minimapRenderer)
    # map.position.x = 0
    # map.position.y = 0
    # map.scale.x = 0.2
    # map.scale.y = 0.2
    # @stage.addChild map

  relaySpriteClicks: (sprite,entityId) ->
    sprite.mousedown = (data) =>
      @emit "spriteClicked", data, entityId

  addSpriteToLayer: (layerId, sprite) ->
    if layer = @layers[layerId]
      layer.addChildAt sprite, layer.children.length # new sprites are topmost in their layer
    else
      console.log "!! FAIL to add to non-existant sprite layer '#{layerId}'",sprite

  removeSpriteFromLayer: (layerId, sprite) ->
    if layer = @layers[layerId]
      layer.removeChild sprite
    else
      console.log "!! FAIL to remove from non-existant sprite layer '#{layerId}'",sprite
    
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
    feet_y = (sprite) ->
      sprite.y + sprite.height/2
    @sprites.children.sort (a,b) ->
      return -1 if(feet_y(a) < feet_y(b))
      return 1 if (feet_y(a) > feet_y(b))
      return 0

    @viewport.update()
    @renderer.render(@stage)
    # @minimapRenderer.render @sprites

module.exports = PixiWrapper
