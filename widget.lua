--[==[
widget.lua -- Show a hackerspace status.

Copyright (C) 2015  Artyom V. Poptsov <poptsov.artyom@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]==]

local setmetatable = setmetatable

local vicious = require("vicious")
local naughty = require("naughty")
local spaceapi = require("awesome_space.spaceapi")
local as_util  = require("awesome_space.util")
local awful = require("awful")
local as_util = {wrap = as_util.wrap, assoc = as_util.assoc}
local mouse =  mouse
local pairs = pairs
local naughty = { notify = naughty.notify, destroy = naughty.destroy  }
local util = awful.util
local tooltip = awful.tooltip
local menu = awful.menu
local prompt = awful.prompt
local table = table
local string = { sub = string.sub, lower = string.lower }

module ("awesome_space.widget")

-- Space API directory table
local directory = nil

-- Space API endpoint to be observed to
local endpoint = false;

-- Cached hackerspace data
local hackerspace = nil

-- Popup menu
local popup = nil

-- Widget menu
local widget_menu = nil;


-- Set hackerspace to NAME.
function set_hackerspace_x (name)
   directory = spaceapi.get_spaceapi_directory ()
   endpoint = {
      name      = name,
      cache_url = directory[name]
   }
end

-- Refresh hackerspace data
function refresh ()
   hackerspace = spaceapi.get_hackerspace_data (endpoint.cache_url)
end


local indicator = {
   ["open"]      = "<span color='#7fff00'>⬤</span>",
   ["closed"]    = "<span color='#ffff00'>⬤</span>",
   ["undefined"] = "<span color='#bebebe'>⬤</span>"
}

-- Default widget formatter.
function default_formatter (widget, args)
   return indicator[args["state"]]
end

-- Make an unordered list containing ELEMENTS with markers.
local function make_list (elements)
   local result = ''
   for idx,val in pairs (elements) do
      if val and val ~= "" then
         result = result .. '■ ' .. val .. '\n'
      end
   end
   return result
end


function show_popup ()
   if hackerspace ~= nil then
      local state = spaceapi.get_state (hackerspace)
      local location = spaceapi.get_location (hackerspace)
      local notify_text = hackerspace.url .. '\n\n'
         .. '<u>Status</u>\n' .. indicator[state] .. ' ' .. state .. '\n'
         .. '\n'

      if location then
         local address = location.address and as_util.wrap (location.address)
            or nil
         notify_text = notify_text .. '<u>Location</u>\n'
            .. make_list ({address, location.lon .. ', ' .. location.lat})
            .. '\n'
      end

      local contacts = make_list (hackerspace.contact)
      if contacts ~= '' then
         notify_text = notify_text .. '<u>Contact</u>\n' .. contacts
      end

      popup = naughty.notify ({
                                 title  = hackerspace.space,
                                 text   = notify_text,
                                 timeout = 0,
                                 screen = mouse.screen
                              })
   end
end

function hide_popup ()
   if popup ~= nil then
      naughty.destroy (popup)
   end
   popup = nil
end

function register (widget)
   local widget_t = tooltip ({
                                objects = { widget },
                                timer_function = function ()
                                   if hackerspace ~= nil then
                                      local name = hackerspace.space
                                      local state
                                         = spaceapi.get_state (hackerspace)
                                      return name .. ': ' .. state
                                   end
                                end
                             })

   local make_dir_menu = function ()
      -- Sort a table T alfabetically
      local alfa_sort = function (t)
         table.sort (t, function (a, b) return a[1] < b[1] end)
      end

      local items = {}

      for i,k in pairs (directory) do
         local letter = string.sub (string.lower (i), 0, 1)
         local letter_table = as_util.assoc (items, letter)
         if not letter_table then
            items[#items + 1] = {letter, {}}
            letter_table = items[#items]
         end

         letter_table[2][#letter_table[2] + 1] = {
            i,
            function ()
               set_hackerspace_x (i)
               refresh ()
            end
         }
      end

      alfa_sort (items)

      for i,k in pairs (items) do
         alfa_sort (k[2])
      end

      return items
   end

   local widget_m = nil

   local show_menu = function ()
      if not widget_m then
         widget_m
            = menu ({items = {
                        { "Refresh",                  refresh },
                        { "Choose an hackerspace...", make_dir_menu () }
            }})
      end

      widget_m:toggle()
   end

   widget:buttons (util.table.join (
                      awful.button ({ }, 1,
                                    function ()
                                       if popup == nil then
                                          show_popup ()
                                       else
                                          hide_popup ()
                                       end
                                    end),
                      awful.button ({ }, 3, show_menu)))
end


function worker (format, warg)
   if not hackerspace then
      set_hackerspace_x (warg)
   end

   refresh ()
   return { name = hackerspace.space, state = spaceapi.get_state (hackerspace) }
end


setmetatable(_M, { __call = function(_, ...) return worker(...) end })

-- widget.lua ends here.
