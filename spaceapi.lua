--[==[
spaceapi.lua -- Space API procedures.

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

local json = require("dkjson")
local io = { popen = io.popen }


module ("awesome_space.spaceapi")


-- URL of the Space API hackerspace directory
local spaceapi_directory = "http://spaceapi.net/directory.json"


--- JSON

-- Get JSON data from the given URL.  Return received data, or 'false'
-- on an error.
local function get_json (url)
   command = 'curl --max-time 15 --silent "' .. url .. '"'
   f = io.popen (command)
   if (not f) then
      print ("Error")
      return false
   end

   return f:read("*all")
end

-- Parse a JSON object JSON_OBJ.  Return a table, or 'false' on an
-- error.
local function parse_json (json_obj)
   local obj, pos, err = json.decode (json_obj, 1, nil)
   if err then
      print ("Error:", err)
      return false
   else
      return obj
   end
end


--- Space API

-- Get the Space API directory as a table.
function get_spaceapi_directory ()
   local json = get_json (spaceapi_directory)
   if not json then
      error ("Could not read JSON")
   end

   local directory = parse_json (json)
   if not directory then
      error ("Could not parse the directory JSON")
   end

   return directory
end

-- Get data for the specified hackerspace.  Return a table, or raise
-- an error.
function get_hackerspace_data (cache_url)
   local json = get_json (cache_url)
   if not json then
      error ("Could not get a hackerspace JSON data:", cache_url)
   end

   return parse_json (json)
end


-- Get hackerspace state from the given data HACKERSPACE_DATA.
function get_state (hackerspace)
   local state_open = nil

   if hackerspace.api == "0.13" then
      state_open = hackerspace.state.open
   elseif hackerspace.api == "0.12" then
      state_open = hackerspace.open
   end

   if state_open == true then
      return "open"
   elseif state_open == false then
      return "closed"
   else
      return "undefined"
   end
end

function get_location (hackerspace)
   local location = nil
   if hackerspace.api == "0.13" then
      location = { address = hackerspace.location.address,
                   lat     = hackerspace.location.lat,
                   lon     = hackerspace.location.lon }
   elseif hackerspace.api == "0.12" then
      location = { address = hackerspace.address,
                   lat     = hackerspace.lat,
                   lon     = hackerspace.lon }
   end

   return location
end

--- spaceapi.lua ends here.
