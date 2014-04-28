appRoot = __dirname
port = Number(process.env.PORT || 4050)
secure_socket_io = !!(process.env.SECURE_SOCKET_IO == 1)

logfmt     = require('logfmt')
express    = require('express')
expressApp = express()
httpServer = require('http').createServer(expressApp)
socketIO   = require('socket.io').listen(httpServer, log: false, secure: secure_socket_io)
simSim  = require('sim-sim-js')

logging =
  debug: true
  incomingMessages: true
  outgoingMessages: true
  suppressTurnMessages: true
  # filters: [
  #   (args...) ->
  #     !args[0].match(/::Event/i)
  #     # !JSON.stringify(args).match(/updateControl/)
  # ]

console.log "SimSim logging config:\n",logging

simultSimServer = simSim.create.socketIOServer(
  socketIO: socketIO
  period: 100
  logging: logging
)

# dddincoming message
#
#   incoming
#   outgoing
#  

expressApp.use logfmt.requestLogger()
expressApp.use "/sim_sim", express.static(simSim.clientAssets)
expressApp.use express.static("#{appRoot}/public")

# expressApp.configure 'production', ->
#   expressApp.use forceSsl(req, res, next) ->
#     if req.header 'x-forwarded-proto' != 'https'
#       res.redirect "https://#{req.header 'host'}#{req.url}"
#     else
#       next()

logfmt.log port: port
httpServer.listen port
