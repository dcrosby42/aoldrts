
RtsWorld = require './world/rts_world.coffee'
RtsUI = require './ui/rts_ui.coffee'

StopWatch = require './utils/stop_watch.coffee'
KeyboardController = require './ui/keyboard_controller.coffee'
PixiWrapper = require './ui/pixi_wrapper.coffee'
GameRunner = require './ui/game_runner.coffee'

ParkMillerRNG = require './utils/pm_prng.coffee'

UIState = require './ui/ui_state.coffee'
Introspector = require './world/introspector.coffee'


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
      "images/crystal-qubodup-ccby3-32-blue.png"
      "images/crystal-qubodup-ccby3-32-green.png"
      "images/crystal-qubodup-ccby3-32-grey.png"
      "images/crystal-qubodup-ccby3-32-orange.png"
      "images/crystal-qubodup-ccby3-32-pink.png"
      "images/crystal-qubodup-ccby3-32-yellow.png"
      ]
    spriteSheetAssets: [
      "images/EBRobotedit2crMatsuoKaito.json",
      "images/terrain.json",
      "images/blue-crystal.json",
      "images/green-crystal.json",
      "images/grey-crystal.json",
      "images/orange-crystal.json",
      "images/pink-crystal.json",
      "images/yellow-crystal.json"
    ]
    simSimConnection:
      url: "#{scheme}://#{window.location.hostname}"#:#{window.location.port}"
      secure: useHttps
  }
  return @_gameConfig
  
window.local =
  vars: {}
  gameRunner: null
  pixiWrapper: null

window.onload = ->
  gameConfig = window.gameConfig()

  stats = setupStats()

  pixiWrapper = buildPixiWrapper(
    width:  gameConfig.stageWidth
    height: gameConfig.stageHeight
    assets: gameConfig.imageAssets
    spriteSheets: gameConfig.spriteSheetAssets
  )

  pixiWrapper.appendViewTo(document.getElementById('gameDiv'))


  pixiWrapper.loadAssets ->
    uiState = UIState.create(
      pixiWrapper:pixiWrapper
    )
    introspector = new Introspector(
      uiState: uiState
    )
    simulation = buildSimulation(
      world: new RtsWorld(
          pixiWrapper:pixiWrapper
          introspector:introspector
        )
      url: gameConfig.simSimConnection.url
      secure: gameConfig.simSimConnection.secure
    )
    keyboardController = buildKeyboardController()
    stopWatch = buildStopWatch()

    rtsUI = new RtsUI(
      simulation: simulation
      pixiWrapper: pixiWrapper
      keyboardController: keyboardController
    )
      
    gameRunner = new GameRunner(
      simulation: simulation
      ui: rtsUI
      window: window
      pixiWrapper: pixiWrapper
      stats: stats
      stopWatch: stopWatch
    )

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
    world: opts.world
    adapter:
      type: 'socket_io'
      options:
        url: opts.url
        secure: opts.secure
    client:
      spyOnOutgoing: (simulation, message) ->
        if !message.type.match(/turn/i) and !(message['data'] and message.data['method'] and message.data.method == "updateControl")
          console.log("<<< Client SEND", message)
      spyOnIncoming: (simulation, message) ->
        if !message.type.match(/turn/i) and !(message['data'] and message.data['method'] and message.data.method == "updateControl")
          console.log(">>> Client RECV", message)

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
  document.getElementById("gameDiv").appendChild(container)
  stats = new Stats()
  container.appendChild(stats.domElement)
  stats.domElement.style.position = "absolute"
  stats

buildPixiWrapper = (opts={})->
  new PixiWrapper(opts)

buildKeyboardController = ->
  actions = {
    g: "goto"
  }
  for n in [0..6]
    actions[n] = "roboType#{n}"

  new KeyboardController(actions)

_copyData = (data) ->
  JSON.parse(JSON.stringify(data))

window.takeSnapshot = ->
  console.log "NO!"
  # d = window.local.gameRunner.simulation.world.getData()
  # ss = _copyData(d)
  # console.log ss
  # window.local.vars.snapshot = ss

window.restoreSnapshot = ->
  console.log "NO!"
  # ss = window.local.vars.snapshot
  # console.log ss
  # window.local.gameRunner.simulation.world.setData _copyData(ss)

window.stop = ->
  window.local.gameRunner.stop()

window.start = ->
  window.local.gameRunner.start()

window.mouseScrollingChanged = ->
  onOff = document.getElementById("mouseScrolling").checked
  window.local.pixiWrapper.setMouseScrollingOn(onOff)

window.watchData = ->
  # insp = window.local.gameRunner.simulation.getWorldIntrospector()
  # pre = document.getElementById("entityInspectorOutput")
  # entityCount = insp.entityCount()

  # txt = "Entity count #{entityCount}:\n"
  # for entityId, components of insp.componentsByEntity()
  #   txt += "Entity #{entityId}:\n"
  #   for compType, comp of components
  #     txt += "  #{compType}:\n"
  #     for k,v of comp
  #       txt += "    #{k}: #{v} (#{typeof v})\n"
  # pre.textContent = txt

  # insp.reset()

  # setTimeout(window.watchData, 500)
  
