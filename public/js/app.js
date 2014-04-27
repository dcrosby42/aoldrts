(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var EntityInspector, GameRunner, KeyboardController, ParkMillerRNG, PixiWrapper, RtsWorld, StopWatch, buildKeyboardController, buildPixiWrapper, buildSimulation, buildStopWatch, getMeta, setupStats, _copyData;

RtsWorld = require('./rts_world.coffee');

StopWatch = require('./stop_watch.coffee');

KeyboardController = require('./keyboard_controller.coffee');

PixiWrapper = require('./pixi_wrapper.coffee');

GameRunner = require('./game_runner.coffee');

ParkMillerRNG = require('./pm_prng.coffee');

EntityInspector = require('./entity_inspector.coffee');

getMeta = function(name) {
  var meta, _i, _len, _ref;
  _ref = document.getElementsByTagName('meta');
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    meta = _ref[_i];
    if (meta.getAttribute("name") === name) {
      return meta.getAttribute("content");
    }
  }
  return null;
};

window.gameConfig = function() {
  var scheme, useHttps;
  if (this._gameConfig) {
    return this._gameConfig;
  }
  useHttps = !!(window.location.protocol.match(/https/));
  scheme = useHttps ? "https" : "http";
  this._gameConfig = {
    stageWidth: window.screen.width / 2,
    stageHeight: window.screen.height / 2,
    imageAssets: ["images/bunny.png", "images/EBRobotedit2crMatsuoKaito.png", "images/bunny.png", "images/logo.png", "images/terrain.png"],
    spriteSheetAssets: ["images/EBRobotedit2crMatsuoKaito.json", "images/terrain.json"],
    simSimConnection: {
      url: "" + scheme + "://" + window.location.hostname,
      secure: useHttps
    }
  };
  return this._gameConfig;
};

window.local = {
  vars: {},
  gameRunner: null,
  entityInspector: null
};

window.onload = function() {
  var gameConfig, pixiWrapper, stats;
  gameConfig = window.gameConfig();
  stats = setupStats();
  pixiWrapper = buildPixiWrapper({
    width: gameConfig.stageWidth,
    height: gameConfig.stageHeight,
    assets: gameConfig.imageAssets,
    spriteSheets: gameConfig.spriteSheetAssets
  });
  pixiWrapper.appendViewTo(document.getElementById('gameDiv'));
  return pixiWrapper.loadAssets(function() {
    var entityInspector, gameRunner, keyboardController, simulation, stopWatch, world;
    entityInspector = new EntityInspector();
    world = new RtsWorld({
      pixiWrapper: pixiWrapper,
      entityInspector: entityInspector
    });
    simulation = buildSimulation({
      world: world,
      url: gameConfig.simSimConnection.url,
      secure: gameConfig.simSimConnection.secure
    });
    keyboardController = buildKeyboardController();
    stopWatch = buildStopWatch();
    gameRunner = new GameRunner({
      window: window,
      simulation: simulation,
      pixiWrapper: pixiWrapper,
      keyboardController: keyboardController,
      stats: stats,
      stopWatch: stopWatch
    });
    window.local.entityInspector = entityInspector;
    window.local.gameRunner = gameRunner;
    window.local.pixiWrapper = pixiWrapper;
    gameRunner.start();
    window.watchData();
    return window.mouseScrollingChanged();
  });
};

buildStopWatch = function() {
  var stopWatch;
  stopWatch = new StopWatch();
  stopWatch.lap();
  return stopWatch;
};

buildSimulation = function(opts) {
  var simulation;
  if (opts == null) {
    opts = {};
  }
  return simulation = SimSim.createSimulation({
    adapter: {
      type: 'socket_io',
      options: {
        url: opts.url,
        secure: opts.secure
      }
    },
    client: {
      spyOnOutgoing: function(simulation, message) {
        if (!message.type.match(/turn/i) && !(message['data'] && message.data['method'] && message.data.method === "updateControl")) {
          return console.log("<<< Client SEND", message);
        }
      },
      spyOnIncoming: function(simulation, message) {
        if (!message.type.match(/turn/i) && !(message['data'] && message.data['method'] && message.data.method === "updateControl")) {
          return console.log(">>> Client RECV", message);
        }
      }
    },
    world: opts.world
  });
};

setupStats = function() {
  var container, stats;
  container = document.createElement("div");
  document.getElementById("gameDiv").appendChild(container);
  stats = new Stats();
  container.appendChild(stats.domElement);
  stats.domElement.style.position = "absolute";
  return stats;
};

buildPixiWrapper = function(opts) {
  if (opts == null) {
    opts = {};
  }
  return new PixiWrapper(opts);
};

buildKeyboardController = function() {
  return new KeyboardController({
    w: "up",
    a: "left",
    d: "right",
    s: "down",
    up: "up",
    left: "left",
    right: "right",
    down: "down"
  });
};

_copyData = function(data) {
  return JSON.parse(JSON.stringify(data));
};

window.takeSnapshot = function() {
  var d, ss;
  d = window.local.gameRunner.simulation.world.getData();
  ss = _copyData(d);
  console.log(ss);
  return window.local.vars.snapshot = ss;
};

window.restoreSnapshot = function() {
  var ss;
  ss = window.local.vars.snapshot;
  console.log(ss);
  return window.local.gameRunner.simulation.world.setData(_copyData(ss));
};

window.stop = function() {
  return window.local.gameRunner.stop();
};

window.start = function() {
  return window.local.gameRunner.start();
};

window.mouseScrollingChanged = function() {
  var onOff;
  onOff = document.getElementById("mouseScrolling").checked;
  return window.local.pixiWrapper.setMouseScrollingOn(onOff);
};

window.watchData = function() {
  var comp, compType, components, entityId, insp, k, pre, txt, v, _ref;
  insp = window.local.entityInspector;
  pre = document.getElementById("entityInspectorOutput");
  txt = "";
  _ref = insp.componentsByEntity();
  for (entityId in _ref) {
    components = _ref[entityId];
    txt += "Entity " + entityId + ":\n";
    for (compType in components) {
      comp = components[compType];
      txt += "  " + compType + ":\n";
      for (k in comp) {
        v = comp[k];
        txt += "    " + k + ": " + v + " (" + (typeof v) + ")\n";
      }
    }
  }
  pre.textContent = txt;
  insp.reset();
  return setTimeout(window.watchData, 500);
};


},{"./entity_inspector.coffee":3,"./game_runner.coffee":4,"./keyboard_controller.coffee":5,"./pixi_wrapper.coffee":6,"./pm_prng.coffee":7,"./rts_world.coffee":9,"./stop_watch.coffee":10}],2:[function(require,module,exports){
var CRC32_TABLE, ChecksumCalculator;

CRC32_TABLE = "00000000 77073096 EE0E612C 990951BA 076DC419 706AF48F E963A535 9E6495A3 0EDB8832 79DCB8A4 E0D5E91E 97D2D988 09B64C2B 7EB17CBD E7B82D07 90BF1D91 1DB71064 6AB020F2 F3B97148 84BE41DE 1ADAD47D 6DDDE4EB F4D4B551 83D385C7 136C9856 646BA8C0 FD62F97A 8A65C9EC 14015C4F 63066CD9 FA0F3D63 8D080DF5 3B6E20C8 4C69105E D56041E4 A2677172 3C03E4D1 4B04D447 D20D85FD A50AB56B 35B5A8FA 42B2986C DBBBC9D6 ACBCF940 32D86CE3 45DF5C75 DCD60DCF ABD13D59 26D930AC 51DE003A C8D75180 BFD06116 21B4F4B5 56B3C423 CFBA9599 B8BDA50F 2802B89E 5F058808 C60CD9B2 B10BE924 2F6F7C87 58684C11 C1611DAB B6662D3D 76DC4190 01DB7106 98D220BC EFD5102A 71B18589 06B6B51F 9FBFE4A5 E8B8D433 7807C9A2 0F00F934 9609A88E E10E9818 7F6A0DBB 086D3D2D 91646C97 E6635C01 6B6B51F4 1C6C6162 856530D8 F262004E 6C0695ED 1B01A57B 8208F4C1 F50FC457 65B0D9C6 12B7E950 8BBEB8EA FCB9887C 62DD1DDF 15DA2D49 8CD37CF3 FBD44C65 4DB26158 3AB551CE A3BC0074 D4BB30E2 4ADFA541 3DD895D7 A4D1C46D D3D6F4FB 4369E96A 346ED9FC AD678846 DA60B8D0 44042D73 33031DE5 AA0A4C5F DD0D7CC9 5005713C 270241AA BE0B1010 C90C2086 5768B525 206F85B3 B966D409 CE61E49F 5EDEF90E 29D9C998 B0D09822 C7D7A8B4 59B33D17 2EB40D81 B7BD5C3B C0BA6CAD EDB88320 9ABFB3B6 03B6E20C 74B1D29A EAD54739 9DD277AF 04DB2615 73DC1683 E3630B12 94643B84 0D6D6A3E 7A6A5AA8 E40ECF0B 9309FF9D 0A00AE27 7D079EB1 F00F9344 8708A3D2 1E01F268 6906C2FE F762575D 806567CB 196C3671 6E6B06E7 FED41B76 89D32BE0 10DA7A5A 67DD4ACC F9B9DF6F 8EBEEFF9 17B7BE43 60B08ED5 D6D6A3E8 A1D1937E 38D8C2C4 4FDFF252 D1BB67F1 A6BC5767 3FB506DD 48B2364B D80D2BDA AF0A1B4C 36034AF6 41047A60 DF60EFC3 A867DF55 316E8EEF 4669BE79 CB61B38C BC66831A 256FD2A0 5268E236 CC0C7795 BB0B4703 220216B9 5505262F C5BA3BBE B2BD0B28 2BB45A92 5CB36A04 C2D7FFA7 B5D0CF31 2CD99E8B 5BDEAE1D 9B64C2B0 EC63F226 756AA39C 026D930A 9C0906A9 EB0E363F 72076785 05005713 95BF4A82 E2B87A14 7BB12BAE 0CB61B38 92D28E9B E5D5BE0D 7CDCEFB7 0BDBDF21 86D3D2D4 F1D4E242 68DDB3F8 1FDA836E 81BE16CD F6B9265B 6FB077E1 18B74777 88085AE6 FF0F6A70 66063BCA 11010B5C 8F659EFF F862AE69 616BFFD3 166CCF45 A00AE278 D70DD2EE 4E048354 3903B3C2 A7672661 D06016F7 4969474D 3E6E77DB AED16A4A D9D65ADC 40DF0B66 37D83BF0 A9BCAE53 DEBB9EC5 47B2CF7F 30B5FFE9 BDBDF21C CABAC28A 53B39330 24B4A3A6 BAD03605 CDD70693 54DE5729 23D967BF B3667A2E C4614AB8 5D681B02 2A6F2B94 B40BBE37 C30C8EA1 5A05DF1B 2D02EF8D";

ChecksumCalculator = (function() {
  function ChecksumCalculator() {}

  ChecksumCalculator.prototype.calculate = function(str, crc) {
    var i, n, x, _i, _ref;
    if (crc == null) {
      crc = 0;
    }
    n = 0;
    x = 0;
    crc = crc ^ (-1);
    for (i = _i = 0, _ref = str.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      n = (crc ^ str.charCodeAt(i)) & 0xFF;
      x = "0x" + CRC32_TABLE.substr(n * 9, 8);
      crc = (crc >>> 8) ^ x;
    }
    return crc ^ (-1);
  };

  return ChecksumCalculator;

})();

module.exports = ChecksumCalculator;


},{}],3:[function(require,module,exports){
var EntityInspector;

EntityInspector = (function() {
  function EntityInspector() {
    this.reset();
  }

  EntityInspector.prototype.reset = function() {
    return this._data = {};
  };

  EntityInspector.prototype.update = function(entityId, component) {
    var eid, typeName, _base;
    eid = "" + entityId;
    typeName = component ? component.constructor ? component.constructor.name : component.toString() : "(!undefined component!)";
    (_base = this._data)[eid] || (_base[eid] = {});
    return this._data[eid][typeName] = component;
  };

  EntityInspector.prototype.componentsByEntity = function() {
    return this._data;
  };

  return EntityInspector;

})();

module.exports = EntityInspector;


},{}],4:[function(require,module,exports){
var GameRunner;

GameRunner = (function() {
  function GameRunner(_arg) {
    this.window = _arg.window, this.simulation = _arg.simulation, this.pixiWrapper = _arg.pixiWrapper, this.stats = _arg.stats, this.stopWatch = _arg.stopWatch, this.keyboardController = _arg.keyboardController;
    this.shouldRun = false;
  }

  GameRunner.prototype.start = function() {
    this.simulation.start();
    this.shouldRun = true;
    return this.update();
  };

  GameRunner.prototype.stop = function() {
    this.shouldRun = false;
    return this.simulation.stop();
  };

  GameRunner.prototype.update = function() {
    var action, value, _ref;
    if (this.shouldRun) {
      this.window.requestAnimationFrame((function(_this) {
        return function() {
          return _this.update();
        };
      })(this));
      _ref = this.keyboardController.update();
      for (action in _ref) {
        value = _ref[action];
        this.simulation.worldProxy("updateControl", action, value);
      }
      this.simulation.update(this.stopWatch.elapsedSeconds());
      this.pixiWrapper.render();
      return this.stats.update();
    }
  };

  return GameRunner;

})();

module.exports = GameRunner;


},{}],5:[function(require,module,exports){
var InputState, KeyboardController, KeyboardWrapper;

KeyboardWrapper = (function() {
  function KeyboardWrapper(keys) {
    var key, _i, _len, _ref;
    this.keys = keys;
    this.downs = {};
    _ref = this.keys;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      this.downs[key] = false;
      this._bind(key);
    }
  }

  KeyboardWrapper.prototype._bind = function(key) {
    Mousetrap.bind(key, ((function(_this) {
      return function() {
        return _this._keyDown(key);
      };
    })(this)), 'keydown');
    return Mousetrap.bind(key, ((function(_this) {
      return function() {
        return _this._keyUp(key);
      };
    })(this)), 'keyup');
  };

  KeyboardWrapper.prototype._keyDown = function(key) {
    this.downs[key] = true;
    return false;
  };

  KeyboardWrapper.prototype._keyUp = function(key) {
    this.downs[key] = false;
    return false;
  };

  KeyboardWrapper.prototype.isActive = function(key) {
    return this.downs[key];
  };

  return KeyboardWrapper;

})();

InputState = (function() {
  function InputState(key) {
    this.key = key;
    this.active = false;
  }

  InputState.prototype.update = function(keyboardWrapper) {
    var newState, oldState;
    oldState = this.active;
    newState = keyboardWrapper.isActive(this.key);
    this.active = newState;
    if (!oldState && newState) {
      return "justPressed";
    }
    if (oldState && !newState) {
      return "justReleased";
    } else {
      return null;
    }
  };

  return InputState;

})();

KeyboardController = (function() {
  function KeyboardController(bindings) {
    var action, key, _ref;
    this.bindings = bindings;
    this.keys = [];
    this.inputStates = {};
    this.actionStates = {};
    _ref = this.bindings;
    for (key in _ref) {
      action = _ref[key];
      this.keys.push(key);
      this.inputStates[key] = new InputState(key);
      this.actionStates[key] = false;
    }
    this.keyboardWrapper = new KeyboardWrapper(this.keys);
  }

  KeyboardController.prototype.update = function() {
    var action, diff, inputState, key, res, _ref;
    diff = {};
    _ref = this.inputStates;
    for (key in _ref) {
      inputState = _ref[key];
      action = this.bindings[key];
      res = inputState.update(this.keyboardWrapper);
      switch (res) {
        case "justPressed":
          diff[action] = true;
          this.actionStates[action] = true;
          break;
        case "justReleased":
          diff[action] = false;
          this.actionStates[action] = false;
      }
    }
    return diff;
  };

  KeyboardController.prototype.isActive = function(action) {
    return this.actionStates[action];
  };

  return KeyboardController;

})();

module.exports = KeyboardController;


},{}],6:[function(require,module,exports){
var PixiWrapper, RtsInterface;

RtsInterface = require('./rts_interface.coffee');

PixiWrapper = (function() {
  function PixiWrapper(opts) {
    var sheet;
    this.stage = new PIXI.Stage(0xDDDDDD, true);
    this.renderer = PIXI.autoDetectRenderer(opts.width, opts.height, void 0, false);
    this.loader = new PIXI.AssetLoader(opts.assets);
    this.spriteSheetLoaders = (function() {
      var _i, _len, _ref, _results;
      _ref = opts.spriteSheets;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sheet = _ref[_i];
        _results.push(new PIXI.SpriteSheetLoader(sheet));
      }
      return _results;
    })();
    this.sprites = new PIXI.DisplayObjectContainer();
    this.sprites.setInteractive(true);
    this.stage.addChild(this.sprites);
    this["interface"] = new RtsInterface({
      sprites: this.sprites,
      renderer: this.renderer
    });
  }

  PixiWrapper.prototype.appendViewTo = function(el) {
    var onEnter, onExit;
    this.renderer.view.id = "game";
    el.appendChild(this.renderer.view);
    onEnter = (function(_this) {
      return function() {
        return _this.fullscreen();
      };
    })(this);
    onExit = (function(_this) {
      return function() {
        return _this.smallscreen();
      };
    })(this);
    return document.getElementById("fullscreen").addEventListener("click", (function() {
      var element;
      element = document.getElementById("game");
      if (BigScreen.enabled) {
        BigScreen.request(element, onEnter, onExit);
      } else {

      }
    }), false);
  };

  PixiWrapper.prototype.setMouseScrollingOn = function(onOff) {
    return this["interface"].setMouseScrollingOn(onOff);
  };

  PixiWrapper.prototype.fullscreen = function() {
    this.renderer.view.style.width = window.screen.width + "px";
    return this.renderer.view.style.height = window.screen.height + "px";
  };

  PixiWrapper.prototype.smallscreen = function() {
    this.renderer.view.style.width = window.screen.width / 2 + "px";
    return this.renderer.view.style.height = window.screen.height / 2 + "px";
  };

  PixiWrapper.prototype.loadAssets = function(callback) {
    var sheet, _i, _len, _ref;
    this.loader.onComplete = callback;
    this.loader.load();
    _ref = this.spriteSheetLoaders;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      sheet = _ref[_i];
      sheet.load();
    }
    return null;
  };

  PixiWrapper.prototype.render = function() {
    this["interface"].update();
    return this.renderer.render(this.stage);
  };

  return PixiWrapper;

})();

module.exports = PixiWrapper;


},{"./rts_interface.coffee":8}],7:[function(require,module,exports){
var ParkMillerRNG;

ParkMillerRNG = (function() {
  function ParkMillerRNG(seed) {
    this.seed = seed;
    this.gen();
  }

  ParkMillerRNG.prototype.gen = function() {
    return this.seed = (this.seed * 16807) % 2147483647;
  };

  ParkMillerRNG.prototype.nextInt = function(min, max) {
    return Math.round(min + ((max - min) * this.gen() / 2147483647.0));
  };

  return ParkMillerRNG;

})();

module.exports = ParkMillerRNG;


},{}],8:[function(require,module,exports){
var RtsInterface;

RtsInterface = (function() {
  function RtsInterface(_arg) {
    var buffer, height, speed, width;
    this.sprites = _arg.sprites, this.renderer = _arg.renderer;
    this.x_move = 0;
    this.y_move = 0;
    width = this.renderer.width;
    height = this.renderer.height;
    buffer = 32;
    speed = 8;
    this.on = true;
    this.sprites.mousemove = (function(_this) {
      return function(data) {
        var negSpeed, posSpeed, x, y;
        if (!_this.on) {
          return;
        }
        x = data.global.x;
        y = data.global.y;
        negSpeed = function(p, b, speed) {
          return -1 * ((p - b) / b) * speed;
        };
        posSpeed = function(p, b, s, speed) {
          return -1 * ((p - (s - b)) / b) * speed;
        };
        if (x <= buffer) {
          _this.x_move = negSpeed(x, buffer, speed);
        } else if (x >= width - buffer) {
          _this.x_move = posSpeed(x, buffer, width, speed);
        } else {
          _this.x_move = 0;
        }
        if (y <= buffer) {
          return _this.y_move = negSpeed(y, buffer, speed);
        } else if (y >= height - buffer) {
          return _this.y_move = posSpeed(y, buffer, height, speed);
        } else {
          return _this.y_move = 0;
        }
      };
    })(this);
  }

  RtsInterface.prototype.update = function() {
    if (this.on) {
      this.sprites.position.x += this.x_move;
      return this.sprites.position.y += this.y_move;
    }
  };

  RtsInterface.prototype.setMouseScrollingOn = function(onOff) {
    return this.on = onOff;
  };

  return RtsInterface;

})();

module.exports = RtsInterface;


},{}],9:[function(require,module,exports){
var BUNNY_VEL, ChecksumCalculator, ComponentRegister, ControlMappingSystem, ControlSystem, Controls, EntityFactory, EntityInspectorSystem, HalfPI, MapTiles, MapTilesSystem, Movement, MovementSystem, Player, Position, RtsWorld, Sprite, SpriteSyncSystem, fixFloat,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Array.prototype.compact = function() {
  var elem, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = this.length; _i < _len; _i++) {
    elem = this[_i];
    if (elem != null) {
      _results.push(elem);
    }
  }
  return _results;
};

ChecksumCalculator = require('./checksum_calculator.coffee');

ComponentRegister = (function() {
  var ctors, nextType, types;
  nextType = 0;
  ctors = [];
  types = [];
  return {
    register: function(ctor) {
      var i;
      i = ctors.indexOf(ctor);
      if (i < 0) {
        ctors.push(ctor);
        types.push(nextType++);
      }
    },
    get: function(ctor) {
      var i;
      i = ctors.indexOf(ctor);
      if (i < 0) {
        throw "Unknown type " + ctor;
      }
      return types[i];
    }
  };
})();

makr.World.prototype.resurrect = function(entId) {
  var entity;
  entity = null;
  if (this._dead.length > 0) {
    entity = this._dead.pop();
    entity._alive = true;
    entity._id = entId;
    entity._componentMask.reset();
  } else {
    entity = new makr.Entity(this, +entId);
  }
  this._alive.push(entity);
  return entity;
};

Player = (function() {
  function Player(_arg) {
    this.id = _arg.id;
  }

  return Player;

})();

Position = (function() {
  function Position(_arg) {
    this.x = _arg.x, this.y = _arg.y;
  }

  return Position;

})();

Movement = (function() {
  function Movement(_arg) {
    this.vx = _arg.vx, this.vy = _arg.vy;
  }

  return Movement;

})();

MapTiles = (function() {
  function MapTiles(_arg) {
    this.seed = _arg.seed, this.width = _arg.width, this.height = _arg.height;
  }

  return MapTiles;

})();

MapTilesSystem = (function(_super) {
  __extends(MapTilesSystem, _super);

  function MapTilesSystem(pixiWrapper) {
    this.pixiWrapper = pixiWrapper;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(MapTiles));
    this.tilesSprites = void 0;
  }

  MapTilesSystem.prototype.onRemoved = function(entity) {
    if (this.tilesSprites != null) {
      this.pixiWrapper.sprites.removeChild(this.tilesSprites);
      return this.tilesSprites = void 0;
    }
  };

  MapTilesSystem.prototype.process = function(entity, elapsed) {
    var component;
    if (this.tilesSprites == null) {
      component = entity.get(ComponentRegister.get(MapTiles));
      this.tilesSprites = this.createTiles(component.seed);
      return this.pixiWrapper.sprites.addChildAt(this.tilesSprites, 0);
    }
  };

  MapTilesSystem.prototype.createTiles = function(seed) {
    var index, tile, tileSize, tiles, x, y, _i, _j;
    tiles = new PIXI.DisplayObjectContainer();
    tiles.position.x = 0;
    tiles.position.y = 0;
    tileSize = 31;
    for (x = _i = 0; _i <= 3200; x = _i += tileSize) {
      for (y = _j = 0; _j <= 3200; y = _j += tileSize) {
        index = (seed + x * y) % 3;
        tile = new PIXI.Sprite(PIXI.Texture.fromFrame("dirt" + index + ".png"));
        tile.position.x = x;
        tile.position.y = y;
        tiles.addChild(tile);
      }
    }
    tiles.cacheAsBitmap = true;
    tiles.position.x = -1600;
    tiles.position.y = -1600;
    return tiles;
  };

  return MapTilesSystem;

})(makr.IteratingSystem);

Sprite = (function() {
  function Sprite(_arg) {
    this.name = _arg.name, this.framelist = _arg.framelist, this.facing = _arg.facing;
    this.remove = false;
    this.add = true;
    this.facing || (this.facing = "down");
    this.idle = true;
  }

  return Sprite;

})();

Controls = (function() {
  function Controls() {
    this.up = false;
    this.down = false;
    this.left = false;
    this.right = false;
  }

  return Controls;

})();

EntityInspectorSystem = (function(_super) {
  __extends(EntityInspectorSystem, _super);

  function EntityInspectorSystem(inspector, componentClass) {
    this.inspector = inspector;
    this.componentClass = componentClass;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(this.componentClass));
  }

  EntityInspectorSystem.prototype.process = function(entity, elapsed) {
    var component;
    component = entity.get(ComponentRegister.get(this.componentClass));
    return this.inspector.update(entity.id, component);
  };

  return EntityInspectorSystem;

})(makr.IteratingSystem);

ControlSystem = (function(_super) {
  __extends(ControlSystem, _super);

  function ControlSystem(rtsWorld) {
    this.rtsWorld = rtsWorld;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(Controls));
  }

  ControlSystem.prototype.process = function(entity, elapsed) {
    var action, controls, entityControls, value, _i, _len, _ref;
    controls = entity.get(ComponentRegister.get(Controls));
    entityControls = this.rtsWorld.currentControls[entity.id] || [];
    for (_i = 0, _len = entityControls.length; _i < _len; _i++) {
      _ref = entityControls[_i], action = _ref[0], value = _ref[1];
      controls[action] = value;
    }
    return this.rtsWorld.currentControls[entity.id] = [];
  };

  return ControlSystem;

})(makr.IteratingSystem);

ControlMappingSystem = (function(_super) {
  __extends(ControlMappingSystem, _super);

  function ControlMappingSystem() {
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(Movement));
    this.registerComponent(ComponentRegister.get(Controls));
  }

  ControlMappingSystem.prototype.process = function(entity, elapsed) {
    var controls, movement;
    movement = entity.get(ComponentRegister.get(Movement));
    controls = entity.get(ComponentRegister.get(Controls));
    if (controls.up) {
      movement.vy = -BUNNY_VEL;
    } else if (controls.down) {
      movement.vy = BUNNY_VEL;
    } else {
      movement.vy = 0;
    }
    if (controls.left) {
      return movement.vx = -BUNNY_VEL;
    } else if (controls.right) {
      return movement.vx = BUNNY_VEL;
    } else {
      return movement.vx = 0;
    }
  };

  return ControlMappingSystem;

})(makr.IteratingSystem);

MovementSystem = (function(_super) {
  __extends(MovementSystem, _super);

  function MovementSystem() {
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(Movement));
    this.registerComponent(ComponentRegister.get(Position));
  }

  MovementSystem.prototype.process = function(entity, elapsed) {
    var movement, position;
    position = entity.get(ComponentRegister.get(Position));
    movement = entity.get(ComponentRegister.get(Movement));
    if (position == null) {
      console.log(entity);
    }
    position.x += movement.vx;
    return position.y += movement.vy;
  };

  return MovementSystem;

})(makr.IteratingSystem);

SpriteSyncSystem = (function(_super) {
  __extends(SpriteSyncSystem, _super);

  function SpriteSyncSystem(pixiWrapper) {
    this.pixiWrapper = pixiWrapper;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(Sprite));
    this.registerComponent(ComponentRegister.get(Position));
    this.registerComponent(ComponentRegister.get(Movement));
    this.spriteCache = {};
    this.spriteFrameCache = {};
  }

  SpriteSyncSystem.prototype.onRemoved = function(entity) {
    this.pixiWrapper.sprites.removeChild(this.spriteCache[entity.id]);
    return this.spriteCache[entity.id] = void 0;
  };

  SpriteSyncSystem.prototype.process = function(entity, elapsed) {
    var movement, pixiSprite, position, sprite;
    position = entity.get(ComponentRegister.get(Position));
    sprite = entity.get(ComponentRegister.get(Sprite));
    movement = entity.get(ComponentRegister.get(Movement));
    pixiSprite = this.spriteCache[entity.id];
    if (pixiSprite == null) {
      pixiSprite = this.buildSprite(entity, sprite, position);
    } else if (sprite.remove) {
      this.removeSprite(entity, sprite);
    } else {
      pixiSprite.position.x = position.x;
      pixiSprite.position.y = position.y;
    }
    switch (false) {
      case !(movement.vx > 0):
        sprite.facing = "right";
        sprite.idle = false;
        break;
      case !(movement.vx < 0):
        sprite.facing = "left";
        sprite.idle = false;
        break;
      case !(movement.vy > 0):
        sprite.facing = "down";
        sprite.idle = false;
        break;
      case !(movement.vy < 0):
        sprite.facing = "up";
        sprite.idle = false;
        break;
      default:
        sprite.idle = true;
    }
    if (sprite.framelist) {
      if (sprite.idle) {
        return pixiSprite.textures = this.spriteFrameCache[sprite.name]["" + sprite.facing + "Idle"];
      } else {
        return pixiSprite.textures = this.spriteFrameCache[sprite.name][sprite.facing];
      }
    }
  };

  SpriteSyncSystem.prototype.buildSprite = function(entity, sprite, position) {
    var container, endIndex, frame, frameCache, frames, pixiSprite, pose, _ref;
    console.log("ADDING SPRITE FOR " + entity.id);
    pixiSprite = void 0;
    if (sprite.framelist) {
      if (!this.spriteFrameCache[sprite.name]) {
        frameCache = {};
        _ref = sprite.framelist;
        for (pose in _ref) {
          frames = _ref[pose];
          frameCache[pose] = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = frames.length; _i < _len; _i++) {
              frame = frames[_i];
              _results.push(new PIXI.Texture.fromFrame(frame));
            }
            return _results;
          })();
        }
        this.spriteFrameCache[sprite.name] = frameCache;
      }
      pixiSprite = new PIXI.MovieClip(this.spriteFrameCache[sprite.name][sprite.facing]);
      pixiSprite.animationSpeed = 0.05;
      pixiSprite.play();
    } else {
      pixiSprite = new PIXI.Sprite(PIXI.Texture.fromFrame(sprite.name));
    }
    pixiSprite.anchor.x = pixiSprite.anchor.y = 0.5;
    pixiSprite.position.x = position.x;
    pixiSprite.position.y = position.y;
    container = this.pixiWrapper.sprites;
    endIndex = container.children.length;
    container.addChildAt(pixiSprite, endIndex);
    console.log("ADDING SPRITE FOR " + entity.id + " at child index " + endIndex);
    sprite.add = false;
    return this.spriteCache[entity.id] = pixiSprite;
  };

  SpriteSyncSystem.prototype.removeSprite = function(entity, sprite) {
    this.pixiWrapper.sprites.removeChild(this.spriteCache[entity.id]);
    delete this.spriteCache[entity.id];
    return sprite.remove = false;
  };

  return SpriteSyncSystem;

})(makr.IteratingSystem);

fixFloat = SimSim.Util.fixFloat;

HalfPI = Math.PI / 2;

EntityFactory = (function() {
  function EntityFactory(ecs) {
    this.ecs = ecs;
  }

  EntityFactory.prototype.generateRobotFrameList = function(robotName) {
    return {
      down: ["" + robotName + "_down_0", "" + robotName + "_down_1", "" + robotName + "_down_2", "" + robotName + "_down_1"],
      left: ["" + robotName + "_left_0", "" + robotName + "_left_1", "" + robotName + "_left_2", "" + robotName + "_left_1"],
      up: ["" + robotName + "_up_0", "" + robotName + "_up_1", "" + robotName + "_up_2", "" + robotName + "_up_1"],
      right: ["" + robotName + "_right_0", "" + robotName + "_right_1", "" + robotName + "_right_2", "" + robotName + "_right_1"],
      downIdle: ["" + robotName + "_down_1"],
      leftIdle: ["" + robotName + "_left_1"],
      upIdle: ["" + robotName + "_up_1"],
      rightIdle: ["" + robotName + "_right_1"]
    };
  };

  EntityFactory.prototype.robot = function(x, y, robotName) {
    var robot;
    robot = this.ecs.create();
    robot.add(new Position({
      x: x,
      y: y
    }), ComponentRegister.get(Position));
    robot.add(new Sprite({
      name: robotName,
      framelist: this.generateRobotFrameList(robotName)
    }), ComponentRegister.get(Sprite));
    robot.add(new Controls(), ComponentRegister.get(Controls));
    robot.add(new Movement({
      vx: 0,
      vy: 0
    }), ComponentRegister.get(Movement));
    return robot;
  };

  EntityFactory.prototype.mapTiles = function(seed, width, height) {
    var comp, mapTiles;
    mapTiles = this.ecs.create();
    comp = new MapTiles({
      seed: seed,
      width: width,
      height: height
    });
    mapTiles.add(comp, ComponentRegister.get(MapTiles));
    return mapTiles;
  };

  return EntityFactory;

})();

BUNNY_VEL = 3;

RtsWorld = (function(_super) {
  __extends(RtsWorld, _super);

  function RtsWorld(_arg) {
    this.pixiWrapper = _arg.pixiWrapper, this.entityInspector = _arg.entityInspector;
    this.pixiWrapper || (function() {
      throw new Error("Need pixiWrapper");
    })();
    this.checksumCalculator = new ChecksumCalculator();
    this.ecs = this.setupECS(this.pixieWrapper);
    this.entityFactory = new EntityFactory(this.ecs);
    this.players = {};
    this.currentControls = {};
    if (this.entityInspector) {
      this.setupEntityInspector(this.ecs, this.entityInspector);
    }
    this.entityFactory.mapTiles((Math.random() * 1000) | 0, 50, 50);
  }

  RtsWorld.prototype.setupECS = function(pixieWrapper) {
    var ecs;
    ComponentRegister.register(Position);
    ComponentRegister.register(Sprite);
    ComponentRegister.register(Player);
    ComponentRegister.register(Movement);
    ComponentRegister.register(Controls);
    ComponentRegister.register(MapTiles);
    ecs = new makr.World();
    ecs.registerSystem(new SpriteSyncSystem(this.pixiWrapper));
    ecs.registerSystem(new MapTilesSystem(this.pixiWrapper));
    ecs.registerSystem(new ControlSystem(this));
    ecs.registerSystem(new MovementSystem());
    ecs.registerSystem(new ControlMappingSystem());
    return ecs;
  };

  RtsWorld.prototype.setupEntityInspector = function(ecs, entityInspector) {
    var componentClass, _i, _len, _ref;
    _ref = [Position, Player, MapTiles];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      componentClass = _ref[_i];
      ecs.registerSystem(new EntityInspectorSystem(entityInspector, componentClass));
    }
    return entityInspector;
  };

  RtsWorld.prototype.findEntityById = function(id) {
    var entity;
    return ((function() {
      var _i, _len, _ref, _results;
      _ref = this.ecs._alive;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entity = _ref[_i];
        if (("" + entity.id) === ("" + id)) {
          _results.push(entity);
        }
      }
      return _results;
    }).call(this))[0];
  };

  RtsWorld.prototype.resetData = function() {};

  RtsWorld.prototype.deserializeComponent = function(serializedComponent) {
    return eval("new " + serializedComponent.type + "(serializedComponent)");
  };

  RtsWorld.prototype.updateControl = function(id, action, value) {
    var _base, _name;
    (_base = this.currentControls)[_name = this.players[id]] || (_base[_name] = []);
    return this.currentControls[this.players[id]].push([action, value]);
  };

  RtsWorld.prototype.addPlayer = function(playerId) {};

  RtsWorld.prototype.removePlayer = function(playerId) {};

  RtsWorld.prototype.playerJoined = function(playerId) {
    var robot;
    robot = this.entityFactory.robot(320, 224, "robot_6");
    robot.add(new Player({
      id: playerId
    }), ComponentRegister.get(Player));
    this.players[playerId] = robot.id;
    return console.log("Player " + playerId + ", JOINED, entity id " + robot.id);
  };

  RtsWorld.prototype.playerLeft = function(playerId) {
    var ent;
    ent = this.findEntityById(this.players[playerId]);
    console.log("Player " + playerId + " LEFT, killing entity id " + ent.id);
    ent.kill();
    return this.players[playerId] = void 0;
  };

  RtsWorld.prototype.theEnd = function() {
    this.resetData();
    return console.log("THE END");
  };

  RtsWorld.prototype.step = function(dt) {
    return this.ecs.update(dt);
  };

  RtsWorld.prototype.setData = function(data) {
    var c, comp, components, comps, ent, entId, entity, staleEnts, _i, _len, _ref, _results;
    this.players = data.players;
    this.ecs._nextEntityID = data.nextEntityId;
    console.log("setData: @ecs._nextEntityID set to " + this.ecs._nextEntityID);
    staleEnts = this.ecs._alive.slice(0);
    for (_i = 0, _len = staleEnts.length; _i < _len; _i++) {
      ent = staleEnts[_i];
      console.log("setData: killing entity " + ent.id, ent);
      ent.kill();
    }
    _ref = data.componentBags;
    _results = [];
    for (entId in _ref) {
      components = _ref[entId];
      entity = this.ecs.resurrect(entId);
      console.log("setData: resurrected entity for entId=" + entId + ":", entity);
      comps = (function() {
        var _j, _len1, _results1;
        _results1 = [];
        for (_j = 0, _len1 = components.length; _j < _len1; _j++) {
          c = components[_j];
          _results1.push(this.deserializeComponent(c));
        }
        return _results1;
      }).call(this);
      entity._componentMask.reset();
      _results.push((function() {
        var _j, _len1, _results1;
        _results1 = [];
        for (_j = 0, _len1 = comps.length; _j < _len1; _j++) {
          comp = comps[_j];
          console.log("setData: adding component to " + entity.id + ":", comp);
          _results1.push(entity.add(comp, ComponentRegister.get(comp.constructor)));
        }
        return _results1;
      })());
    }
    return _results;
  };

  RtsWorld.prototype.getData = function() {
    var c, componentBags, components, data, ent, entId, _ref;
    componentBags = {};
    _ref = this.ecs._componentBags;
    for (entId in _ref) {
      components = _ref[entId];
      ent = this.findEntityById(entId);
      if ((ent != null) && ent.alive) {
        componentBags[entId] = (function() {
          var _i, _len, _ref1, _results;
          _ref1 = components.compact();
          _results = [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            c = _ref1[_i];
            _results.push(this.serializeComponent(c));
          }
          return _results;
        }).call(this);
      }
    }
    data = {
      players: this.players,
      componentBags: componentBags,
      nextEntityId: this.ecs._nextEntityID
    };
    console.log(data);
    return data;
  };

  RtsWorld.prototype.serializeComponent = function(component) {
    var name, serializedComponent, value;
    serializedComponent = {};
    if (component) {
      for (name in component) {
        value = component[name];
        if (!(value instanceof Function)) {
          serializedComponent[name] = value;
        }
      }
      serializedComponent['type'] = component.constructor.name;
      return serializedComponent;
    } else {
      console.log("WTF serializeComponent got undefined component?!", component);
      return {
        type: 'BROKEN'
      };
    }
  };

  RtsWorld.prototype.deserializeComponent = function(serializedComponent) {
    return eval("new " + serializedComponent.type + "(serializedComponent)");
  };

  RtsWorld.prototype.getChecksum = function() {
    return 0;
  };

  return RtsWorld;

})(SimSim.WorldBase);

module.exports = RtsWorld;


},{"./checksum_calculator.coffee":2}],10:[function(require,module,exports){
var StopWatch;

StopWatch = (function() {
  function StopWatch() {
    this.start = this.currentTimeMillis();
    this.millis = this.start;
  }

  StopWatch.prototype.lap = function() {
    var newMillis;
    newMillis = this.currentTimeMillis();
    this.lapMillis = newMillis - this.millis;
    this.millis = newMillis;
    return this.lapSeconds();
  };

  StopWatch.prototype.currentTimeMillis = function() {
    return new Date().getTime();
  };

  StopWatch.prototype.lapSeconds = function() {
    return this.lapMillis / 1000.0;
  };

  StopWatch.prototype.elapsedSeconds = function() {
    return (this.currentTimeMillis() - this.start) / 1000.0;
  };

  return StopWatch;

})();

module.exports = StopWatch;


},{}]},{},[1])