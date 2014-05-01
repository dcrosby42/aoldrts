class EventBus
  constructor: ->
    @clear()

  push: (event_type, args={}) ->
    # store up events until the end of the loop
    @_eventBag[event_type] ||= []
    @_eventBag[event_type].push(args)

  clear: ->
    @_eventBag = {}

  eventsFor: (event_type) ->
    @_eventBag[event_type] || []




module.exports = EventBus
