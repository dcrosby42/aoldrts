(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var EntityInspector, GameRunner, KeyboardController, ParkMillerRNG, PixiWrapper, RtsUI, RtsWorld, StopWatch, buildKeyboardController, buildPixiWrapper, buildSimulation, buildStopWatch, getMeta, setupStats, _copyData;

RtsWorld = require('./world/rts_world.coffee');

RtsUI = require('./ui/rts_ui.coffee');

StopWatch = require('./utils/stop_watch.coffee');

KeyboardController = require('./ui/keyboard_controller.coffee');

PixiWrapper = require('./ui/pixi_wrapper.coffee');

GameRunner = require('./ui/game_runner.coffee');

ParkMillerRNG = require('./utils/pm_prng.coffee');

EntityInspector = require('./world/entity_inspector.coffee');

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
    imageAssets: ["images/bunny.png", "images/EBRobotedit2crMatsuoKaito.png", "images/bunny.png", "images/logo.png", "images/terrain.png", "images/crystal-qubodup-ccby3-32-blue.png", "images/crystal-qubodup-ccby3-32-green.png", "images/crystal-qubodup-ccby3-32-grey.png", "images/crystal-qubodup-ccby3-32-orange.png", "images/crystal-qubodup-ccby3-32-pink.png", "images/crystal-qubodup-ccby3-32-yellow.png"],
    spriteSheetAssets: ["images/EBRobotedit2crMatsuoKaito.json", "images/terrain.json", "images/blue-crystal.json", "images/green-crystal.json", "images/grey-crystal.json", "images/orange-crystal.json", "images/pink-crystal.json", "images/yellow-crystal.json"],
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
  pixiWrapper: null
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
    var gameRunner, keyboardController, rtsUI, simulation, stopWatch, world;
    world = new RtsWorld({
      pixiWrapper: pixiWrapper,
      introspector: new EntityInspector()
    });
    simulation = buildSimulation({
      world: new RtsWorld({
        pixiWrapper: pixiWrapper,
        introspector: new EntityInspector()
      }),
      url: gameConfig.simSimConnection.url,
      secure: gameConfig.simSimConnection.secure
    });
    keyboardController = buildKeyboardController();
    stopWatch = buildStopWatch();
    rtsUI = new RtsUI({
      simulation: simulation,
      pixiWrapper: pixiWrapper,
      keyboardController: keyboardController
    });
    gameRunner = new GameRunner({
      simulation: simulation,
      ui: rtsUI,
      window: window,
      pixiWrapper: pixiWrapper,
      stats: stats,
      stopWatch: stopWatch
    });
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
    world: opts.world,
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
    }
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
  var actions, n, _i;
  actions = {
    g: "goto"
  };
  for (n = _i = 0; _i <= 6; n = ++_i) {
    actions[n] = "roboType" + n;
  }
  return new KeyboardController(actions);
};

_copyData = function(data) {
  return JSON.parse(JSON.stringify(data));
};

window.takeSnapshot = function() {
  return console.log("NO!");
};

window.restoreSnapshot = function() {
  return console.log("NO!");
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
  var comp, compType, components, entityCount, entityId, insp, k, pre, txt, v, _ref;
  insp = window.local.gameRunner.simulation.getWorldIntrospector();
  pre = document.getElementById("entityInspectorOutput");
  entityCount = insp.entityCount();
  txt = "Entity count " + entityCount + ":\n";
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


},{"./ui/game_runner.coffee":2,"./ui/keyboard_controller.coffee":3,"./ui/pixi_wrapper.coffee":4,"./ui/rts_ui.coffee":5,"./utils/pm_prng.coffee":9,"./utils/stop_watch.coffee":10,"./world/entity_inspector.coffee":12,"./world/rts_world.coffee":13}],2:[function(require,module,exports){
var GameRunner;

GameRunner = (function() {
  function GameRunner(_arg) {
    this.window = _arg.window, this.simulation = _arg.simulation, this.pixiWrapper = _arg.pixiWrapper, this.stats = _arg.stats, this.stopWatch = _arg.stopWatch, this.ui = _arg.ui;
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
    if (this.shouldRun) {
      this.window.requestAnimationFrame((function(_this) {
        return function() {
          return _this.update();
        };
      })(this));
      this.ui.update(0.17);
      this.simulation.update(this.stopWatch.elapsedSeconds());
      this.pixiWrapper.render();
      return this.stats.update();
    }
  };

  return GameRunner;

})();

module.exports = GameRunner;


},{}],3:[function(require,module,exports){
var InputState, KeyboardController, KeyboardWrapper;

KeyboardWrapper = (function() {
  function KeyboardWrapper(keys) {
    var key, _i, _len, _ref;
    this.keys = keys;
    this.downs = {};
    _ref = this.keys;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      this.downs[key] = {
        queued: [],
        last: false
      };
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
    this.downs[key]['queued'].push(true);
    return false;
  };

  KeyboardWrapper.prototype._keyUp = function(key) {
    this.downs[key]['queued'].push(false);
    return false;
  };

  KeyboardWrapper.prototype.isActive = function(key) {
    var v;
    if (this.downs[key]['queued'].length > 0) {
      v = this.downs[key]['queued'].shift();
      this.downs[key]['last'] = v;
    }
    return this.downs[key]['last'];
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


},{}],4:[function(require,module,exports){
var PixiWrapper, Viewport,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Viewport = require('./viewport.coffee');

PixiWrapper = (function(_super) {
  __extends(PixiWrapper, _super);

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
    this.bgSprites = new PIXI.DisplayObjectContainer();
    this.bgSprites.setInteractive(true);
    this.stage.addChildAt(this.bgSprites, 0);
    this.viewport = new Viewport({
      spriteGroups: [this.sprites, this.bgSprites],
      width: this.renderer.width,
      height: this.renderer.height
    });
    this.stage.mousedown = (function(_this) {
      return function(data) {
        return _this.emit("stageClicked", data);
      };
    })(this);
    this.bgSprites.mousedown = (function(_this) {
      return function(data) {
        return _this.emit("worldClicked", data);
      };
    })(this);
    this.sprites.mousedown = (function(_this) {
      return function(data) {
        return _this.emit("worldClicked", data);
      };
    })(this);
  }

  PixiWrapper.prototype.addBackgroundSprite = function(sprite, entityId) {
    if (entityId == null) {
      entityId = null;
    }
    return this.bgSprites.addChildAt(sprite, 0);
  };

  PixiWrapper.prototype.addMiddleGroundSprite = function(sprite, entityId) {
    var endIndex;
    if (entityId == null) {
      entityId = null;
    }
    endIndex = this.sprites.children.length;
    this.sprites.addChildAt(sprite, endIndex);
    console.log("ADDED SPRITE for " + entityId, sprite);
    if (entityId != null) {
      return sprite.mousedown = (function(_this) {
        return function(data) {
          return _this.emit("spriteClicked", data, entityId);
        };
      })(this);
    }
  };

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
    return this.viewport.setMouseScrollingOn(onOff);
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
    var feet_y;
    feet_y = function(sprite) {
      return sprite.y + sprite.height / 2;
    };
    this.sprites.children.sort(function(a, b) {
      if (feet_y(a) < feet_y(b)) {
        return -1;
      }
      if (feet_y(a) > feet_y(b)) {
        return 1;
      }
      return 0;
    });
    this.viewport.update();
    return this.renderer.render(this.stage);
  };

  return PixiWrapper;

})(SimSim.EventEmitter);

module.exports = PixiWrapper;


},{"./viewport.coffee":6}],5:[function(require,module,exports){
var RtsUI;

RtsUI = (function() {
  function RtsUI(_arg) {
    this.pixiWrapper = _arg.pixiWrapper, this.keyboardController = _arg.keyboardController, this.simulation = _arg.simulation;
    this.updateQueue = [];
    this.introspector = this.simulation.getWorldIntrospector();
    this._setupUnitSelection();
    this._setupRobotSpawner();
    this._setupUnitCommand();
  }

  RtsUI.prototype.update = function(dt) {
    var fn, keyEvents, _results;
    keyEvents = this.keyboardController.update();
    _results = [];
    while (fn = this.updateQueue.shift()) {
      _results.push(fn(dt));
    }
    return _results;
  };

  RtsUI.prototype._setupUnitSelection = function() {
    this.selectedEntityId = null;
    return this.pixiWrapper.on("spriteClicked", (function(_this) {
      return function(data, entityId) {
        var entity, owned;
        entity = _this.introspector.getEntity(entityId);
        owned = entity['Owned'];
        if ((owned != null) && owned.playerId === _this.simulation.clientId()) {
          return _this.selectedEntityId = entityId;
        }
      };
    })(this));
  };

  RtsUI.prototype._setupRobotSpawner = function() {
    return this.pixiWrapper.on("worldClicked", (function(_this) {
      return function(data) {
        var pt, robos, x, _i;
        pt = data.getLocalPosition(data.target);
        robos = [];
        for (x = _i = 1; _i <= 5; x = ++_i) {
          if (_this.keyboardController.isActive("roboType" + x)) {
            robos.push("robot_" + x);
          }
        }
        if (robos.length > 0) {
          return _this.updateQueue.push(function() {
            var robotType, _j, _len, _results;
            _results = [];
            for (_j = 0, _len = robos.length; _j < _len; _j++) {
              robotType = robos[_j];
              _results.push(_this.simulation.worldProxy("summonRobot", robotType, {
                x: pt.x,
                y: pt.y
              }));
            }
            return _results;
          });
        }
      };
    })(this));
  };

  RtsUI.prototype._setupUnitCommand = function() {
    return this.pixiWrapper.on("worldClicked", (function(_this) {
      return function(data) {
        var pt;
        pt = data.getLocalPosition(data.target);
        if (_this.selectedEntityId && _this.keyboardController.isActive("goto")) {
          return _this.updateQueue.push(function() {
            _this.simulation.worldProxy("commandUnit", "goto", {
              entityId: _this.selectedEntityId,
              x: pt.x,
              y: pt.y
            });
            return _this.selectedEntityId = null;
          });
        }
      };
    })(this));
  };

  return RtsUI;

})();

module.exports = RtsUI;


},{}],6:[function(require,module,exports){
var Viewport;

Viewport = (function() {
  function Viewport(_arg) {
    var buffer, height, speed, sprites, width, _i, _j, _len, _len1, _ref, _ref1;
    this.spriteGroups = _arg.spriteGroups, width = _arg.width, height = _arg.height;
    this.x_move = 0;
    this.y_move = 0;
    buffer = 32;
    speed = 8;
    this.on = true;
    _ref = this.spriteGroups;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      sprites = _ref[_i];
      sprites.mouseout = (function(_this) {
        return function(data) {
          _this.x_move = 0;
          return _this.y_move = 0;
        };
      })(this);
    }
    _ref1 = this.spriteGroups;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      sprites = _ref1[_j];
      sprites.mousemove = (function(_this) {
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
            _this.y_move = negSpeed(y, buffer, speed);
          } else if (y >= height - buffer) {
            _this.y_move = posSpeed(y, buffer, height, speed);
          } else {
            _this.y_move = 0;
          }
          return false;
        };
      })(this);
    }
  }

  Viewport.prototype.update = function() {
    var sprites, _i, _len, _ref, _results;
    if (this.on) {
      _ref = this.spriteGroups;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sprites = _ref[_i];
        sprites.position.x += this.x_move;
        _results.push(sprites.position.y += this.y_move);
      }
      return _results;
    }
  };

  Viewport.prototype.setMouseScrollingOn = function(onOff) {
    document.getElementById("game").setAttribute('tabindex', 1);
    document.getElementById("game").focus();
    return this.on = onOff;
  };

  return Viewport;

})();

module.exports = Viewport;


},{}],7:[function(require,module,exports){
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


},{}],8:[function(require,module,exports){
var ComponentRegister;

ComponentRegister = (function() {
  var ctors, nextType, types;
  nextType = 0;
  ctors = [];
  types = [];
  console.log("!!! MAKE NEW ComponentRegister 1!!");
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

module.exports = ComponentRegister;


},{}],9:[function(require,module,exports){
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

  ParkMillerRNG.prototype.choose = function(list) {
    var i;
    i = this.nextInt(0, list.length - 1);
    return list[i];
  };

  ParkMillerRNG.prototype.weighted_choose = function(list) {
    var current_weight, next_weight, target_weight, total_weight, value, weight, _i, _j, _len, _len1, _ref, _ref1;
    total_weight = 0;
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      _ref = list[_i], value = _ref[0], weight = _ref[1];
      total_weight += weight;
    }
    target_weight = this.nextInt(0, total_weight);
    current_weight = 0;
    for (_j = 0, _len1 = list.length; _j < _len1; _j++) {
      _ref1 = list[_j], value = _ref1[0], weight = _ref1[1];
      next_weight = current_weight + weight;
      if (target_weight <= (weight + current_weight)) {
        return value;
      }
      current_weight = next_weight;
    }
  };

  return ParkMillerRNG;

})();

module.exports = ParkMillerRNG;


},{}],10:[function(require,module,exports){
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


},{}],11:[function(require,module,exports){
var C, Controls, Goto, MapTiles, Movement, Owned, Position, Powerup, Sprite, Wander;

C = {};

module.exports = C;

C.Owned = Owned = (function() {
  function Owned(_arg) {
    this.playerId = _arg.playerId;
  }

  return Owned;

})();

C.Position = Position = (function() {
  function Position(_arg) {
    this.x = _arg.x, this.y = _arg.y;
  }

  return Position;

})();

C.Movement = Movement = (function() {
  function Movement(_arg) {
    this.vx = _arg.vx, this.vy = _arg.vy, this.speed = _arg.speed;
    this.speed || (this.speed = 0);
  }

  return Movement;

})();

C.MapTiles = MapTiles = (function() {
  function MapTiles(_arg) {
    this.seed = _arg.seed, this.width = _arg.width, this.height = _arg.height;
  }

  return MapTiles;

})();

C.Powerup = Powerup = (function() {
  function Powerup(_arg) {
    this.powerup_type = _arg.powerup_type;
  }

  return Powerup;

})();

C.Sprite = Sprite = (function() {
  function Sprite(_arg) {
    this.name = _arg.name, this.framelist = _arg.framelist, this.facing = _arg.facing;
    this.remove = false;
    this.add = true;
    this.facing || (this.facing = "down");
    this.idle = true;
  }

  return Sprite;

})();

C.Controls = Controls = (function() {
  function Controls() {
    this.up = false;
    this.down = false;
    this.left = false;
    this.right = false;
  }

  return Controls;

})();

C.Goto = Goto = (function() {
  function Goto(_arg) {
    this.x = _arg.x, this.y = _arg.y;
  }

  return Goto;

})();

C.Wander = Wander = (function() {
  function Wander(_arg) {
    this.range = _arg.range;
  }

  return Wander;

})();


},{}],12:[function(require,module,exports){
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

  EntityInspector.prototype.getEntity = function(entityId) {
    return this._data["" + entityId];
  };

  EntityInspector.prototype.entityCount = function() {
    return Object.keys(this._data).length;
  };

  return EntityInspector;

})();

module.exports = EntityInspector;


},{}],13:[function(require,module,exports){
var C, ChecksumCalculator, CommandQueueSystem, ComponentRegister, ControlSystem, EntityFactory, EntityInspectorSystem, GotoSystem, HalfPI, MapTilesSystem, MovementSystem, ParkMillerRNG, PlayerColors, RtsWorld, SpriteSyncSystem, WanderControlMappingSystem, eachMapTile, fixFloat,
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

PlayerColors = [0x99FF99, 0xFF99FF, 0xFFFF99, 0x9999FF, 0xFF9999, 0x99FFFF];

ChecksumCalculator = require('../utils/checksum_calculator.coffee');

ParkMillerRNG = require('../utils/pm_prng.coffee');

ComponentRegister = require('../utils/component_register.coffee');

CommandQueueSystem = require('./systems/command_queue_system.coffee');

GotoSystem = require('./systems/goto_system.coffee');

WanderControlMappingSystem = require('./systems/wander_control_mapping_system.coffee');

C = require('./components.coffee');

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

eachMapTile = function(prng, width, height, f) {
  var base, bases, feature, features, offset_x, offset_y, spare_seed, tileSize, tile_set, tile_sets, x, y, _i, _ref, _results;
  tile_sets = ["gray", "dark_brown", "dark"];
  features = [[null, 200], ["stone0", 8], ["stone1", 8], ["crater", 2]];
  bases = [["small_crater", 5], ["basic0", 50], ["basic1", 50]];
  tile_set = prng.choose(tile_sets);
  tileSize = 31;
  offset_x = (width / 2) * tileSize;
  offset_y = (height / 2) * tileSize;
  _results = [];
  for (x = _i = _ref = width * tileSize; -tileSize > 0 ? _i <= 0 : _i >= 0; x = _i += -tileSize) {
    _results.push((function() {
      var _j, _ref1, _results1;
      _results1 = [];
      for (y = _j = _ref1 = height * tileSize; -tileSize > 0 ? _j <= 0 : _j >= 0; y = _j += -tileSize) {
        base = prng.weighted_choose(bases);
        feature = prng.weighted_choose(features);
        spare_seed = prng.gen();
        _results1.push(f(x - offset_x, y - offset_y, tile_set, base, feature, spare_seed));
      }
      return _results1;
    })());
  }
  return _results;
};

MapTilesSystem = (function(_super) {
  __extends(MapTilesSystem, _super);

  function MapTilesSystem(pixiWrapper) {
    this.pixiWrapper = pixiWrapper;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(C.MapTiles));
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
      component = entity.get(ComponentRegister.get(C.MapTiles));
      this.tilesSprites = this.createTiles(component.seed, component.width, component.height);
      return this.pixiWrapper.addBackgroundSprite(this.tilesSprites);
    }
  };

  MapTilesSystem.prototype.createTile = function(tiles, frame, x, y) {
    var tile;
    tile = new PIXI.Sprite(PIXI.Texture.fromFrame(frame));
    tile.position.x = x;
    tile.position.y = y;
    return tile;
  };

  MapTilesSystem.prototype.createTiles = function(seed, width, height) {
    var prng, tiles;
    tiles = new PIXI.DisplayObjectContainer();
    tiles.position.x = 0;
    tiles.position.y = 0;
    prng = new ParkMillerRNG(seed);
    eachMapTile(prng, width, height, (function(_this) {
      return function(x, y, tile_set, base, feature) {
        var feature_frame, frame;
        frame = tile_set + "_set_" + base;
        tiles.addChild(_this.createTile(tiles, frame, x, y));
        if (feature != null) {
          feature_frame = tile_set + "_set_" + feature;
          return tiles.addChild(_this.createTile(tiles, feature_frame, x, y));
        }
      };
    })(this));
    tiles.cacheAsBitmap = true;
    return tiles;
  };

  return MapTilesSystem;

})(makr.IteratingSystem);

EntityInspectorSystem = (function(_super) {
  __extends(EntityInspectorSystem, _super);

  function EntityInspectorSystem(entityInspector, componentClass) {
    this.entityInspector = entityInspector;
    this.componentClass = componentClass;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(this.componentClass));
  }

  EntityInspectorSystem.prototype.process = function(entity, elapsed) {
    var component;
    component = entity.get(ComponentRegister.get(this.componentClass));
    return this.entityInspector.update(entity.id, component);
  };

  return EntityInspectorSystem;

})(makr.IteratingSystem);

ControlSystem = (function(_super) {
  __extends(ControlSystem, _super);

  function ControlSystem(rtsWorld) {
    this.rtsWorld = rtsWorld;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(C.Controls));
    this.registerComponent(ComponentRegister.get(C.Owned));
  }

  ControlSystem.prototype.process = function(entity, elapsed) {
    var action, controls, entityControls, value, _i, _len, _ref;
    controls = entity.get(ComponentRegister.get(C.Controls));
    entityControls = this.rtsWorld.currentControls[entity.id] || [];
    for (_i = 0, _len = entityControls.length; _i < _len; _i++) {
      _ref = entityControls[_i], action = _ref[0], value = _ref[1];
      controls[action] = value;
    }
    return this.rtsWorld.currentControls[entity.id] = [];
  };

  return ControlSystem;

})(makr.IteratingSystem);

MovementSystem = (function(_super) {
  __extends(MovementSystem, _super);

  function MovementSystem() {
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(C.Movement));
    this.registerComponent(ComponentRegister.get(C.Position));
  }

  MovementSystem.prototype.process = function(entity, elapsed) {
    var movement, position;
    position = entity.get(ComponentRegister.get(C.Position));
    movement = entity.get(ComponentRegister.get(C.Movement));
    if (position == null) {
      console.log("Y NO Position?", entity);
    }
    position.x += movement.vx * elapsed;
    return position.y += movement.vy * elapsed;
  };

  return MovementSystem;

})(makr.IteratingSystem);

SpriteSyncSystem = (function(_super) {
  __extends(SpriteSyncSystem, _super);

  function SpriteSyncSystem(pixiWrapper, playerFinder) {
    this.pixiWrapper = pixiWrapper;
    this.playerFinder = playerFinder;
    makr.IteratingSystem.call(this);
    this.registerComponent(ComponentRegister.get(C.Sprite));
    this.registerComponent(ComponentRegister.get(C.Position));
    this.registerComponent(ComponentRegister.get(C.Movement));
    this.spriteCache = {};
    this.spriteFrameCache = {};
  }

  SpriteSyncSystem.prototype.onRemoved = function(entity) {
    this.pixiWrapper.sprites.removeChild(this.spriteCache[entity.id]);
    return this.spriteCache[entity.id] = void 0;
  };

  SpriteSyncSystem.prototype.process = function(entity, elapsed) {
    var movement, owner, pixiSprite, position, sprite, vx, vy;
    position = entity.get(ComponentRegister.get(C.Position));
    sprite = entity.get(ComponentRegister.get(C.Sprite));
    movement = entity.get(ComponentRegister.get(C.Movement));
    owner = entity.get(ComponentRegister.get(C.Owned));
    pixiSprite = this.spriteCache[entity.id];
    if (pixiSprite == null) {
      pixiSprite = this.buildSprite(entity, sprite, position, owner);
    } else if (sprite.remove) {
      this.removeSprite(entity, sprite);
    } else {
      pixiSprite.position.x = position.x;
      pixiSprite.position.y = position.y;
    }
    vx = movement.vx;
    vy = movement.vy;
    if (vy < 0) {
      sprite.facing = "up";
    }
    if (vy > 0) {
      sprite.facing = "down";
    }
    if (Math.abs(vx) > Math.abs(vy)) {
      if (vx < 0) {
        sprite.facing = "left";
      }
      if (vx > 0) {
        sprite.facing = "right";
      }
    }
    sprite.idle = vx === 0 && vy === 0;
    if (sprite.framelist) {
      if (sprite.idle) {
        return pixiSprite.textures = this.spriteFrameCache[sprite.name]["" + sprite.facing + "Idle"];
      } else {
        return pixiSprite.textures = this.spriteFrameCache[sprite.name][sprite.facing];
      }
    }
  };

  SpriteSyncSystem.prototype.buildSprite = function(entity, sprite, position, owner) {
    var frame, frameCache, frames, pixiSprite, pose, _ref;
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
      pixiSprite.animationSpeed = 0.0825;
      pixiSprite.play();
    } else {
      pixiSprite = new PIXI.Sprite(PIXI.Texture.fromFrame(sprite.name));
    }
    pixiSprite.anchor.x = pixiSprite.anchor.y = 0.5;
    pixiSprite.position.x = position.x;
    pixiSprite.position.y = position.y;
    if (owner != null) {
      pixiSprite.tint = this.playerFinder.playerMetadata[owner.playerId].color;
      console.log(pixiSprite.tint);
    }
    pixiSprite.setInteractive(true);
    this.pixiWrapper.addMiddleGroundSprite(pixiSprite, entity.id);
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
    if (robotName.indexOf("robot_4") === 0) {
      return {
        down: ["" + robotName + "_down_0", "" + robotName + "_down_1", "" + robotName + "_down_2", "" + robotName + "_down_1"],
        left: ["" + robotName + "_left_0", "" + robotName + "_left_1", "" + robotName + "_left_2", "" + robotName + "_left_1"],
        up: ["" + robotName + "_up_0", "" + robotName + "_up_1", "" + robotName + "_up_2", "" + robotName + "_up_1"],
        right: ["" + robotName + "_right_0", "" + robotName + "_right_1", "" + robotName + "_right_2", "" + robotName + "_right_1"],
        downIdle: ["" + robotName + "_down_0", "" + robotName + "_down_1", "" + robotName + "_down_2", "" + robotName + "_down_1"],
        leftIdle: ["" + robotName + "_left_0", "" + robotName + "_left_1", "" + robotName + "_left_2", "" + robotName + "_left_1"],
        upIdle: ["" + robotName + "_up_0", "" + robotName + "_up_1", "" + robotName + "_up_2", "" + robotName + "_up_1"],
        rightIdle: ["" + robotName + "_right_0", "" + robotName + "_right_1", "" + robotName + "_right_2", "" + robotName + "_right_1"]
      };
    } else {
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
    }
  };

  EntityFactory.prototype.robot = function(x, y, robotName) {
    var robot;
    console.log("robot", robotName);
    robot = this.ecs.create();
    robot.add(new C.Position({
      x: x,
      y: y
    }), ComponentRegister.get(C.Position));
    robot.add(new C.Sprite({
      name: robotName,
      framelist: this.generateRobotFrameList(robotName)
    }), ComponentRegister.get(C.Sprite));
    robot.add(new C.Controls(), ComponentRegister.get(C.Controls));
    robot.add(new C.Movement({
      vx: 0,
      vy: 0,
      speed: 15
    }), ComponentRegister.get(C.Movement));
    robot.add(new C.Wander({
      range: 50
    }), ComponentRegister.get(C.Wander));
    return robot;
  };

  EntityFactory.prototype.powerup = function(x, y, powerup_type) {
    var crystal_frames, p, powerup_frames;
    crystal_frames = ["" + powerup_type + "-crystal0", "" + powerup_type + "-crystal1", "" + powerup_type + "-crystal2", "" + powerup_type + "-crystal3", "" + powerup_type + "-crystal4", "" + powerup_type + "-crystal5", "" + powerup_type + "-crystal6", "" + powerup_type + "-crystal7"];
    powerup_frames = {
      downIdle: crystal_frames,
      down: crystal_frames
    };
    p = this.ecs.create();
    p.add(new C.Position({
      x: x,
      y: y
    }), ComponentRegister.get(C.Position));
    p.add(new C.Movement({
      vx: 0,
      vy: 0
    }), ComponentRegister.get(C.Movement));
    p.add(new C.Powerup({
      powerup_type: powerup_type
    }), ComponentRegister.get(C.Powerup));
    p.add(new C.Sprite({
      name: "" + powerup_type + "-crystal",
      framelist: powerup_frames
    }), ComponentRegister.get(C.Sprite));
    return p;
  };

  EntityFactory.prototype.mapTiles = function(seed, width, height) {
    var comp, mapTiles, prng;
    mapTiles = this.ecs.create();
    comp = new C.MapTiles({
      seed: seed,
      width: width,
      height: height
    });
    mapTiles.add(comp, ComponentRegister.get(C.MapTiles));
    prng = new ParkMillerRNG(seed);
    eachMapTile(prng, width, height, (function(_this) {
      return function(x, y, tile_set, base, feature, spare) {
        var p, sparePRNG;
        sparePRNG = new ParkMillerRNG(spare);
        if (feature === "crater") {
          p = sparePRNG.weighted_choose([["blue", 25], ["green", 25], [null, 50]]);
          if (p != null) {
            return _this.powerup(x + 32, y + 32, p);
          }
        }
      };
    })(this));
    return mapTiles;
  };

  return EntityFactory;

})();

RtsWorld = (function(_super) {
  __extends(RtsWorld, _super);

  function RtsWorld(_arg) {
    this.pixiWrapper = _arg.pixiWrapper, this.introspector = _arg.introspector;
    this.pixiWrapper || (function() {
      throw new Error("Need pixiWrapper");
    })();
    this.introspector || (function() {
      throw new Error("Need an introspector, eg, EntityInspector");
    })();
    this.playerMetadata = {};
    this.currentControls = {};
    this.commandQueue = [];
    this.randomNumberGenerator = new ParkMillerRNG((Math.random() * 1000) | 0);
    this.checksumCalculator = new ChecksumCalculator();
    this.ecs = this._setupECS(this.pixieWrapper);
    this.entityFactory = new EntityFactory(this.ecs);
    this._setupIntrospector(this.ecs, this.introspector);
    this.entityFactory.mapTiles((Math.random() * 1000) | 0, 100, 100);
  }

  RtsWorld.prototype._setupECS = function(pixieWrapper) {
    var ecs;
    ComponentRegister.register(C.Position);
    ComponentRegister.register(C.Sprite);
    ComponentRegister.register(C.Owned);
    ComponentRegister.register(C.Movement);
    ComponentRegister.register(C.Controls);
    ComponentRegister.register(C.MapTiles);
    ComponentRegister.register(C.Powerup);
    ComponentRegister.register(C.Goto);
    ComponentRegister.register(C.Wander);
    ecs = new makr.World();
    ecs.registerSystem(new WanderControlMappingSystem(this.randomNumberGenerator));
    ecs.registerSystem(new GotoSystem());
    ecs.registerSystem(new SpriteSyncSystem(this.pixiWrapper, this));
    ecs.registerSystem(new MapTilesSystem(this.pixiWrapper));
    ecs.registerSystem(new CommandQueueSystem(this.commandQueue, this));
    ecs.registerSystem(new MovementSystem());
    return ecs;
  };

  RtsWorld.prototype._setupIntrospector = function(ecs, introspector) {
    var componentClass, _i, _len, _ref, _results;
    _ref = [C.Position, C.Movement, C.Owned, C.MapTiles];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      componentClass = _ref[_i];
      _results.push(ecs.registerSystem(new EntityInspectorSystem(introspector, componentClass)));
    }
    return _results;
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
    return new C[serializedComponent.type](serializedComponent);
  };

  RtsWorld.prototype.summonRobot = function(playerId, robotType, args) {
    var robot;
    if (args == null) {
      args = {};
    }
    robot = this.entityFactory.robot(args.x, args.y, robotType);
    return robot.add(new C.Owned({
      playerId: playerId
    }), ComponentRegister.get(C.Owned));
  };

  RtsWorld.prototype.commandUnit = function(playerId, command, args) {
    if (args == null) {
      args = {};
    }
    return this.commandQueue.push({
      command: command,
      playerId: playerId,
      args: args
    });
  };

  RtsWorld.prototype.getIntrospector = function() {
    return this.introspector;
  };

  RtsWorld.prototype.playerJoined = function(playerId) {
    var _base;
    (_base = this.playerMetadata)[playerId] || (_base[playerId] = {});
    return this.playerMetadata[playerId].color = this.randomNumberGenerator.choose(PlayerColors);
  };

  RtsWorld.prototype.playerLeft = function(playerId) {
    var ent, owner, _i, _len, _ref, _results;
    console.log("Player " + playerId + " LEFT");
    _ref = this.ecs._alive;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      ent = _ref[_i];
      owner = ent.get(ComponentRegister.get(C.Owned));
      if ((owner != null) && (owner.playerId === playerId)) {
        _results.push(ent.kill());
      } else {
        _results.push(void 0);
      }
    }
    return _results;
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
    this.playerMetadata = data.playerMetadata;
    this.ecs._nextEntityID = data.nextEntityId;
    this.randomNumberGenerator.seed = data.sacredSeed;
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
      playerMetadata: this.playerMetadata,
      componentBags: componentBags,
      nextEntityId: this.ecs._nextEntityID,
      sacredSeed: this.randomNumberGenerator.seed
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

  RtsWorld.prototype.getChecksum = function() {
    return 0;
  };

  return RtsWorld;

})(SimSim.WorldBase);

module.exports = RtsWorld;


},{"../utils/checksum_calculator.coffee":7,"../utils/component_register.coffee":8,"../utils/pm_prng.coffee":9,"./components.coffee":11,"./systems/command_queue_system.coffee":14,"./systems/goto_system.coffee":15,"./systems/wander_control_mapping_system.coffee":16}],14:[function(require,module,exports){
var C, CommandQueueSystem, Commands, ComponentRegister,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ComponentRegister = require('../../utils/component_register.coffee');

C = require('../components.coffee');

CommandQueueSystem = (function(_super) {
  __extends(CommandQueueSystem, _super);

  function CommandQueueSystem(commandQueue, entityFinder) {
    this.commandQueue = commandQueue;
    this.entityFinder = entityFinder;
    makr.IteratingSystem.call(this);
  }

  CommandQueueSystem.prototype.processEntities = function() {
    var cmd, commands, _i, _len, _results;
    commands = [];
    while (cmd = this.commandQueue.shift()) {
      commands.push(cmd);
    }
    _results = [];
    for (_i = 0, _len = commands.length; _i < _len; _i++) {
      cmd = commands[_i];
      if (cmd.args.entityId != null) {
        _results.push(this._handleEntityCommand(cmd));
      } else {
        _results.push(this._handleCommand(cmd));
      }
    }
    return _results;
  };

  CommandQueueSystem.prototype._handleCommands = function(cmd) {
    var commandFn;
    commandFn = Commands[cmd.command];
    if (commandFn != null) {
      return commandFn(cmd);
    } else {
      return console.log("CommandQueueSystem: No Command defined for " + cmd.command, cmd);
    }
  };

  CommandQueueSystem.prototype._handleEntityCommand = function(cmd) {
    var commandFn, owned, targetEntity;
    targetEntity = this.entityFinder.findEntityById(cmd.args.entityId);
    owned = targetEntity.get(ComponentRegister.get(C.Owned));
    if (owned && (cmd.playerId === owned.playerId)) {
      commandFn = Commands.Entity[cmd.command];
      if (commandFn != null) {
        return commandFn(targetEntity, cmd);
      } else {
        return console.log("CommandQueueSystem: No Entity Command defined for " + cmd.command, cmd);
      }
    } else {
      return console.log("CommandQueueSystem: ILLEGAL INSTRUCTION, player " + cmd.playerId + " may not command entity " + cmd.args.entityId + " because it's owned by " + owned.playerId);
    }
  };

  return CommandQueueSystem;

})(makr.IteratingSystem);

Commands = {};

Commands.Entity = {};

Commands.Entity.march = function(entity, cmd) {
  var movement;
  movement = entity.get(ComponentRegister.get(C.Movement));
  if (cmd.args.direction === "left") {
    return movement.vx = -movement.speed;
  } else if (cmd.args.direction === "right") {
    return movement.vx = movement.speed;
  } else if (cmd.args.direction === "stop") {
    return movement.vx = 0;
  }
};

Commands.Entity.goto = function(entity, cmd) {
  var comp;
  comp = new C.Goto({
    x: cmd.args.x,
    y: cmd.args.y
  });
  return entity.add(comp, ComponentRegister.get(C.Goto));
};

module.exports = CommandQueueSystem;


},{"../../utils/component_register.coffee":8,"../components.coffee":11}],15:[function(require,module,exports){
var C, CR, GotoSystem,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CR = require('../../utils/component_register.coffee');

C = require('../components.coffee');

Vec2D.useObjects();

GotoSystem = (function(_super) {
  __extends(GotoSystem, _super);

  function GotoSystem() {
    makr.IteratingSystem.call(this);
    this.registerComponent(CR.get(C.Goto));
    this.registerComponent(CR.get(C.Position));
    this.registerComponent(CR.get(C.Movement));
  }

  GotoSystem.prototype.process = function(entity, elapsed) {
    var dx, dy, goto, magnitude, movement, position, target, velocity;
    goto = entity.get(CR.get(C.Goto));
    position = entity.get(CR.get(C.Position));
    movement = entity.get(CR.get(C.Movement));
    dx = goto.x - position.x;
    dy = goto.y - position.y;
    target = Vec2D.create(dx, dy);
    magnitude = target.magnitude();
    if (magnitude < 5) {
      entity.remove(CR.get(C.Goto));
      movement.vx = 0;
      return movement.vy = 0;
    } else {
      velocity = target.unit().multiplyByScalar(movement.speed);
      movement.vx = velocity.getX();
      return movement.vy = velocity.getY();
    }
  };

  return GotoSystem;

})(makr.IteratingSystem);

module.exports = GotoSystem;


},{"../../utils/component_register.coffee":8,"../components.coffee":11}],16:[function(require,module,exports){
var C, CR, ParkMillerRNG, WanderControlMappingSystem,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CR = require('../../utils/component_register.coffee');

C = require('../components.coffee');

ParkMillerRNG = require('../../utils/pm_prng.coffee');

WanderControlMappingSystem = (function(_super) {
  __extends(WanderControlMappingSystem, _super);

  function WanderControlMappingSystem(randomNumberGenerator) {
    this.randomNumberGenerator = randomNumberGenerator;
    makr.IteratingSystem.call(this);
    this.registerComponent(CR.get(C.Position));
    this.registerComponent(CR.get(C.Wander));
  }

  WanderControlMappingSystem.prototype.process = function(entity, elapsed) {
    var dx, dy, goto, position, range, wander;
    wander = entity.get(CR.get(C.Wander));
    position = entity.get(CR.get(C.Position));
    goto = entity.get(CR.get(C.Goto));
    if (goto == null) {
      range = wander.range;
      dx = this.randomNumberGenerator.nextInt(-range, range);
      dy = this.randomNumberGenerator.nextInt(-range, range);
      return entity.add(new C.Goto({
        x: position.x + dx,
        y: position.y + dy
      }), CR.get(C.Goto));
    }
  };

  return WanderControlMappingSystem;

})(makr.IteratingSystem);

module.exports = WanderControlMappingSystem;


},{"../../utils/component_register.coffee":8,"../../utils/pm_prng.coffee":9,"../components.coffee":11}]},{},[1])