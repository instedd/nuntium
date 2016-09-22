(function(win) {
  var scripts = document.getElementsByTagName('script'),
      len = scripts.length,
      re = /pigeonui\.js$/,
      src, nuntiumScriptSrc;

  while (len--) {
    src = scripts[len].src;
    if (src && src.match(re)) {
      nuntiumScriptSrc = src.match("https?://[^/]*")[0];
      break;
    }
  }

  win.pigeon = {
    addChannel: function(options) {
      var overlay = document.createElement("div");
      overlay.style.position = "fixed"
      overlay.style.top = 0
      overlay.style.left = 0
      overlay.style.width = "100%"
      overlay.style.height = "100%"
      overlay.style.backgroundColor = "rgba(0, 0, 0, 0.5)"
      overlay.style.zIndex = 10000
      overlay.onclick = function() {
        options.callback(null);
        document.body.removeChild(overlay);
      };

      document.body.appendChild(overlay);

      var frame = document.createElement("iframe");
      frame.style.backgroundColor = "white"
      frame.style.position = "absolute"
      frame.style.border = "0px"
      frame.style.top = "25%"
      frame.style.left = "25%"
      frame.style.height = "50%"
      frame.style.width = "50%"
      frame.src = nuntiumScriptSrc + "/pigeon/new?access_token=" + options.accessToken


      overlay.appendChild(frame)

      var listener = function(event) {
        win.removeEventListener("message", listener);
        if (event.source == frame.contentWindow && event.origin == nuntiumScriptSrc) {
          options.callback(event.data);
          document.body.removeChild(overlay);
        }
      }

      win.addEventListener("message", listener, false);
    }
  }
})(window);
