
ComponentRegister = (->
  nextType = 0
  ctors = []
  types = []

  console.log "!!! MAKE NEW ComponentRegister 1!!"
  register: (ctor) ->
    i = ctors.indexOf(ctor)
    if i < 0
      ctors.push ctor
      types.push nextType++
    return

  get: (ctor) ->
    i = ctors.indexOf(ctor)
    throw "Unknown type " + ctor  if i < 0
    types[i]
)()

module.exports = ComponentRegister
