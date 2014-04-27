
RtsWorld = require './rts_world.coffee'

StopWatch = require './stop_watch.coffee'
KeyboardController = require './keyboard_controller.coffee'
PixiWrapper = require './pixi_wrapper.coffee'
GameRunner = require './game_runner.coffee'
ParkMillerRNG = require './pm_prng.coffee'

getMeta = (name) ->
  for meta in document.getElementsByTagName('meta')
    if meta.getAttribute("name") == name
      return meta.getAttribute("content")
  return null

window.gameConfig = ->
  return @_gameConfig if @_gameConfig
  useHttps = !!(window.location.protocol.match(/https/))
  scheme = if useHttps then "https" else "http"

  @_gameConfig = {
    stageWidth: window.screen.width / 2
    stageHeight: window.screen.height / 2
    imageAssets: [
      "images/bunny.png"
      ]
    simSimConnection:
      url: "#{scheme}://#{window.location.hostname}"#:#{window.location.port}"
      secure: useHttps
  }
  return @_gameConfig
  

window.local =
  vars: {}
  gameRunner: null

window.onload = ->
  gameConfig = window.gameConfig()

  stats = setupStats()

  pixiWrapper = buildPixiWrapper(
    width:  gameConfig.stageWidth
    height: gameConfig.stageHeight
    assets: gameConfig.imageAssets
  )

  pixiWrapper.appendViewTo(document.body)

  pixiWrapper.loadAssets ->
    world = new RtsWorld(
      pixiWrapper:pixiWrapper
    )

    simulation = buildSimulation(
      world: world
      url: gameConfig.simSimConnection.url
      secure: gameConfig.simSimConnection.secure
    )
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
        secure: opts.secure
    client:
      spyOnOutgoing: (simulation, message) ->
        console.log("<<< Client SEND", message) unless message.type.match(/turn/i)
      spyOnIncoming: (simulation, message) ->
        console.log(">>> Client RECV", message) unless message.type.match(/turn/i)

    # spyOnDataIn: (simulation, data) ->
    #   step = "?"
    #   step = simulation.simState.step if simulation.simState
    #   console.log ">> turn: #{simulation.currentTurnNumber} step: #{simulation.simState.step} data:", data
    # spyOnDataOut: (simulation, data) ->
    #   step = "?"
    #   step = simulation.simState.step if simulation.simState
    #   console.log ">> turn: #{simulation.currentTurnNumber} step: #{simulation.simState.step} data:", data

    world: opts.world
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
    w: "up"
    a: "left"
    d: "right"
    s: "down"
    up: "up"
    left: "left"
    right: "right"
    down: "down"
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
