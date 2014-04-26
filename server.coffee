port = Number(process.env.PORT || 4050)
verbose    = true
appRoot = __dirname

logfmt     = require('logfmt')
express    = require('express')
expressApp = express()
httpServer = require('http').createServer(expressApp)
socketIO   = require('socket.io').listen(httpServer, log: false, secure: false)
simSim  = require('sim-sim-js')

simultSimServer = simSim.create.socketIOServer(
  socketIO: socketIO
  period: 100
)

expressApp.use logfmt.requestLogger()
expressApp.use "/sim_sim", express.static(simSim.clientAssets)
expressApp.use express.static("#{appRoot}/public")

logfmt.log port: port
httpServer.listen port
