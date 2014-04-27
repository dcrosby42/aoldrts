
class GameRunner
  constructor: ({@window,@simulation,@pixiWrapper,@stats,@stopWatch,@keyboardController}) ->
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

      for action,value of @keyboardController.update()
        if value
          if (action == "myNewRobot")
            @simulation.worldProxy "summonMyRobot", 200, 100
          else if (action == "theirNewRobot")
            @simulation.worldProxy "summonTheirRobot", 400, 400
          else if (action == "marchMyRobot")
            @simulation.worldProxy "marchMyRobot"
          else if (action == "marchTheirRobot")
            @simulation.worldProxy "marchTheirRobot"

      @simulation.update(@stopWatch.elapsedSeconds())
      @pixiWrapper.render()
      @stats.update()

module.exports = GameRunner
