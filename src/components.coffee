C = {}
module.exports = C

C.Owned = class Owned
  constructor: ({@playerId}) ->

C.Position = class Position
  constructor: ({@x, @y}) ->

C.Movement = class Movement
  constructor: ({@vx, @vy, @speed}) ->
    @speed ||= 0

C.MapTiles = class MapTiles
  constructor: ({@seed, @width, @height}) ->

C.Powerup = class Powerup
  constructor: ({@powerup_type}) ->

C.Sprite = class Sprite
  constructor: ({@name, @framelist, @facing}) ->
    @remove = false
    @add = true
    @facing ||= "down"
    @idle = true

C.Controls = class Controls
  constructor: () ->
    @up = false
    @down = false
    @left = false
    @right = false

C.Goto = class Goto
  constructor: ({@x, @y}) ->

C.Wander = class Wander
  constructor: ({@range}) ->

