//= require jquery

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
      var overlay = $("<div>")
        .css({
          position: "fixed",
          top: 0,
          left: 0,
          width: "100%",
          height: "100%",
          backgroundColor: "rgba(0, 0, 0, 0.5)",
          zIndex: 10000
        })
        .click(function() {
          options.callback(null);
          document.body.removeChild(overlay);
        })[0];
      document.body.appendChild(overlay);

      var frame = $("<iframe>")
        .attr("src", nuntiumScriptSrc + "/pigeon/new?access_token=" + options.accessToken)
        .css({
          backgroundColor: "white",
          position: "absolute",
          border: "0px",
          top: "25%",
          left: "25%",
          height: "50%",
          width: "50%"
        })[0]
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
