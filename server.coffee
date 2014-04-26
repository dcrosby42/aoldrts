appRoot = __dirname
port = Number(process.env.PORT || 4050)
secure_socket_io = !!(process.env.SECURE_SOCKET_IO == 1)

logfmt     = require('logfmt')
express    = require('express')
expressApp = express()
httpServer = require('http').createServer(expressApp)
socketIO   = require('socket.io').listen(httpServer, log: true, secure: secure_socket_io)
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
