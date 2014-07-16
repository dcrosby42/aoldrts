
StatefulBinding = require './stateful_binding.coffee'

EntityViewBinding = {}
EntityViewBinding.create = (viewClass, opts) ->
  opts.add = (entity) ->
    view = viewClass.create(entity: entity)
    entityId = entity.get('entityId')
    pixiWrapper = @get('pixiWrapper')
    sprite = view.get('sprite')

    if layer = opts.layer
      pixiWrapper.addSpriteToLayer layer, sprite
    else
      pixiWrapper.addUISprite sprite

    if view.get('relayClicks')
      pixiWrapper.relaySpriteClicks(sprite, entityId)

    view

  opts.find = (entity,col) ->
    col.findBy("entityId", entity.entityId)

  opts.remove = (entity,view) ->
    if layer = opts.layer
      @get('pixiWrapper').removeSpriteFromLayer layer, view.get('sprite')
    else
      @get('pixiWrapper').removeUISprite view.get('sprite')

  StatefulBinding.create(opts)

module.exports = EntityViewBinding
