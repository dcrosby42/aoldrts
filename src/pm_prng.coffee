
class ParkMillerRNG
  constructor: (@seed) ->
    @gen()
  gen: -> @seed = (@seed * 16807) % 2147483647
  nextInt: (min, max) ->
    Math.round((min + ((max - min) * @gen() / 2147483647.0)))

  # @shuffled_upto: (n, rand_int_range) ->
  #   a = [1..n]
  #   for j in a
  #     i = rand_int_range(0, n-j-1)
  #     tmp = a[j]
  #     a[j] = a[j+i]
  #     a[j+i] = tmp

module.exports = ParkMillerRNG
