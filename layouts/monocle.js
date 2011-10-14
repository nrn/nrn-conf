/**
 * This is a hot loadable layout for nwm. See module.exports
 * at end of the file for details.
 *
 * Monocle (a.k.a. fullscreen)
 *
 *  +---------------------+ +---------------------+
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  +---------------------+ +---------------------+
 *        2 windows               3 windows
 *
 *  +---------------------+ +---------------------+
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  |                     | |                     |
 *  +---------------------+ +---------------------+
 *        4 windows               5 windows
 */

function monocle(workspace){
  var windows = workspace.visible();
  var screen = workspace.monitor;
  var window_ids = Object.keys(windows);
  if(window_ids.length < 1) {
    return;
  }
  var mainId = workspace.mainWindow;
  windows[mainId].move(screen.x, screen.y);
  windows[mainId].resize(screen.width, screen.height);
  // remove from visible
  window_ids = window_ids.filter(function(id) { return (id != mainId); });
  window_ids.forEach(function(id, index) {
    windows[id].hide();
  });
}

// Hot loading works like this:
// You export a callback function, which gets called every time
// a hot load needs to occur.
// The function gets the running instance of nwm, and does it's thing
// e.g. adds a new layout etc.
module.exports = function(nwm) {
  nwm.addLayout('monocle', monocle);
};
