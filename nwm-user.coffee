# modules
wm = require('nwm')
NWM = wm.NWM
XK = wm.keysymdef
Xh = wm.Xh
child_process = require('child_process')

# instantiate nwm and configure it
nwm = new NWM()

# load layouts
layouts = wm.layouts
nwm.addLayout('flexible', require(__dirname+'/layouts/flexible.js'))
nwm.addLayout('monocle', layouts.monocle)
nwm.addLayout('wide', layouts.wide)

# convinience functions for writing the keyboard shortcuts
currentMonitor = ->
  nwm.monitors.get(nwm.monitors.current)


moveToMonitor = (window, currentMonitor, otherMonitorId) ->
  if window
    window.monitor = otherMonitorId
    # set the workspace to the current workspace on that monitor
    otherMonitor = nwm.monitors.get(otherMonitorId)
    window.workspace = otherMonitor.workspaces.current
    # rearrange both monitors
    currentMonitor.workspaces.get(currentMonitor.workspaces.current).rearrange()
    otherMonitor.workspaces.get(otherMonitor.workspaces.current).rearrange()

resizeWorkspace = (increment) ->
  workspace = currentMonitor().currentWorkspace()
  workspace.setMainWindowScale(workspace.getMainWindowScale() + increment)
  workspace.rearrange()

changeWorkspace = (increment) ->
  monitor = currentMonitor()
  next = monitor.workspaces.current + increment
  if next < 0 then next = 19
  if next > 19 then next = 0
  monitor.go(next)

# KEYBOARD SHORTCUTS
# Change the base modifier to your liking e.g. Xh.Mod4Mask if you just want to use the meta key without Ctrl
baseModifier = Xh.Mod4Mask # Win key

if ( process.env.DISPLAY && process.env.DISPLAY == ':1' )
  baseModifier = Xh.Mod4Mask|Xh.ControlMask # Win + Ctrl


keyboard_shortcuts = [
  {
    key: [1, 2, 3, 4, 5, 6, 7, 8, 9, 0] # number keys are used to move between screens
    callback: (event) ->
      currentMonitor().go(String.fromCharCode(event.keysym))
  }
  {
    key: [1, 2, 3, 4, 5, 6, 7, 8, 9, 0] # with shift, move windows between workspaces
    modifier: [ 'shift' ]
    callback: (event) ->
      monitor = currentMonitor()
      monitor.windowTo(monitor.focused_window, String.fromCharCode(event.keysym))
  }
  {
    key: ['Left', 'Page_Up'] # meta+left and meta+right key for switching workspaces
    callback: ->
      changeWorkspace(-1)
  }
  {
    key: ['Right', 'Page_Down'] # meta Page up and meta Page down should go through the workspaces
    callback: ->
      changeWorkspace(1)
  }
  {
    key: 'Return' # enter key launches sakura
    modifier: [ 'shift' ]
    callback: (event) ->
      child_process.spawn('sakura', [], { env: process.env })
  }
  {
    key: 'c' # c key closes the current window
    modifier: [ 'shift' ]
    callback: (event) ->
      monitor = currentMonitor()
      monitor.focused_window && nwm.wm.killWindow(monitor.focused_window)
  }
  {
    key: 'space' # space switches between layout modes
    callback: (event) ->
      monitor = currentMonitor()
      workspace = monitor.currentWorkspace()
      workspace.layout = nwm.nextLayout(workspace.layout)
      # monocle hides windows in the current workspace, so unhide them
      monitor.go(monitor.workspaces.current)
      workspace.rearrange()
  }
  {
    key: ['h', 'F10'] # shrink master area
    callback: (event) ->
      resizeWorkspace(-5)
  }
  {
    key: ['l', 'F11'] # grow master area
    callback: (event) ->
      resizeWorkspace(+5)
  }
  {
    key: 'Tab' # tab makes the current window the main window
    callback: (event) ->
      monitor = currentMonitor()
      workspace = monitor.currentWorkspace()
      workspace.mainWindow = monitor.focused_window
      workspace.rearrange()
  }
  {
    key: 'comma' # moving windows between monitors
    modifier: [ 'shift' ]
    callback: (event) ->
      monitor = currentMonitor()
      window = nwm.windows.get(monitor.focused_window)
      if window  # empty if no windows
        moveToMonitor(window, monitor, nwm.monitors.next(window.monitor))
  }
  {
    key: 'period' # moving windows between monitors
    modifier: [ 'shift' ]
    callback: (event) ->
      monitor = currentMonitor()
      window = nwm.windows.get(monitor.focused_window)
      if window  # empty if no windows
        moveToMonitor(window, monitor, nwm.monitors.prev(window.monitor))
  }
  {
    key: 'j' # moving focus
    callback: ->
      monitor = currentMonitor()
      if monitor.focused_window && nwm.windows.exists(monitor.focused_window)
        previous = nwm.windows.prev(monitor.focused_window)
        window = nwm.windows.get(previous)
        console.log('Current', monitor.focused_window, 'previous', window.id)
        monitor.focused_window = window.id
        nwm.wm.focusWindow(window.id)
  }
  {
    key: 'k' # moving focus
    callback: ->
      monitor = currentMonitor()
      if monitor.focused_window && nwm.windows.exists(monitor.focused_window)
        next = nwm.windows.next(monitor.focused_window)
        window = nwm.windows.get(next)
        console.log('Current', monitor.focused_window, 'next', window.id)
        monitor.focused_window = window.id
        nwm.wm.focusWindow(monitor.focused_window)
  }
  {
    key: 'q' # quit
    modifier: [ 'shift' ]
    callback: ->
      process.exit()
  }
]

# take each of the keyboard shortcuts above and make add a key using nwm.addKey
keyboard_shortcuts.forEach((shortcut) ->
  callback = shortcut.callback
  modifier = baseModifier
  # translate the modifier array to a X11 modifier
  if shortcut.modifier
    (shortcut.modifier.indexOf('shift') > -1) && (modifier = modifier|Xh.ShiftMask)
    (shortcut.modifier.indexOf('ctrl') > -1) && (modifier = modifier|Xh.ControlMask)
  # add shortcuts
  if Array.isArray(shortcut.key)
    shortcut.key.forEach((key) ->
      nwm.addKey({ key: XK[key], modifier: modifier }, callback)
    )
  else
    nwm.addKey({ key: XK[shortcut.key], modifier: modifier }, callback)
)


# /usr/include/X11/XF86keysym.h

XF86keysym = {
  AudioLowerVolume: 0x1008FF11   # Volume control down
  AudioMute:  0x1008FF12   # Mute sound from the system
  AudioRaiseVolume: 0x1008FF13   # Volume control up
}

# Experimental volume key support for my thinkpad

nwm.addKey( { key: XF86keysym.AudioLowerVolume, modifier: 0 }, ->
  child_process.spawn('amixer', ['set', 'Master', '2dB-', 'unmute'], { env: process.env })
)

nwm.addKey( { key: XF86keysym.AudioMute, modifier: 0 }, ->
  child_process.spawn('amixer', ['set', 'Master', 'toggle'], { env: process.env })
)

nwm.addKey( { key: XF86keysym.AudioRaiseVolume, modifier: 0 }, ->
  child_process.spawn('amixer', ['set', 'Master', '2dB+', 'unmute'], { env: process.env })
)

# REPL

# list windows
Repl = ->
Repl.windows = ->
  console.log(['id', 'monitor', 'workspace', 'title', 'x', 'y', 'h', 'w'].join(' | '))
  items = []
  Object.keys(nwm.windows.items).forEach((id) ->
    window = nwm.windows.get(id)
    items.push([window.id, window.monitor, window.workspace, window.title, window.x, window.y, window.height, window.width ])
  )

  items.forEach((item) ->
    console.log(item.join(' | '))
  )



# START
nwm.start( ->
  # expose repl over unix socket
  repl = require('repl')
  net = require('net')
  net.createServer((socket) ->
    console.log('Started REPL via unix socket on ./repl-sock. Use socat to connect: "socat STDIN UNIX-CONNECT:./repl-sock"')
    r = repl.start('>', socket)
    r.context.nwm = nwm
    r.context.windows = Repl.windows
  ).listen('./repl-sock')
)
