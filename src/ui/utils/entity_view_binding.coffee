
StatefulBinding = require './stateful_binding.coffee'

EntityViewBinding = {}
EntityViewBinding.create = (viewClass, opts) ->
  opts.add = (entity) ->
    view = viewClass.create(entity: entity)

    if layer = opts.layer
      @get('pixiWrapper').addSpriteToLayer layer, view.get('sprite')
    else
      @get('pixiWrapper').addUISprite view.get('sprite')
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
