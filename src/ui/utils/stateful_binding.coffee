StatefulBinding = {}
StatefulBinding.create = ({from,to, find,add,remove}) ->
  (->
    currentItems = @get(from).toArray()
    unless oldItems = @get("_old_#{from}")
      oldItems = []
      @set("_old_#{from}", oldItems)

    StatefulBinding.processDifferences(oldItems, currentItems,
      itemAdded: (item) =>
        res = add.call(@,item)
        @get(to).pushObject res

      itemRemoved: (item) =>
        col = @get(to)
        res = find.call(@, item, col)
        remove.call(@, item, res)
        col.removeObject res
    )
    @set("_old_#{from}", currentItems)
  ).observes("#{from}.[]")

StatefulBinding.processDifferences = (old,current,fns) ->
  if removedFn = fns.itemRemoved
    old.forEach (o) ->
      if current.indexOf(o) == -1
        removedFn(o)

  if addedFn = fns.itemAdded
    current.forEach (o) ->
      if old.indexOf(o) == -1
        addedFn(o)
  
module.exports = StatefulBinding
