
class KeyboardWrapper
  constructor: (@keys) ->
    @downs = {}
    for key in @keys
      @downs[key] = false
      @_bind key

  _bind: (key) ->
    Mousetrap.bind key, (=> @_keyDown(key)), 'keydown'
    Mousetrap.bind key, (=> @_keyUp(key)), 'keyup'
  
  _keyDown: (key) ->
    @downs[key] = true
    false

  _keyUp: (key) ->
    @downs[key] = false
    false

  isActive: (key) ->
    @downs[key]


class InputState
  constructor: (@key)->
    @active = false

  update: (keyboardWrapper)->
    oldState = @active
    newState = keyboardWrapper.isActive(@key)
    @active = newState
    if !oldState and newState
      return "justPressed"
    if oldState and !newState
      return "justReleased"
    else
      return null

class KeyboardController
  constructor: (@bindings) ->
    @keys = []
    @inputStates = {}
    @actionStates = {}
    for key,action of @bindings
      @keys.push(key)
      @inputStates[key] = new InputState(key)
      @actionStates[key] = false

    @keyboardWrapper = new KeyboardWrapper(@keys)

  update: ->
    diff = {}
    for key,inputState of @inputStates
      action = @bindings[key]
      res = inputState.update(@keyboardWrapper)
      switch res
        when "justPressed"
          diff[action] = true
          @actionStates[action] = true
        when "justReleased"
          diff[action] = false
          @actionStates[action] = false
        # else
        #   @actionStates[action] = false
    diff

  isActive: (action) ->
    @actionStates[action]


module.exports = KeyboardController
