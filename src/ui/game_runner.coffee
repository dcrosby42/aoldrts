
class GameRunner
  constructor: ({@window,@simulation,@pixiWrapper,@stats,@stopWatch, @ui}) ->
    @shouldRun = false

  start: ->
    @simulation.start()
    @shouldRun = true
    @updateFn = @window.setInterval =>
      @update()
    , 16

  stop: ->
    @shouldRun = false
    @simulation.stop()

  update: ->
    if @shouldRun
      # see http://stackoverflow.com/a/16033979/671533
      # @window.requestAnimationFrame => @update()

      @previousElapsedSeconds ||= @stopWatch.elapsedSeconds()
      currentElapsedSeconds = @stopWatch.elapsedSeconds()
      deltaSeconds =  currentElapsedSeconds - @previousElapsedSeconds
      @previousElapsedSeconds = currentElapsedSeconds

      if deltaSeconds > 5
        msg = "Activity Timeout: Did you tab away? Now we refresh!"
        console.log msg
        @stop()
        @window.alert(msg)
        @window.location.reload()
      @ui.update(deltaSeconds)

      @simulation.update(currentElapsedSeconds)
      @pixiWrapper.render()
      @stats.update()
    else
      clearInterval(@updateFn)

module.exports = GameRunner
