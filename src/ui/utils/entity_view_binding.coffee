
StatefulBinding = require './stateful_binding.coffee'

EntityViewBinding = {}
EntityViewBinding.create = (viewClass, opts) ->
  layer = opts.layer || 'middle'

  opts.add = (entity) ->
    view = viewClass.create(entity: entity)
    entityId = entity.get('entityId')
    pixiWrapper = @get('pixiWrapper')
    sprite = view.get('sprite')
    pixiWrapper.addSpriteToLayer layer, sprite
    if view.get('relayClicks')
      pixiWrapper.relaySpriteClicks(sprite, entityId)
    view

  opts.find = (entity,col) ->
    col.findBy("entityId", entity.entityId)

  opts.remove = (entity,view) ->
    @get('pixiWrapper').removeSpriteFromLayer layer, view.get('sprite')

  StatefulBinding.create(opts)

module.exports = EntityViewBinding
