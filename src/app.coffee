
RtsWorld = require './rts_world.coffee'

StopWatch = require './stop_watch.coffee'
KeyboardController = require './keyboard_controller.coffee'
PixiWrapper = require './pixi_wrapper.coffee'
GameRunner = require './game_runner.coffee'

window.gameConfig =
  stageWidth: 800
  stageHeight: 600
  imageAssets: [
    "images/bunny.png"
    ]
  url: "http://#{window.location.hostname}:#{window.location.port}"

window.local =
  vars: {}
  gameRunner: null

window.onload = ->
  stats = setupStats()

  pixiWrapper = buildPixiWrapper(
    width: window.gameConfig.stageWidth
    height: window.gameConfig.stageHeight
    assets: window.gameConfig.imageAssets
  )

  pixiWrapper.appendViewTo(document.body)

  pixiWrapper.loadAssets ->
    world = new RtsWorld(
      pixiWrapper:pixiWrapper
    )

    simulation = buildSimulation(url: window.gameConfig.url, world: world)
    keyboardController = buildKeyboardController()
    stopWatch = buildStopWatch()
    gameRunner = new GameRunner(
      window: window
      simulation: simulation
      pixiWrapper: pixiWrapper
      keyboardController: keyboardController
      stats: stats
      stopWatch: stopWatch
    )

    window.local.gameRunner = gameRunner

    gameRunner.start()

buildStopWatch = ->
  stopWatch = new StopWatch()
  stopWatch.lap()
  stopWatch

buildSimulation = (opts={})->
  simulation = SimSim.createSimulation(
    adapter:
      type: 'socket_io'
      options:
        url: opts.url
    world: opts.world
    # spyOnDataIn: (simulation, data) ->
    #   step = "?"
    #   step = simulation.simState.step if simulation.simState
    #   console.log ">> turn: #{simulation.currentTurnNumber} step: #{simulation.simState.step} data:", data
    # spyOnDataOut: (simulation, data) ->
    #   step = "?"
    #   step = simulation.simState.step if simulation.simState
    #   console.log ">> turn: #{simulation.currentTurnNumber} step: #{simulation.simState.step} data:", data
  )

setupStats = ->
  container = document.createElement("div")
  document.body.appendChild(container)
  stats = new Stats()
  container.appendChild(stats.domElement)
  stats.domElement.style.position = "absolute"
  stats
  
buildPixiWrapper = (opts={})->
  new PixiWrapper(opts)

buildKeyboardController = ->
  new KeyboardController(
    w: "forward"
    a: "left"
    d: "right"
    s: "back"
    up: "forward"
    left: "left"
    right: "right"
    back: "back"
  )



_copyData = (data) ->
  JSON.parse(JSON.stringify(data))

window.takeSnapshot = ->
  d = window.local.gameRunner.simulation.world.getData()
  ss = _copyData(d)
  console.log ss
  window.local.vars.snapshot = ss

window.restoreSnapshot = ->
  ss = window.local.vars.snapshot
  console.log ss
  window.local.gameRunner.simulation.world.setData _copyData(ss)

window.stop = ->
  window.local.gameRunner.stop()

window.start = ->
  window.local.gameRunner.start()
