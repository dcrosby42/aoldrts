class HealthDisplay
  constructor: (@pixiWrapper, @introspector) ->
    @healthDisplaysByEntityId = {}

  update: ->
    ents_with_comps = @introspector.entitiesWithComponent("Health")
    for eid, components of ents_with_comps
      unless @healthDisplaysByEntityId[eid]?
        # pixiSprite = new PIXI.Sprite(PIXI.Texture.fromImage('images/bunny.png'))
        # @pixiWrapper.addUISprite(pixiSprite)
        # @healthDisplaysByEntityId[eid] = pixiSprite
        indicator = new PIXI.Graphics()
        @pixiWrapper.addUISprite(indicator)
        @healthDisplaysByEntityId[eid] = indicator

    for eid in Object.keys(@healthDisplaysByEntityId)
      sprite = @healthDisplaysByEntityId[eid]
      comps = ents_with_comps[eid]
      if comps?
        pos = comps["Position"]
        health = comps["Health"]
        sprite.position.x = pos.x
        sprite.position.y = pos.y
        # sprite.scale.y = health.health / health.maxHealth
        healthRatio = health.health / health.maxHealth
        sprite.clear()
        sprite.beginFill 0x009900
        sprite.lineStyle 1, 0x00FF00
        sprite.drawRect -15,20,(30*healthRatio),6
        sprite.endFill()
      else
        @pixiWrapper.removeUISprite(sprite)
        delete @healthDisplaysByEntityId[eid]



module.exports = HealthDisplay
