
StatefulBinding = require './stateful_binding.coffee'

EntityViewBinding = {}
EntityViewBinding.create = (viewClass, opts) ->
  opts.add = (entity) ->
    view = viewClass.create(entity: entity)
    @get('pixiWrapper').addUISprite view.get('sprite')
    view
  opts.find = (entity,col) ->
    col.findBy("entityId", entity.entityId)
  opts.remove = (entity,view) ->
    @get('pixiWrapper').removeUISprite view.get('sprite') # <-- External stateful sideeffect

  StatefulBinding.create(opts)

module.exports = EntityViewBinding
