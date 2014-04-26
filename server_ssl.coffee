fs = require('fs')
port = Number(process.env.PORT || 4050)
appRoot = __dirname

logfmt     = require('logfmt')
express    = require('express')
expressApp = express()

keys_dir = 'keys/'
serverOptions =
  key:  fs.readFileSync(keys_dir + 'server.key')
  cert: fs.readFileSync(keys_dir + 'server.crt')

httpsServer = require('https').createServer(serverOptions, expressApp)
socketIO   = require('socket.io').listen(httpsServer, log: true, secure: true)
simSim  = require('sim-sim-js')

simultSimServer = simSim.create.socketIOServer(
  socketIO: socketIO
  period: 100
)

expressApp.use logfmt.requestLogger()
expressApp.use "/sim_sim", express.static(simSim.clientAssets)
expressApp.use express.static("#{appRoot}/public")

logfmt.log port: port
httpsServer.listen port
