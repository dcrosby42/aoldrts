
class GameRunner
  constructor: ({@window,@simulation,@pixiWrapper,@stats,@stopWatch, @ui}) ->
    @shouldRun = false

  start: ->
    @simulation.start()
    @shouldRun = true
    @update()

  stop: ->
    @shouldRun = false
    @simulation.stop()

  update: ->
    if @shouldRun
      @window.requestAnimationFrame => @update()

      @ui.update(0.17) # TODO Use StopWatch to get this right.

      @simulation.update(@stopWatch.elapsedSeconds()) 
      @pixiWrapper.render()
      @stats.update()

module.exports = GameRunner
