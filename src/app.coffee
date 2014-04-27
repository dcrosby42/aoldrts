
RtsWorld = require './rts_world.coffee'

StopWatch = require './stop_watch.coffee'
KeyboardController = require './keyboard_controller.coffee'
PixiWrapper = require './pixi_wrapper.coffee'
GameRunner = require './game_runner.coffee'

ParkMillerRNG = require './pm_prng.coffee'

EntityInspector = require './entity_inspector.coffee'

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
      "images/bunny.png",
      "images/EBRobotedit2crMatsuoKaito.png",
      "images/bunny.png",
      "images/logo.png",
      "images/terrain.png",
      ]
    simSimConnection:
      url: "#{scheme}://#{window.location.hostname}"#:#{window.location.port}"
      secure: useHttps
  }
  return @_gameConfig
  
window.local =
  vars: {}
  gameRunner: null
  entityInspector: null

window.onload = ->
  gameConfig = window.gameConfig()

  stats = setupStats()

  pixiWrapper = buildPixiWrapper(
    width:  gameConfig.stageWidth
    height: gameConfig.stageHeight
    assets: gameConfig.imageAssets
  )

  pixiWrapper.appendViewTo(document.getElementById('gameDiv'))


  pixiWrapper.loadAssets ->
    entityInspector = new EntityInspector()

    world = new RtsWorld(
      pixiWrapper:pixiWrapper
      entityInspector: entityInspector
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

    window.local.entityInspector = entityInspector
    window.local.gameRunner = gameRunner
    window.local.pixiWrapper = pixiWrapper

    gameRunner.start()
    window.watchData()
    window.mouseScrollingChanged()

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
  document.getElementById("gameDiv").appendChild(container)
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

window.mouseScrollingChanged = ->
  onOff = document.getElementById("mouseScrolling").checked
  window.local.pixiWrapper.setMouseScrollingOn(onOff)

window.watchData = ->
  insp = window.local.entityInspector
  pre = document.getElementById("entityInspectorOutput")

  txt = ""
  for entityId, components of insp.componentsByEntity()
    txt += "Entity #{entityId}:\n"
    for compType, comp of components
      txt += "  #{compType}:\n"
      for k,v of comp
        txt += "    #{k}: #{v} (#{typeof v})\n"

  pre.textContent = txt

  setTimeout(window.watchData, 500)
  
