
class StopWatch
  constructor: ->
    @start = @currentTimeMillis()
    @millis = @start

  lap: ->
    newMillis = @currentTimeMillis()
    @lapMillis = newMillis - @millis
    @millis = newMillis
    @lapSeconds()

  currentTimeMillis: ->
    new Date().getTime()

  lapSeconds: ->
    @lapMillis / 1000.0

  elapsedSeconds: ->
    (@currentTimeMillis() - @start)/1000.0


module.exports = StopWatch
