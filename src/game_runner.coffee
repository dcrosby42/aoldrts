
class GameRunner
  constructor: ({@window,@simulation,@pixiWrapper,@stats,@stopWatch,@keyboardController,@entityInspector}) ->
    @shouldRun = false
    @worldProxyQueue = []

    @pixiWrapper.on "spriteClicked", (data,entityId) =>
      @worldProxyQueue.push =>
        entity = @entityInspector.getEntity(entityId)
        owned = entity['Owned']
        if owned.playerId == @simulation.clientId()
          movement = entity['Movement']
          if movement.vx > 0
            @simulation.worldProxy "commandUnit", "march", entityId: entityId, direction: "left"
          else if movement.vx < 0
            @simulation.worldProxy "commandUnit", "march", entityId: entityId, direction: "stop"
          else
            @simulation.worldProxy "commandUnit", "march", entityId: entityId, direction: "right"

    @pixiWrapper.on "worldClicked", (data) =>
      pt = data.getLocalPosition(data.target)
      for n in [0..6]
        if @keyboardController.isActive("roboType#{n}")
          @simulation.worldProxy "summonRobot", "robot_#{n}", x: pt.x, y: pt.y



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

      # Accumulated ui actions:
      while action = @worldProxyQueue.shift()
        action()

      @simulation.update(@stopWatch.elapsedSeconds())
      @pixiWrapper.render()
      @stats.update()

module.exports = GameRunner
