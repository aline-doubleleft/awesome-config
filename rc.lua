-- default rc.lua for shifty
--
-- package.path = package.path .. ';' .. os.getenv("HOME") .. '/.luarocks/lib/lua/5.1;'
print(package.path)
-- Standard awesome library
require("awful")
require("awful.autofocus")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- shifty - dynamic tagging library
require("shifty")
-- Vicious 
vicious = require("vicious")
-- APW
-- local APW = require("apw/widget")


-- Lognotify
-- local lognotify=require("lognotify")

-- useful for debugging, marks the beginning of rc.lua exec
print("Entered rc.lua: " .. os.time())

-- Variable definitions
awesome_home = os.getenv("HOME") .. "/.config/awesome"
-- Themes define colours, icons, and wallpapers
-- The default is a dark theme
theme_path = awesome_home .. "/themes/redhalo/theme.lua"
-- Uncommment this for a lighter theme
-- theme_path = "/usr/share/awesome/themes/sky/theme"

-- Actually load theme
beautiful.init(theme_path)

-- This is used later as the default terminal and editor to run.
browser = "firefox"
mail = "thunderbird"
terminal = "urxvtc -e tmux"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

spacer = widget({ type = "textbox" })
spacer.text = " "

-- Vicious widgets
-- Date and Time
datewidget = widget({ type = "textbox" })
vicious.register(datewidget, vicious.widgets.date, "%a %b %d, %R", 60)

-- Memory
memwidget = widget({ type = "textbox" })
vicious.register(memwidget, vicious.widgets.mem, "$1% ($2MB/$3MB)", 13)

-- CPU Usage
cpuwidget = awful.widget.graph()
cpuwidget:set_width(50)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color("#FF5656")
cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
vicious.register(cpuwidget, vicious.widgets.cpu, "$1")

-- Audio volume
volmaster = widget({ type = "textbox" })
volmaster:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("amixer -q set Master toggle", false) end),
    awful.button({ }, 3, function () awful.util.spawn(terminal .. "-e alsamixer", true)   end),
    awful.button({ }, 4, function () awful.util.spawn("amixer -q set Master 2dB+", false) end),
    awful.button({ }, 5, function () awful.util.spawn("amixer -q set Master 2dB-", false) end)
 ))
vicious.register(volmaster, vicious.widgets.volume, "Master: $1% ", 1, "Master")

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key, I suggest you to remap
-- Mod4 to another key using xmodmap or other tools.  However, you can use
-- another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}

-- Define if we want to use titlebar on all applications.
use_titlebar = false

-- Shifty configured tags.
shifty.config.tags = {
    w1 = {
        layout    = awful.layout.suit.max,
        mwfact    = 0.60,
        exclusive = false,
        position  = 1,
        init      = true,
        screen    = 1,
        slave     = true,
    },
    web = {
        layout      = awful.layout.suit.tile.bottom,
        mwfact      = 0.65,
        exclusive   = true,
        max_clients = 1,
        position    = 4,
        spawn       = browser,
    },
    mail = {
        layout    = awful.layout.suit.tile,
        mwfact    = 0.55,
        exclusive = false,
        position  = 5,
        spawn     = mail,
        slave     = true
    },
    tools = {
        layout    = awful.layout.suit.floating,
        exclusive = false,
        position  = 7,
    },
    media = {
        layout    = awful.layout.suit.floating,
        exclusive = false,
        position  = 8,
    },
    office = {
        layout   = awful.layout.suit.tile,
        position = 9,
    },
}

-- SHIFTY: application matching rules
-- order here matters, early rules will be applied first
shifty.config.apps = {
    {
        match = {
            "Navigator",
            "Vimperator",
            "Gran Paradiso",
            "Chromium",
        },
        tag = "web",
    },
    {
        match = {
            "Shredder.*",
            "Thunderbird",
            "mutt",
        },
        tag = "mail",
    },
    {
        match = {
            "pcmanfm",
        },
        slave = true
    },
    {
        match = {
            "calculator",
            "FOX Calculator",
            "pavucontrol",
        },
        tag = "tools",
    },
    {
        match = {
            "OpenOffice.*",
            "Abiword",
            "Gnumeric",
        },
        tag = "office",
    },
    {
        match = {
            "Mplayer.*",
            "Mirage",
            "gimp",
            "gtkpod",
            "Ufraw",
            "easytag",
            "spotify",
            "Spotify.*",
        },
        tag = "media",
        nopopup = true,
    },
    {
        match = {
            "MPlayer",
            "Gnuplot",
            "galculator",
            "calculator",
            "FOX Calculator",
            "pavucontrol",
            "spotify",
        },
        float = true,
    },
    {
        match = {
            terminal,
        },
        honorsizehints = false,
        slave = true,
    },
    {
        match = {""},
        buttons = awful.util.table.join(
            awful.button({}, 1, function (c) client.focus = c; c:raise() end),
            awful.button({modkey}, 1, function(c)
                client.focus = c
                c:raise()
                awful.mouse.client.move(c)
                end),
            awful.button({modkey}, 3, awful.mouse.client.resize)
            )
    },
}

-- SHIFTY: default tag creation rules
-- parameter description
--  * floatBars : if floating clients should always have a titlebar
--  * guess_name : should shifty try and guess tag names when creating
--                 new (unconfigured) tags?
--  * guess_position: as above, but for position parameter
--  * run : function to exec when shifty creates a new tag
--  * all other parameters (e.g. layout, mwfact) follow awesome's tag API
shifty.config.defaults = {
    layout = awful.layout.suit.tile.bottom,
    ncol = 1,
    mwfact = 0.60,
    floatBars = true,
    guess_name = true,
    guess_position = true,
}

--  Wibox
-- Create a laucher widget and a main menu
myawesomemenu = {
    {"manual", terminal .. " -e man awesome"},
    {"edit config",
     editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua"},
    {"restart", awesome.restart},
    {"quit", awesome.quit}
}

mymainmenu = awful.menu(
    {
        items = {
            {"awesome", myawesomemenu, beautiful.awesome_icon},
              {"open terminal", terminal}}
          })

mylauncher = awful.widget.launcher({image = image(beautiful.awesome_icon),
                                     menu = mymainmenu})

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
    awful.button({}, 1, awful.tag.viewonly),
    awful.button({modkey}, 1, awful.client.movetotag),
    awful.button({}, 3, function(tag) tag.selected = not tag.selected end),
    awful.button({modkey}, 3, awful.client.toggletag),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
    )

mytasklist = {}
mytasklist.buttons = awful.util.table.join(
    awful.button({}, 1, function(c)
        if not c:isvisible() then
            awful.tag.viewonly(c:tags()[1])
        end
        client.focus = c
        c:raise()
        end),
    awful.button({}, 3, function()
        if instance then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({width=250})
        end
        end),
    awful.button({}, 4, function()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
        end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
        end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] =
        awful.widget.prompt({layout = awful.widget.layout.leftright})
    -- Create an imagebox widget which will contains an icon indicating which
    -- layout we're using.  We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
            awful.button({}, 1, function() awful.layout.inc(layouts, 1) end),
            awful.button({}, 3, function() awful.layout.inc(layouts, -1) end),
            awful.button({}, 4, function() awful.layout.inc(layouts, 1) end),
            awful.button({}, 5, function() awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist.new(s,
                                            awful.widget.taglist.label.all,
                                            mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist.new(function(c)
                        return awful.widget.tasklist.label.currenttags(c, s)
                    end,
                                              mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({position = "top", screen = s})
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        datewidget, spacer,
        s == 1 and mysystray or nil, spacer,
        memwidget, spacer,
        cpuwidget.widget, spacer,
        volmaster, spacer,
        -- right_layout:add(APW),
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
        }

    mywibox[s].screen = s
end

-- SHIFTY: initialize shifty
-- the assignment of shifty.taglist must always be after its actually
-- initialized with awful.widget.taglist.new()
shifty.taglist = mytaglist
shifty.init()

-- Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({}, 3, function() mymainmenu:show({keygrabber=true}) end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))

-- Key bindings
globalkeys = awful.util.table.join(
    -- Tags
    awful.key({modkey,}, "Left", awful.tag.viewprev),
    awful.key({modkey,}, "Right", awful.tag.viewnext),
    awful.key({modkey,}, "Escape", awful.tag.history.restore),

    -- Shifty: keybindings specific to shifty
    awful.key({modkey, "Shift"}, "d", shifty.del), -- delete a tag
    awful.key({modkey, "Shift"}, "n", shifty.send_prev), -- client to prev tag
    awful.key({modkey}, "n", shifty.send_next), -- client to next tag
    awful.key({modkey, "Control"},
              "n",
              function()
                  local t = awful.tag.selected()
                  local s = awful.util.cycle(screen.count(), t.screen + 1)
                  awful.tag.history.restore()
                  t = shifty.tagtoscr(s, t)
                  awful.tag.viewonly(t)
              end),
    awful.key({modkey}, "a", shifty.add), -- creat a new tag
    awful.key({modkey,}, "r", shifty.rename), -- rename a tag
    awful.key({modkey, "Shift"}, "a", -- nopopup new tag
    function()
        shifty.add({nopopup = true})
    end),

    awful.key({modkey,}, "j",
    function()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({modkey,}, "k",
    function()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({modkey,}, "w", function() mymainmenu:show(true) end),

    -- Layout manipulation
    awful.key({modkey, "Shift"}, "j",
        function() awful.client.swap.byidx(1) end),
    awful.key({modkey, "Shift"}, "k",
        function() awful.client.swap.byidx(-1) end),
    awful.key({modkey, "Control"}, "j", function() awful.screen.focus(1) end),
    awful.key({modkey, "Control"}, "k", function() awful.screen.focus(-1) end),
    awful.key({modkey,}, "u", awful.client.urgent.jumpto),
    awful.key({modkey,}, "Tab",
    function()
        awful.client.focus.history.previous()
        if client.focus then
            client.focus:raise()
        end
    end),

    -- Standard program
    awful.key({modkey,}, "Return", function() awful.util.spawn(terminal) end),
    awful.key({modkey, "Control"}, "r", awesome.restart),
    awful.key({modkey, "Shift"}, "q", awesome.quit),

    awful.key({modkey,}, "l", function() awful.tag.incmwfact(0.05) end),
    awful.key({modkey,}, "h", function() awful.tag.incmwfact(-0.05) end),
    awful.key({modkey, "Shift"}, "h", function() awful.tag.incnmaster(1) end),
    awful.key({modkey, "Shift"}, "l", function() awful.tag.incnmaster(-1) end),
    awful.key({modkey, "Control"}, "h", function() awful.tag.incncol(1) end),
    awful.key({modkey, "Control"}, "l", function() awful.tag.incncol(-1) end),
    awful.key({modkey,}, "space", function() awful.layout.inc(layouts, 1) end),
    awful.key({modkey, "Shift"}, "space",
        function() awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({modkey}, "F1", function()
        awful.prompt.run({prompt = "Run: "},
        mypromptbox[mouse.screen].widget,
        awful.util.spawn, awful.completion.shell,
        awful.util.getdir("cache") .. "/history")
        end),

    awful.key({modkey}, "F4", function()
        awful.prompt.run({prompt = "Run Lua code: "},
        mypromptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
        end),
    
    awful.key({ }, "Print", function () 
        awful.util.spawn_with_shell("DATE=`date +%d%m%Y_%H%M%S`; xsnap -nogui -file $HOME/Temp/xsnap$DATE") 
        end)
    )

-- Client awful tagging: this is useful to tag some clients and then do stuff
-- like move to tag on them
clientkeys = awful.util.table.join(
    awful.key({modkey,}, "f", function(c) c.fullscreen = not c.fullscreen  end),
    awful.key({modkey, "Shift"}, "c", function(c) c:kill() end),
    awful.key({modkey, "Control"}, "space", awful.client.floating.toggle),
    awful.key({modkey, "Control"}, "Return",
        function(c) c:swap(awful.client.getmaster()) end),
    awful.key({modkey,}, "o", function(c) awful.client.movetoscreen(c,c.screen-1) end ),
     awful.key({modkey,}, "p", function(c) awful.client.movetoscreen(c,c.screen+1) end ),
    awful.key({modkey, "Shift"}, "r", function(c) c:redraw() end),
    awful.key({modkey}, "t", awful.client.togglemarked),
    awful.key({modkey,}, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),

    -- Multimedia
    awful.key({ }, "XF86AudioRaiseVolume", function ()
       awful.util.spawn("amixer set Master 2%+", false) end),
    awful.key({ }, "XF86AudioLowerVolume", function ()
       awful.util.spawn("amixer set Master 2%-", false) end),
    awful.key({ }, "XF86AudioMute", function ()
       awful.util.spawn("amixer set Master toggle", false) end)

)

-- SHIFTY: assign client keys to shifty for use in
-- match() function(manage hook)
shifty.config.clientkeys = clientkeys
shifty.config.modkey = modkey

-- Compute the maximum number of digit we need, limited to 9
for i = 1, (shifty.config.maxtags or 9) do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({modkey}, i, function()
            local t =  awful.tag.viewonly(shifty.getpos(i))
            end),
        awful.key({modkey, "Control"}, i, function()
            local t = shifty.getpos(i)
            t.selected = not t.selected
            end),
        awful.key({modkey, "Control", "Shift"}, i, function()
            if client.focus then
                awful.client.toggletag(shifty.getpos(i))
            end
            end),
        -- move clients to other tags
        awful.key({modkey, "Shift"}, i, function()
            if client.focus then
                t = shifty.getpos(i)
                awful.client.movetotag(t)
                awful.tag.viewonly(t)
            end
        end))
    end

-- Set keys
root.keys(globalkeys)

-- Hook function to execute when focusing a client.
client.add_signal("focus", function(c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_focus
    end
end)

-- Hook function to execute when unfocusing a client.
client.add_signal("unfocus", function(c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_normal
    end
end)

-- Auto-execute dex
local xresources_name = "awesome.started"
local xresources = awful.util.pread("xrdb -query")
if not xresources:match(xresources_name) then
    -- Execute once for X server
    os.execute("dex -a -e Awesome")
end
awful.util.spawn_with_shell("xrdb -merge <<< " .. "'" .. xresources_name .. ": true'")

-- ilog = lognotify{
--    logs = { mpd = { file = "/home/bob/.mpd/log", },
--     aptitude = { file = "/var/log/aptitude", },
--     -- Check, whether you have the permissions to read your log files!
--     -- You can fix this by configure syslog deamon in many case.
--     syslog    = { file = "/var/log/syslog", ignore = { "Changing fan level" },
--     },
--     awesome  = { file = "/home/bob/log/awesome",
--         ignore = {
--             "/var/lib/dpkg", -- aptwidget failure when aptitude running
--             "wicd", "wired profiles found", -- wicd junk
--             "seek to:", "Close unzip stream", -- gmpc junk
--             "^nolog"},
--         },
--    -- Delay between checking in seconds. Default: 1
--    interval = 1,
--    -- Time in seconds after which popup expires. Set 0 for no timeout. Default: 0
--    naughty_timeout = 15
--    }
-- }
-- 
-- ilog:start()
