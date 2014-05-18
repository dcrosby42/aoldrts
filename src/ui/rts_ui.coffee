HealthDisplay = require './health_display.coffee'




class RtsUI
  constructor: ({@pixiWrapper, @keyboardController, @simulation}) ->
    @updateQueue = []
    @introspector = @simulation.getWorldIntrospector()

    @uiState = @introspector.uiState
    # TODO ARGH!!!!  (this should probably be composed in app.coffee or someplace earlier)
    window.ui = @uiState
    @uiState.set 'pixiWrapper', @pixiWrapper
    @uiState.get('selectedUnits') # See the "Unconsumed computed properties" section of http://emberjs.com/guides/object-model/observers/

    @_setupUnitSelection()
    @_setupRobotSpawner()
    @_setupUnitCommand()
    @_setupHealthDisplays()


  update: (dt) ->
    keyEvents = @keyboardController.update()

    while fn = @updateQueue.shift()
      fn(dt)

    @healthDisplay.update()

  _setupHealthDisplays: ->
    @healthDisplay = new HealthDisplay(@pixiWrapper, @introspector)

  _setupUnitSelection: ->
    @pixiWrapper.on "spriteClicked", (data,entityId) =>
      entity = @introspector.getEntity(entityId)
      owned = entity['Owned']
      if owned? and owned.playerId == @simulation.clientId()
        @uiState.set('selectedEntityId', "#{entityId}")


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
      entityId = @uiState.get('selectedEntityId')
      if entityId and @keyboardController.isActive("goto")
        @updateQueue.push =>
          @simulation.worldProxy "commandUnit", "goto", entityId: entityId, x: pt.x, y: pt.y

module.exports = RtsUI

