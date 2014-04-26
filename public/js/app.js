(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var GameRunner, KeyboardController, PixiWrapper, RtsWorld, StopWatch, buildKeyboardController, buildPixiWrapper, buildSimulation, buildStopWatch, getMeta, setupStats, _copyData;

RtsWorld = require('./rts_world.coffee');

StopWatch = require('./stop_watch.coffee');

KeyboardController = require('./keyboard_controller.coffee');

PixiWrapper = require('./pixi_wrapper.coffee');

GameRunner = require('./game_runner.coffee');

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
  useHttps = getMeta('use-https') === "true";
  scheme = useHttps ? "https" : "http";
  this._gameConfig = {
    stageWidth: 800,
    stageHeight: 600,
    imageAssets: ["images/bunny.png"],
    simSimConnection: {
      url: "" + scheme + "://" + window.location.hostname,
      secure: useHttps
    }
  };
  return this._gameConfig;
};

window.local = {
  vars: {},
  gameRunner: null
};

window.onload = function() {
  var gameConfig, pixiWrapper, stats;
  gameConfig = window.gameConfig();
  stats = setupStats();
  pixiWrapper = buildPixiWrapper({
    width: gameConfig.stageWidth,
    height: gameConfig.stageHeight,
    assets: gameConfig.imageAssets
  });
  pixiWrapper.appendViewTo(document.body);
  return pixiWrapper.loadAssets(function() {
    var gameRunner, keyboardController, simulation, stopWatch, world;
    world = new RtsWorld({
      pixiWrapper: pixiWrapper
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
    window.local.gameRunner = gameRunner;
    return gameRunner.start();
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
    world: opts.world
  });
};

setupStats = function() {
  var container, stats;
  container = document.createElement("div");
  document.body.appendChild(container);
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


},{"./game_runner.coffee":3,"./keyboard_controller.coffee":4,"./pixi_wrapper.coffee":5,"./rts_world.coffee":6,"./stop_watch.coffee":7}],2:[function(require,module,exports){
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


},{}],4:[function(require,module,exports){
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


},{}],5:[function(require,module,exports){
var PixiWrapper;

PixiWrapper = (function() {
  function PixiWrapper(opts) {
    this.stage = new PIXI.Stage(0xDDDDDD, true);
    this.renderer = PIXI.autoDetectRenderer(opts.width, opts.height, void 0, false);
    this.loader = new PIXI.AssetLoader(opts.assets);
  }

  PixiWrapper.prototype.appendViewTo = function(el) {
    return el.appendChild(this.renderer.view);
  };

  PixiWrapper.prototype.loadAssets = function(callback) {
    this.loader.onComplete = callback;
    return this.loader.load();
  };

  PixiWrapper.prototype.render = function() {
    return this.renderer.render(this.stage);
  };

  return PixiWrapper;

})();

module.exports = PixiWrapper;


},{}],6:[function(require,module,exports){
var BUNNY_VEL, ChecksumCalculator, HalfPI, RtsWorld, fixFloat,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ChecksumCalculator = require('./checksum_calculator.coffee');

fixFloat = SimSim.Util.fixFloat;

HalfPI = Math.PI / 2;

BUNNY_VEL = 3;

RtsWorld = (function(_super) {
  __extends(RtsWorld, _super);

  function RtsWorld(opts) {
    if (opts == null) {
      opts = {};
    }
    this.checksumCalculator = new ChecksumCalculator();
    this.pixiWrapper = opts.pixiWrapper || (function() {
      throw new Error("Need opts.pixiWrapper");
    })();
    this.data = this.defaultData();
    this.gameObjects = {
      bunnies: {}
    };
    this.syncNeeded = true;
  }

  RtsWorld.prototype.defaultData = function() {
    return {
      nextId: 0,
      players: {},
      bunnies: {}
    };
  };

  RtsWorld.prototype.playerJoined = function(playerId) {
    var bunnyId;
    bunnyId = "Bunny" + (this.nextId());
    this.data.bunnies[bunnyId] = {
      x: 400,
      y: 200,
      vx: 0,
      vy: 0
    };
    this.data.players[playerId] = {
      bunnyId: bunnyId,
      controls: {
        up: false,
        down: false,
        left: false,
        right: false
      }
    };
    this.syncNeeded = true;
    return console.log("Player " + playerId + " JOINED, @data is now", this.data);
  };

  RtsWorld.prototype.playerLeft = function(playerId) {
    var bunnyId;
    if (bunnyId = this.data.players[playerId].bunnyId) {
      delete this.data.bunnies[bunnyId];
    }
    delete this.data.players[playerId];
    this.syncNeeded = true;
    return console.log("Player " + playerId + " LEFT, @data is now", this.data);
  };

  RtsWorld.prototype.theEnd = function() {
    this.resetData();
    return console.log("THE END");
  };

  RtsWorld.prototype.step = function(dt) {
    this.syncDataToGameObjects();
    this.applyControls();
    this.moveBunnies();
    return this.moveSprites();
  };

  RtsWorld.prototype.setData = function(data) {
    this.resetData();
    this.data = data;
    return this.syncNeeded = true;
  };

  RtsWorld.prototype.resetData = function() {
    this.data = this.defaultData();
    this.syncNeeded = true;
    return this.syncDataToGameObjects();
  };

  RtsWorld.prototype.getData = function() {
    return this.data;
  };

  RtsWorld.prototype.getChecksum = function() {
    return this.checksumCalculator.calculate(JSON.stringify(this.getData()));
  };

  RtsWorld.prototype.updateControl = function(id, action, value) {
    return this.data.players[id].controls[action] = value;
  };

  RtsWorld.prototype.moveBunnies = function() {
    var bunny, bunnyId, _ref, _results;
    _ref = this.data.bunnies;
    _results = [];
    for (bunnyId in _ref) {
      bunny = _ref[bunnyId];
      bunny.x += bunny.vx;
      _results.push(bunny.y += bunny.vy);
    }
    return _results;
  };

  RtsWorld.prototype.moveSprites = function() {
    var bunny, bunnyId, obj, _ref, _results;
    _ref = this.gameObjects.bunnies;
    _results = [];
    for (bunnyId in _ref) {
      obj = _ref[bunnyId];
      bunny = this.data.bunnies[bunnyId];
      obj.sprite.position.x = bunny.x;
      _results.push(obj.sprite.position.y = bunny.y);
    }
    return _results;
  };

  RtsWorld.prototype.applyControls = function() {
    var bunny, con, player, playerId, _ref, _results;
    _ref = this.data.players;
    _results = [];
    for (playerId in _ref) {
      player = _ref[playerId];
      con = player.controls;
      bunny = this.data.bunnies[player.bunnyId];
      if (con.up) {
        bunny.vy = -BUNNY_VEL;
      } else if (con.down) {
        bunny.vy = BUNNY_VEL;
      } else {
        bunny.vy = 0;
      }
      if (con.left) {
        _results.push(bunny.vx = -BUNNY_VEL);
      } else if (con.right) {
        _results.push(bunny.vx = BUNNY_VEL);
      } else {
        _results.push(bunny.vx = 0);
      }
    }
    return _results;
  };

  RtsWorld.prototype.nextId = function() {
    var nid;
    nid = this.data.nextId;
    this.data.nextId += 1;
    return nid;
  };

  RtsWorld.prototype.syncDataToGameObjects = function() {
    var bunnyData, bunnyId, e, obj, _ref, _ref1, _results;
    if (!this.syncNeeded) {
      return;
    }
    this.syncNeeded = false;
    _ref = this.data.bunnies;
    for (bunnyId in _ref) {
      bunnyData = _ref[bunnyId];
      if (!this.gameObjects.bunnies[bunnyId]) {
        try {
          obj = {};
          obj.sprite = this.makeBoxSprite(bunnyData);
          this.pixiWrapper.stage.addChild(obj.sprite);
          this.gameObjects.bunnies[bunnyId] = obj;
        } catch (_error) {
          e = _error;
          console.log("OOPS adding box " + bunnyId, e);
        }
      }
    }
    _ref1 = this.gameObjects.bunnies;
    _results = [];
    for (bunnyId in _ref1) {
      obj = _ref1[bunnyId];
      if (!this.data.bunnies[bunnyId]) {
        try {
          this.pixiWrapper.stage.removeChild(obj.sprite);
          _results.push(delete this.gameObjects.bunnies[bunnyId]);
        } catch (_error) {
          e = _error;
          _results.push(console.log("OOPS removing box " + bunnyId, e));
        }
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  RtsWorld.prototype.makeBoxSprite = function(boxData) {
    var box, size;
    size = 1;
    box = new PIXI.Sprite(PIXI.Texture.fromFrame("images/bunny.png"));
    box.i = 0;
    box.anchor.x = box.anchor.y = 0.5;
    box.scale.x = size;
    box.scale.y = size;
    return box;
  };

  return RtsWorld;

})(SimSim.WorldBase);

module.exports = RtsWorld;


},{"./checksum_calculator.coffee":2}],7:[function(require,module,exports){
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