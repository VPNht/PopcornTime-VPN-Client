var gui, isDebug, preventDefault, version, win;

gui = require('nw.gui');

version = '0.1.0';

win = gui.Window.get();

isDebug = true;

win.title = gui.App.manifest.name + ' VPN ' + version;

win.focus();

win.on("new-win-policy", function(frame, url, policy) {
  return policy.ignore();
});

preventDefault = function(e) {
  return e.preventDefault();
};

window.addEventListener("dragover", preventDefault, false);

window.addEventListener("drop", preventDefault, false);

window.addEventListener("dragstart", preventDefault, false);

$(function() {
  $('#windowControlMinimize').on('click', function() {
    return win.minimize();
  });
  return $('#windowControlClose').on('click', function() {
    return win.close();
  });
});

var Auth, request;

request = require('request');

Auth = (function() {
  function Auth() {}

  Auth.logout = function() {
    window.App.advsettings.set('vpnUsername', '');
    window.App.advsettings.set('vpnPassword', '');
    hideAll();
    return $('.login').show();
  };

  Auth.login = function() {
    var auth, password, username;
    username = $('#username').val();
    password = $('#password').val();
    if (username === '' || password === '') {
      return $('#invalidLogin').show();
    } else {
      auth = "Basic " + new Buffer(username + ":" + password).toString("base64");
      return request({
        url: 'https://vpn.ht/servers',
        headers: {
          Authorization: auth
        }
      }, function(error, response, body) {
        if (response.statusCode === 401) {
          return $('#invalidLogin').show();
        } else {
          if (window) {
            window.App.advsettings.set('vpnUsername', username);
            window.App.advsettings.set('vpnPassword', password);
            window.vpn = JSON.parse(body);
            Details.open();
            return checkStatus();
          }
        }
      });
    }
  };

  return Auth;

})();

$(function() {
  $('#username').keypress(function(e) {
    if (e.which === 13) {
      return Auth.login();
    }
  });
  $('#password').keypress(function(e) {
    if (e.which === 13) {
      return Auth.login();
    }
  });
  $('#login').on('click', function() {
    return Auth.login();
  });
  $('#logoutBtn').on('click', function() {
    return Auth.logout();
  });
  $('#connectBtn').on('click', function() {
    return App.VPN.connect($('#protocol').val());
  });
  $('#disconnectBtn').on('click', function() {
    return App.VPN.disconnect();
  });
  $('#cancelBtn').on('click', function() {
    return App.VPN.disconnect();
  });
  $('#createAccount').on('click', function() {
    return gui.Shell.openExternal('https://vpn.ht/popcorntime');
  });
  $('#helpBtn').on('click', function() {
    return gui.Shell.openExternal('https://vpnht.zendesk.com/hc/en-us');
  });
  $('#forgotPassword').on('click', function() {
    return gui.Shell.openExternal('https://vpn.ht/forgot');
  });
  return $('#showDetail').on('click', function() {
    return Details.open();
  });
});

var Connected, _;

_ = require('underscore');

Connected = (function() {
  function Connected() {}

  Connected.open = function() {
    hideAll();
    return $('.status').show();
  };

  return Connected;

})();

var Details, _;

_ = require('underscore');

Details = (function() {
  function Details() {}

  Details.open = function() {
    var protocols, servers;
    hideAll();
    $('.details').show();
    $('.usernameLabel').html(window.vpn.user.username);
    if (process.platform === "darwin") {
      protocols = ['openvpn'];
    } else if (process.platform === "win32") {
      protocols = ['pptp', 'openvpn'];
    } else if (process.platform === "linux") {
      protocols = ['openvpn'];
    }
    $('#protocol').empty();
    $('#servers').empty();
    _.each(protocols, function(protocol) {
      return $('#protocol').append('<option value="' + protocol + '">' + protocol.toUpperCase() + '</option>');
    });
    servers = _.first(window.vpn.servers);
    return _.each(servers, function(server) {
      return $('#servers').append('<option value="' + server + '">' + server.toUpperCase() + '</option>');
    });
  };

  return Details;

})();

var autoLogin, copy, copyToLocation, createReadStream, downloadFileToLocation, downloadTarballAndExtract, hideAll;

hideAll = function() {
  $('.login').hide();
  $('.status').hide();
  $('.installScript').hide();
  $('.details').hide();
  $('.connecting').hide();
  return $('.loading').hide();
};

autoLogin = function() {
  if (window.App && window.App.settings.vpnUsername && window.App.settings.vpnPassword) {
    $('#username').val(window.App.settings.vpnUsername);
    $('#password').val(window.App.settings.vpnPassword);
    return Auth.login();
  }
};

downloadTarballAndExtract = function(url) {
  var defer, stream, tempPath;
  defer = Q.defer();
  tempPath = temp.mkdirSync("popcorntime-openvpn-");
  stream = tar.Extract({
    path: tempPath
  });
  stream.on("end", function() {
    defer.resolve(tempPath);
  });
  stream.on("error", function() {
    defer.resolve(false);
  });
  createReadStream({
    url: url
  }, function(requestStream) {
    requestStream.pipe(zlib.createGunzip()).pipe(stream);
  });
  return defer.promise;
};

downloadFileToLocation = function(url, name) {
  var defer, stream, tempPath;
  defer = Q.defer();
  tempPath = temp.mkdirSync("popcorntime-openvpn-");
  tempPath = path.join(tempPath, name);
  stream = fs.createWriteStream(tempPath);
  stream.on("finish", function() {
    defer.resolve(tempPath);
  });
  stream.on("error", function() {
    defer.resolve(false);
  });
  createReadStream({
    url: url
  }, function(requestStream) {
    requestStream.pipe(stream);
  });
  return defer.promise;
};

createReadStream = function(requestOptions, callback) {
  return callback(request.get(requestOptions));
};

copyToLocation = function(targetFilename, fromDirectory) {
  var defer;
  defer = Q.defer();
  mv(fromDirectory, targetFilename, function(err) {
    return defer.resolve(err);
  });
  return defer.promise;
};

copy = function(source, target, cb) {
  var cbCalled, done, rd, wr;
  done = function(err) {
    var cbCalled;
    if (!cbCalled) {
      cb(err);
      cbCalled = true;
    }
  };
  cbCalled = false;
  rd = fs.createReadStream(source);
  rd.on("error", function(err) {
    done(err);
  });
  wr = fs.createWriteStream(target);
  wr.on("error", function(err) {
    done(err);
  });
  wr.on("close", function(ex) {
    done();
  });
  rd.pipe(wr);
};

var InstallScript, _;

_ = require('underscore');

InstallScript = (function() {
  function InstallScript() {}

  InstallScript.open = function() {
    hideAll();
    return $('.installScript').hide();
  };

  return InstallScript;

})();

var runas;

runas = function(cmd, args, callback) {
  var child, exec;
  exec = require("child_process").exec;
  if (process.platform === "linux") {
    return child = exec("which gksu", function(error, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);
      console.log(error);
      if (stdout) {
        cmd = stdout + " " + cmd + " " + args.join(" ");
        return child = exec(cmd, function(error, stdout, stderr) {
          if (error !== null) {
            return callback(false);
          }
          return callback(true);
        });
      } else {
        return child = exec("which kdesu", function(error, stdout, stderr) {
          if (stdout) {
            cmd = stdout + " " + cmd + " " + args.join(" ");
            return child = exec(cmd, function(error, stdout, stderr) {
              if (error !== null) {
                return callback(false);
              }
              return callback(true);
            });
          } else {
            InstallScript.open();
            return callback(false);
          }
        });
      }
    });
  } else if (process.platform === "win32") {
    cmd = path.join(getInstallPathOpenVPN(), 'runas.cmd') + " " + cmd + " " + args.join(" ");
    return child = exec(cmd, function(error, stdout, stderr) {
      if (error !== null) {
        return callback(false);
      }
      return callback(true);
    });
  } else {
    cmd = "osascript -e 'do shell script \"" + cmd + " " + args.join(" ") + " \" with administrator privileges'";
    return child = exec(cmd, function(error, stdout, stderr) {
      console.log(stdout);
      if (error !== null) {
        return callback(false);
      }
      return callback(true);
    });
  }
};

var checkStatus, getStatus, monitorStatus, request, timerMonitor;

request = require('request');

timerMonitor = false;

getStatus = function(callback) {
  return request({
    url: 'https://vpn.ht/status?json'
  }, function(error, response, body) {
    if (error) {
      return callback(false);
    }
    if (response && response.statusCode === 200) {
      body = JSON.parse(body);
      return callback(body);
    } else {
      return callback(false);
    }
  });
};

checkStatus = function(type) {
  type = type || 'c';
  console.log('monitoring status....', type);
  return getStatus(function(data) {
    if (data) {
      win.vpnStatus = data;
      console.log(data.connected);
      if (type === 'c' && data.connected === true) {
        window.App.VPNClient.setVPNStatus(true);
        Connected.open();
        if (timerMonitor) {
          return window.clearTimeout(timerMonitor);
        }
      } else if (type === 'd' && data.connected === false) {
        window.App.VPNClient.setVPNStatus(false);
        Details.open();
        if (timerMonitor) {
          return window.clearTimeout(timerMonitor);
        }
      }
    }
  });
};

monitorStatus = function(type) {
  return timerMonitor = setInterval((function() {
    return checkStatus(type);
  }), 2500);
};

var Q, VPN, fs, mv, path, request, tar, temp, zlib;

request = require("request");

Q = require("q");

tar = require("tar");

temp = require("temp");

zlib = require("zlib");

mv = require("mv");

fs = require("fs");

path = require("path");

VPN = function() {
  if (!(this instanceof VPN)) {
    return new VPN();
  }
  this.running = false;
  return this.ip = false;
};

temp.track();

VPN.prototype.isInstalled = function() {
  var installed;
  if (haveBinariesOpenVPN()) {
    installed = window.App.advsettings.get("vpn");
    if (installed) {
      return true;
    } else {
      return false;
    }
  }
  return false;
};

VPN.prototype.isDisabled = function() {
  var disabled;
  disabled = window.App.advsettings.get("vpnDisabledPerm");
  if (disabled) {
    return true;
  } else {
    return false;
  }
};

VPN.prototype.isRunning = function() {
  var defer, self;
  defer = Q.defer();
  self = this;
  getStatus(function(data) {
    if (data) {
      return defer.resolve(data.connected);
    }
  });
  return defer.promise;
};

VPN.prototype.connect = function(protocol) {
  var ovpnEnabled, pptpEnabled, self;
  self = this;
  hideAll();
  $('.connecting').show();
  monitorStatus();
  if (protocol === 'pptp') {
    pptpEnabled = window.App.advsettings.get("vpnPPTP");
    if (pptpEnabled) {
      return this.connectPPTP();
    } else {
      console.log('install');
      return this.installPPTP().then(function() {
        console.log('connect');
        return self.connectPPTP();
      });
    }
  } else {
    ovpnEnabled = window.App.advsettings.get("vpnOVPN");
    if (ovpnEnabled && haveBinariesOpenVPN()) {
      return this.connectOpenVPN();
    } else {
      console.log('install');
      return this.installOpenVPN().then(function() {
        console.log('connect');
        return self.connectOpenVPN();
      });
    }
  }
};

VPN.prototype.disconnect = function() {
  var self;
  hideAll();
  $('.loading').show();
  self = this;
  if (this.running && this.protocol === 'pptp') {
    monitorStatus('d');
    return self.disconnectPPTP();
  } else if (this.running && this.protocol === 'openvpn') {
    monitorStatus('d');
    return self.disconnectOpenVPN();
  } else {
    return self.disconnectOpenVPN().then(function() {
      return self.disconnectPPTP().then(function() {
        return monitorStatus('d');
      });
    });
  }
};

var exec;

exec = require("child_process").exec;

VPN.prototype.installPPTP = function() {
  var configFile, defer;
  defer = Q.defer();
  switch (process.platform) {
    case "win32":
      configFile = "https://client.vpn.ht/config/pptp.txt";
      downloadFileToLocation(configFile, "pptp.txt").then(function(temp) {
        var child, rasphone;
        rasphone = path.join(process.env.APPDATA, "Microsoft", "Network", "Connections", "Pbk", "rasphone.pbk");
        return child = exec("type " + temp + " >> " + rasphone, function(error, stdout, stderr) {
          if (error) {
            console.log(err);
            return defer.resolve(false);
          } else {
            window.App.advsettings.set("vpnPPTP", true);
            return defer.resolve(true);
          }
        });
      });
      break;
    default:
      defer.resolve(false);
  }
  return defer.promise;
};

VPN.prototype.connectPPTP = function() {
  var authString, child, defer, rasdial, self;
  self = this;
  defer = Q.defer();
  switch (process.platform) {
    case "win32":
      rasdial = path.join(process.env.SystemDrive, 'Windows', 'System32', 'rasdial.exe');
      authString = window.App.settings.vpnUsername + " " + window.App.settings.vpnPassword;
      child = exec(rasdial + " vpnht " + authString, function(error, stdout, stderr) {
        if (error) {
          console.log(err);
          return defer.resolve(false);
        } else {
          console.log(stdout);
          self.protocol = 'pptp';
          self.running = true;
          return defer.resolve(true);
        }
      });
      break;
    default:
      defer.resolve(false);
  }
  return defer.promise;
};

VPN.prototype.disconnectPPTP = function() {
  var child, defer, rasdial, self;
  self = this;
  defer = Q.defer();
  switch (process.platform) {
    case "win32":
      rasdial = path.join(process.env.SystemDrive, 'Windows', 'System32', 'rasdial.exe');
      child = exec(rasdial + " /disconnect", function(error, stdout, stderr) {
        if (error) {
          console.log(err);
          return defer.resolve(false);
        } else {
          console.log(stdout);
          self.running = false;
          return defer.resolve(true);
        }
      });
      break;
    default:
      defer.resolve(false);
  }
  return defer.promise;
};

var exec, getInstallPathOpenVPN, getPidOpenVPN, haveBinariesOpenVPN;

exec = require("child_process").exec;

VPN.prototype.installOpenVPN = function() {
  var arch, defer, self, tarball;
  self = this;
  defer = Q.defer();
  switch (process.platform) {
    case "darwin":
      tarball = "https://client.vpn.ht/bin/openvpn-mac.tar.gz";
      downloadTarballAndExtract(tarball).then(function(temp) {
        return copyToLocation(getInstallPathOpenVPN(), temp).then(function(err) {
          return self.downloadOpenVPNConfig().then(function(err) {
            window.App.advsettings.set("vpnOVPN", true);
            return defer.resolve();
          });
        });
      });
      break;
    case "linux":
      arch = (process.arch === "ia32" ? "x86" : process.arch);
      tarball = "https://client.vpn.ht/bin/openvpn-linux-" + arch + ".tar.gz";
      downloadTarballAndExtract(tarball).then(function(temp) {
        return copyToLocation(getInstallPathOpenVPN(), temp).then(function(err) {
          return self.downloadOpenVPNConfig().then(function(err) {
            window.App.advsettings.set("vpnOVPN", true);
            return defer.resolve();
          });
        });
      });
      break;
    case "win32":
      arch = (process.arch === "ia32" ? "x86" : process.arch);
      tarball = "https://client.vpn.ht/bin/openvpn-win-" + arch + ".tar.gz";
      downloadTarballAndExtract(tarball).then(function(temp) {
        return copyToLocation(getInstallPathOpenVPN(), temp).then(function(err) {
          return self.downloadOpenVPNConfig().then(function(err) {
            var args, openvpnInstall;
            args = ["/S", "/SELECT_TAP=1", "/SELECT_SERVICE=1", "/SELECT_SHORTCUTS=1", "/SELECT_OPENVPNGUI=1", "/D=" + getInstallPathOpenVPN('service')];
            openvpnInstall = path.join(getInstallPathOpenVPN(), 'openvpn-install.exe');
            return runas(openvpnInstall, args, function(success) {
              var timerCheckDone;
              return timerCheckDone = setInterval((function() {
                var haveBin;
                haveBin = haveBinariesOpenVPN();
                console.log(haveBin);
                if (haveBin) {
                  window.App.advsettings.set("vpnOVPN", true);
                  window.clearTimeout(timerCheckDone);
                  return defer.resolve();
                }
              }), 1000);
            });
          });
        });
      });
  }
  return defer.promise;
};

VPN.prototype.downloadOpenVPNConfig = function() {
  var configFile, e;
  try {
    if (!fs.existsSync(getInstallPathOpenVPN())) {
      fs.mkdirSync(getInstallPathOpenVPN());
    }
  } catch (_error) {
    e = _error;
    console.log(e);
  }
  configFile = "https://client.vpn.ht/config/vpnht.ovpn";
  return downloadFileToLocation(configFile, "config.ovpn").then(function(temp) {
    return copyToLocation(path.resolve(getInstallPathOpenVPN(), "vpnht.ovpn"), temp);
  });
};

VPN.prototype.disconnectOpenVPN = function() {
  var defer, netBin, self;
  defer = Q.defer();
  self = this;
  if (!this.running) {
    defer.resolve();
  }
  if (process.platform === "win32") {
    netBin = path.join(process.env.SystemDrive, "Windows", "System32", "net.exe");
    runas(netBin, ["stop", "VPNHTService"], function(success) {
      self.running = false;
      console.log("openvpn stoped");
      return defer.resolve();
    });
  } else {
    getPidOpenVPN().then(function(pid) {
      if (pid) {
        runas("kill", ["-9", pid], function(success) {
          var e;
          try {
            fs.unlinkSync(path.join(getInstallPathOpenVPN(), "vpnht.pid"));
          } catch (_error) {
            e = _error;
            console.log(e);
          }
          self.running = false;
          console.log("openvpn stoped");
          return defer.resolve();
        });
      } else {
        console.log("no pid found");
        self.running = false;
        defer.reject("no_pid_found");
      }
    });
  }
  return defer.promise;
};

VPN.prototype.connectOpenVPN = function() {
  var defer, fs, self, tempPath;
  defer = Q.defer();
  fs = require("fs");
  self = this;
  tempPath = temp.mkdirSync("popcorntime-vpnht");
  tempPath = path.join(tempPath, "o1");
  fs.writeFile(tempPath, window.App.settings.vpnUsername + "\n" + window.App.settings.vpnPassword, function(err) {
    var args, e, newConfig, openvpn, vpnConfig;
    if (err) {
      return defer.reject(err);
    } else {
      vpnConfig = path.resolve(getInstallPathOpenVPN(), "vpnht.ovpn");
      if (fs.existsSync(vpnConfig)) {
        args = ["--daemon", "--writepid", path.join(getInstallPathOpenVPN(), "vpnht.pid"), "--log-append", path.join(getInstallPathOpenVPN(), "vpnht.log"), "--config", vpnConfig, "--auth-user-pass", tempPath];
        if (process.platform === "linux") {
          args = ["--daemon", "--writepid", path.join(getInstallPathOpenVPN(), "vpnht.pid"), "--log-append", path.join(getInstallPathOpenVPN(), "vpnht.log"), "--dev", "tun0", "--config", vpnConfig, "--auth-user-pass", tempPath];
        }
        if (process.platform === "win32") {
          newConfig = path.resolve(getInstallPathOpenVPN('service'), "config", "openvpn.ovpn");
          return copy(vpnConfig, newConfig, function(err) {
            if (err) {
              console.log(err);
            }
            return fs.appendFile(newConfig, "\r\nauth-user-pass " + tempPath.replace(/\\/g, "\\\\"), function(err) {
              var netBin;
              netBin = path.join(process.env.SystemDrive, "Windows", "System32", "net.exe");
              return runas(netBin, ['start', 'VPNHTService'], function(success) {
                self.running = true;
                self.protocol = 'openvpn';
                console.log("openvpn launched");
                return defer.resolve();
              });
            });
          });
        } else {
          openvpn = path.resolve(getInstallPathOpenVPN(), "openvpn");
          if (fs.existsSync(openvpn)) {
            try {
              if (fs.existsSync(path.join(getInstallPathOpenVPN(), "vpnht.pid"))) {
                fs.unlinkSync(path.join(getInstallPathOpenVPN(), "vpnht.pid"));
              }
            } catch (_error) {
              e = _error;
              console.log(e);
            }
            return runas(openvpn, args, function(success) {
              self.running = true;
              self.protocol = 'openvpn';
              return defer.resolve();
            });
          }
        }
      } else {
        return defer.reject("openvpn_config_not_found");
      }
    }
  });
  return defer.promise;
};

haveBinariesOpenVPN = function() {
  switch (process.platform) {
    case "darwin":
    case "linux":
      return fs.existsSync(path.resolve(getInstallPathOpenVPN(), "openvpn"));
    case "win32":
      return fs.existsSync(path.resolve(getInstallPathOpenVPN('service'), "bin", "openvpn.exe"));
    default:
      return false;
  }
};

getPidOpenVPN = function() {
  var defer;
  defer = Q.defer();
  fs.readFile(path.join(getInstallPathOpenVPN(), "vpnht.pid"), "utf8", function(err, data) {
    if (err) {
      defer.resolve(false);
    } else {
      defer.resolve(data.trim());
    }
  });
  return defer.promise;
};

getInstallPathOpenVPN = function(type) {
  type = type || false;
  if (type === 'service') {
    return path.join(process.env.USERPROFILE, 'vpnht');
  } else {
    return path.join(process.cwd(), "openvpnht");
  }
};

var menu;

if (isDebug) {
  win.showDevTools();
  menu = new gui.Menu({
    type: 'menubar'
  });
  menu.append(new gui.MenuItem({
    label: 'Tools',
    submenu: new gui.Menu()
  }));
  menu.items[0].submenu.append(new gui.MenuItem({
    label: 'Developer Tools',
    click: function() {
      return win.showDevTools();
    }
  }));
  menu.items[0].submenu.append(new gui.MenuItem({
    label: "Reload ignoring cache",
    click: function() {
      return win.reloadIgnoringCache();
    }
  }));
  win.menu = menu;
}
