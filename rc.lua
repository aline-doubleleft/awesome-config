
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
local tyrannical = require("tyrannical")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
awesome_home = os.getenv("HOME") .. "/.config/awesome/"
local beautiful = require("beautiful")
beautiful.init(awesome_home .. "themes/default/theme.lua")
local revelation = require("revelation")
local vicious = require("vicious")
require("powerline")

local blingbling = require("blingbling")

-- This is used later as the default terminal and editor to run.
terminal = "xfce4-terminal -e tmux"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
filemanager = "xfce4-terminal -e 'tmux new -s ranger \'ranger\''"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

divider = wibox.widget.textbox()
divider:set_text(" ")

hardivider = wibox.widget.textbox()
hardivider:set_text("|")

mycalendar = wibox.widget.textbox()    
mycalendartimer = timer({ timeout = 60 })    
mycalendartimer:connect_signal("timeout",    
  function()
    agenda = "khal agenda --days 1"
    fh = assert(io.popen(agenda .. " | [ $(wc -l) -ne 1 ] && " .. agenda .. " | grep '[0-2][0-9]:[0-2][0:9]-[0-2][0-9]:[0-2][0-9]' || " .. agenda, "r"))
    mycalendar:set_text(fh:read("*all"))    
    fh:close()    
  end    
)    
mycalendartimer:start()

-- Powerline
local powerline_layout = wibox.layout.margin(powerline_widget,0,0,0,5)

-- CPU graph
cpu_graph = blingbling.line_graph()
cpu_graph:set_height(18)
cpu_graph:set_width(100)
cpu_graph:set_show_text(false)
cpu_graph:set_rounded_size(0.3)
cpu_graph:set_graph_background_color("#00000033")
vicious.register(cpu_graph, vicious.widgets.cpu,'$1',2)

-- CPU thermal
thermalwidget = wibox.widget.textbox()
vicious.register(thermalwidget, vicious.widgets.thermal, "$1°C", 20, { "coretemp.0/hwmon/hwmon0", "core"} )

-- Mem widget
memwidget=blingbling.line_graph()
memwidget:set_height(18)
memwidget:set_width(100)
memwidget:set_graph_background_color("#00000022")
memwidget:set_show_text(true)
memwidget:set_font_size(8)
vicious.register(memwidget, vicious.widgets.mem, '$1', 13)

-- {{{ File system usage
-- Initialize widgets
fs = {
  b = awful.widget.progressbar(), r = awful.widget.progressbar(),
  h = awful.widget.progressbar(), s = awful.widget.progressbar()
}

fsboot = wibox.widget.textbox()
fsboot:set_text('/boot:')

fsroot = wibox.widget.textbox()
fsroot:set_text('/:')

fshome = wibox.widget.textbox()
fshome:set_text('/home:')

-- Progressbar properties
for _, w in pairs(fs) do
  w:set_vertical(true):set_ticks(true)
  w:set_height(14):set_width(5):set_ticks_size(2)
  w:set_border_color(beautiful.border_widget)
  w:set_background_color(beautiful.fg_off_widget)
  w:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 },
    stops = { { 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" }}
  }) -- Register buttons
  w:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("rox", false) end)
  ))
end -- Enable caching
vicious.cache(vicious.widgets.fs)
-- Register widgets
vicious.register(fs.b, vicious.widgets.fs, "${/boot used_p}", 599)
vicious.register(fs.r, vicious.widgets.fs, "${/ used_p}",     599)
vicious.register(fs.h, vicious.widgets.fs, "${/home used_p}", 599)
-- }}}

-- Volume
carddev = "pulse"
scontrol = "Speaker"
function volume (mode, widget)
    -- it returns either channel = 0, when USB is connected or channel = 1 otherwise.
    local channel = os.execute("cat /proc/asound/cards | grep USB >/dev/null 2>&1")
    if mode == "update" then
        local fd = io.popen("amixer -D " .. carddev .. " -c " .. channel .. " -- sget " .. scontrol)
        local status = fd:read("*all")
        fd:close()

        local volume = string.match(status, "(%d?%d?%d)%%")
        volume = string.format("% 3d", volume)

        status = string.match(status, "%[(o[^%]]*)%]")

        if string.find(status, "on", 1, true) then
            widget:set_background_color("#000000")
        else
            widget:set_background_color("#cc3333")
        end
        widget:set_value(volume)
    elseif mode == "up" then
        io.popen("amixer -q -D " .. carddev .. " -c " .. channel .. " sset " .. scontrol .. " 5%+"):read("*all")
        volume("update", widget)
    elseif mode == "down" then
        io.popen("amixer -q -D " .. carddev .. " -c " .. channel .. " sset " .. scontrol .. " 5%-"):read("*all")
        volume("update", widget)
    else
        io.popen("amixer -D " .. carddev .. " -c " .. channel .. " sset " .. scontrol .. " toggle"):read("*all")
        volume("update", widget)
    end
end

pb_volume = awful.widget.progressbar()
pb_volume:set_width(12)
pb_volume:set_height(1)
pb_volume:set_ticks(true)
pb_volume:set_ticks_gap(1)
pb_volume:set_ticks_size(1)
pb_volume:set_vertical(true)
pb_volume:set_background_color("#000000")
pb_volume:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, "black" }, { 0.5, "yellow" }, { 1, "red" } }})
pb_volume:set_border_color("#999933")
pb_volume:set_max_value(100)
pb_volume:set_value(0)
pb_volume:buttons(awful.util.table.join(
    awful.button( { }, 4, function () volume("up", pb_volume) end),
    awful.button( { }, 5, function () volume("down", pb_volume) end),
    awful.button( { }, 1, function () volume("mute", pb_volume) end)
))
volume("update", pb_volume)
pb_timer = timer({ timeout = 10 })
pb_timer:connect_signal("timeout", function () volume("update", pb_volume) end)
pb_timer:start()

-- Keyboard layout widget
kbdwidget = wibox.widget.textbox(" Dvorak ")
kbdwidget.border_width = 1
kbdwidget.border_color = beautiful.fg_normal
kbdwidget:set_text(" Dvorak ")

kbdstrings = {[0] = " Dvorak ", 
              [1] = " Bra "}

dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.connect_signal("ru.gentoo.kbdd", function(...)
    local data = {...}
    local layout = data[2]
    kbdwidget:set_markup(kbdstrings[layout])
    end
)

-- {{{ Calendar
local calendar = blingbling.calendar(powerline_layout)
calendar:set_link_to_external_calendar(true)
calendar:clear_and_add_function_get_events_from(
   function(day, month, year)
      local f = io.popen('khal agenda --days 1 ' ..
                            day .. '/' .. month .. '/' .. year)
      local out = f:read("*all")
      f:close()
      return out
   end
)

local powerline_calendar = wibox.layout.margin(calendar,0,0,0,5)

-- }}}

local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- First, set some settings
tyrannical.settings.default_layout =  awful.layout.suit.floating
tyrannical.settings.mwfact = 0.66

-- Setup some tags
tyrannical.tags = {
    {
        name        = "Term",                 -- Call the tag "Term"
        init        = true,                   -- Load the tag on startup
        exclusive   = true,                   -- Refuse any other type of clients (by classes)
        screen      = {1,2},                  -- Create this tag on screen 1 and screen 2
        layout      = awful.layout.suit.max,
        selected    = true,
        class       = { --Accept the following classes, refuse everything else (because of "exclusive=true")
            "xterm" , "urxvt" , "aterm","URxvt","XTerm","konsole","terminator","gnome-terminal","Xfce4-terminal","xfce4-terminal"
        }
    } ,
    {
        name        = "Internet",
        init        = true,
        exclusive   = true,
      --icon        = "~net.png",                 -- Use this icon for the tag (uncomment with a real path)
        screen      = screen.count()>1 and 2 or 1,-- Setup on screen 2 if there is more than 1 screen, else on screen 1
        layout      = awful.layout.suit.max,      -- Use the max layout
        -- exec_once   = {"chromium"}, --When the tag is accessed for the first time, execute this command
        class = {
            "Opera"         , "Firefox"        , "Rekonq"    , "Dillo"        , "Arora",
            "Chromium"      , "chromium-browser-chromium", "nightly"        , "minefield"     }
    } ,
    {
        name = "Files",
        init        = false,
        exclusive   = true,
        screen      = 1,
        layout      = awful.layout.suit.tile,
        -- exec_once   = {"thunar"}, --When the tag is accessed for the first time, execute this command
        class  = {
            "Thunar", "Konqueror", "Dolphin", "ark", "Nautilus","emelfm", "ranger"
        }
    } ,
    {
        name        = "Doc",
        init        = false, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        exclusive   = true,
        layout      = awful.layout.suit.max,
        class       = {
            "Assistant"     , "Okular"         , "Evince"    , "EPDFviewer"   , "xpdf",
            "Xpdf"          , "Zathura"                                       }
    } ,
    {
        name        = "Multimedia",
        init        = false, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        exclusive   = true,
        layout      = awful.layout.suit.floating,
        class       = {
            "Spotify", "spotify"
        }
    } ,
{
        name        = "Tools",
        init        = false, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        exclusive   = true,
        layout      = awful.layout.suit.floating,
        class       = {
            "pavucontrol"
        }
    } ,
    {
        name        = "IM",
        init        = false,

        exclusive   = false,
        layout      = awful.layout.suit.floating,
        class       = {
            "Sky", "Skype", "Slack" 
        }
    }
}

-- Ignore the tag "exclusive" property for the following clients (matched by classes)
tyrannical.properties.intrusive = {
    "ksnapshot"     , "pinentry"       , "gtksu"     , "kcalc"        , "xcalc"               ,
    "feh"           , "Gradient editor", "About KDE" , "Paste Special", "Background color"    ,
    "kcolorchooser" , "plasmoidviewer" , "Xephyr"    , "kruler"       , "plasmaengineexplorer",
}

-- Ignore the tiled layout for the matching clients
tyrannical.properties.floating = {
    "MPlayer"      , "pinentry"        , "ksnapshot"  , "pinentry"     , "gtksu"          ,
    "xine"         , "feh"             , "kmix"       , "kcalc"        , "xcalc"          ,
    "yakuake"      , "Select Color$"   , "kruler"     , "kcolorchooser", "Paste Special"  ,
    "New Form"     , "Insert Picture"  , "kcharselect", "mythfrontend" , "plasmoidviewer" 
}

-- Make the matching clients (by classes) on top of the default layout
tyrannical.properties.ontop = {
    "Xephyr"       , "ksnapshot"       , "kruler"
}

-- Force the matching clients (by classes) to be centered on the screen on init
tyrannical.properties.centered = {
    "kcalc"
}

-- Do not honor size hints request for those classes
tyrannical.properties.size_hints_honor = { xterm = false, URxvt = false, aterm = false, sauer_client = false, mythfrontend  = false}


-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                       awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(divider)
    right_layout:add(pb_volume)
    right_layout:add(divider)
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(kbdwidget)
    right_layout:add(divider)
    right_layout:add(fsroot)
    right_layout:add(fs.r)
    right_layout:add(divider)
    right_layout:add(fshome)
    right_layout:add(fs.h)
    right_layout:add(divider)
    right_layout:add(fsboot)
    right_layout:add(fs.b)
    right_layout:add(divider)
    right_layout:add(memwidget)
    right_layout:add(thermalwidget)
    right_layout:add(cpu_graph)
    right_layout:add(powerline_calendar)
    right_layout:add(divider)
    right_layout:add(mycalendar)
    right_layout:add(divider)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),
    awful.key({ modkey,           }, "e",      revelation),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Shift"   }, "Return", function () awful.util.spawn(filemanager) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    awful.key({ }, "Print", function () 
        awful.util.spawn_with_shell("DATE=`date +%d%m%Y_%H%M%S`; xsnap -nogui -file $HOME/Temp/xsnap$DATE") 
        end),

    -- Unmount all devices
    awful.key({ modkey, "Mod1" }, "m", function ()
        awful.util.spawn_with_shell("udiskie-umount -2 -a")
    end),

    -- Lock screen
    awful.key({ modkey, "Mod1" }, "l", function ()
        awful.util.spawn("sync")
        awful.util.spawn("xautolock -locknow")
    end),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),

    -- Volume
    awful.key({ }, "XF86AudioRaiseVolume", function () volume("up", pb_volume) end),
    awful.key({ }, "XF86AudioLowerVolume", function () volume("down", pb_volume) end),
    awful.key({ }, "XF86AudioMute", function () volume("mute", pb_volume) end),

    -- Brighness
    awful.key({ }, "XF86MonBrightnessDown", function ()
    awful.util.spawn("xbacklight -dec 15") end),
    awful.key({ }, "XF86MonBrightnessUp", function ()
    awful.util.spawn("xbacklight -inc 15") end)

    -- Alt + Right Shift switches the current keyboard layout
    -- awful.key({ "Mod1" }, "Shift_R", function () kbdcfg.switch() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    --default stuff here,
    -- {
    --     rule = { class = ""  },
    --     callback = function(c)
    --     awful.client.property.set(c, "overwrite_class", "spotify")
    --     end
    -- }
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

local xresources_name = "awesome.started"
local xresources = awful.util.pread("xrdb -query")
if not xresources:match(xresources_name) then
    -- Execute once for X server
    os.execute("dex -a -e Awesome")
    os.execute("/usr/bin/gnome-keyring-daemon --start --components=ssh")
end
awful.util.spawn_with_shell("xrdb -merge <<< " .. "'" .. xresources_name .. ": true'")
