class RtsUI
  constructor: ({@pixiWrapper, @keyboardController, @simulation}) ->
    @updateQueue = []
    @introspector = @simulation.getWorldIntrospector()

    @_setupUnitSelection()
    @_setupRobotSpawner()
    @_setupUnitCommand()

  update: (dt) ->
    keyEvents = @keyboardController.update()

    while fn = @updateQueue.shift()
      fn(dt)

    # for action,value of keyEvents
    #   if value
    #     if (action == "myNewRobot")
    #       @simulation.worldProxy "summonMyRobot", 200, 100

  _setupUnitSelection: ->
    @selectedEntityId = null
    @pixiWrapper.on "spriteClicked", (data,entityId) =>
      entity = @introspector.getEntity(entityId)
      owned = entity['Owned']
      if owned? and owned.playerId == @simulation.clientId()
        @selectedEntityId = entityId

  _setupRobotSpawner: ->
    @pixiWrapper.on "worldClicked", (data) =>
      pt = data.getLocalPosition(data.target)
      robos = []
      for x in [1..5]
        if @keyboardController.isActive("roboType#{x}")
          robos.push "robot_#{x}"
      if robos.length > 0
        @updateQueue.push =>
          for robotType in robos
            @simulation.worldProxy "summonRobot", robotType, x: pt.x, y: pt.y

  _setupUnitCommand: ->
    @pixiWrapper.on "worldClicked", (data) =>
      pt = data.getLocalPosition(data.target)
      if @selectedEntityId and @keyboardController.isActive("goto")
        @updateQueue.push =>
          @simulation.worldProxy "commandUnit", "goto", entityId: @selectedEntityId, x: pt.x, y: pt.y
          @selectedEntityId = null

module.exports = RtsUI

