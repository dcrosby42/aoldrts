
makr.IteratingSystem.prototype.processEntities = (entities, elapsed) ->
  sortedEntities = entities.sort (a,b) ->
      return -1 if a.id < b.id
      return 1 if a.id > b.id
      return 0
  for entity in sortedEntities
    @process(entity, elapsed)

makr.World.prototype.resurrect = (entId) ->
  entity = null
  if (@_dead.length > 0)
    entity = @_dead.pop()
    entity._alive = true
    entity._id = entId
    entity._componentMask.reset()
  else
    entity = new makr.Entity(@, +entId)

  @_alive.push(entity)
  entity
