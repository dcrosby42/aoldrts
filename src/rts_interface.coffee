class RtsInterface
  constructor: ({@sprites, @renderer}) ->
    @x_move = 0
    @y_move = 0

    width = @renderer.width
    height = @renderer.height

    buffer = 32

    speed = 8

    @sprites.mousemove = (data) =>
      x = data.global.x
      y = data.global.y

      negSpeed = (p, b, speed) ->
        -1 * ((p - b) / b) * speed
      posSpeed = (p, b, s, speed) ->
        -1 * ((p - (s - b)) / b) * speed

      if x <= buffer
        @x_move = negSpeed(x, buffer, speed)
      else if x >= width - buffer
        @x_move = posSpeed(x, buffer, width, speed)
      else
        @x_move = 0

      if y <= buffer
        @y_move = negSpeed(y, buffer, speed)
      else if y >= height - buffer
        @y_move = posSpeed(y, buffer, height, speed)
      else
        @y_move = 0

  update: ->
    @sprites.position.x += @x_move
    @sprites.position.y += @y_move

module.exports = RtsInterface