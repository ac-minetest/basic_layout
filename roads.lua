-- ROAD LAYOUT GENERATOR by rnd
-- Copyright 2016 rnd

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local layout = {};
layout.cells = {}; -- list of cells, each cell will be {x1,z1,x2,z2,mark}, mark = true means cell is to be removed
layout.roads = {}; -- road list, each road {x1,z1,x2,z2}
layout.pos = {x=0,y=0,z=0}; -- where to put it
-- SETTINGS
layout.height = 200; -- dimension of outer box
layout.width = 200;
layout.minheight = 5; -- smallest dimension of cell
layout.minheightupper = 100;
layout.minwidth = 5;
layout.minwidthupper = 100;
layout.excludeprobability = 0.8;
-- END OF SETTINGS

layout.subdivide = function ( cell_index )
	
	local cell = layout.cells[cell_index];
	local x1 = cell[1]; local z1 = cell[2]; local x2 = cell[3]; local z2 = cell[4];
	local nz, nx,vertically,horizontaly;
	vertically=false;horizontaly=false;
	local minheight = layout.minheight+(layout.minheightupper-layout.minheight)*math.random();
	local minwidth = layout.minwidth+(layout.minwidthupper-layout.minwidth)*math.random();
	
	if z2-z1<layout.height*0.25 and z2-z1>0.1*layout.height then -- chunks of certains size get discarded
		if math.random()<layout.excludeprobability then return false end -- discard
	end
	
	if z2-z1>2*minheight then -- can subdivide vertically
		--z1+layout.minheight,z2-layout.minheight
		nz = z1+minheight+math.random()*(z2-z1-2*minheight);
		vertically=true;
		table.insert(layout.roads,{x1,nz,x2,nz});
	end
	if x2-x1>2*minwidth then -- can subdivide horizontaly
		nx = x1+minwidth+math.random()*(x2-x1-2*minwidth);
		horizontaly=true;
		table.insert(layout.roads,{nx,z1,nx,z2});
	end
	
	if horizontaly then -- add new cells
		if vertically then -- horizontally and vertically
      table.insert(layout.cells,{x1,z1,nx,nz,false});
			table.insert(layout.cells,{nx,z1,x2,nz,false});
			table.insert(layout.cells,{x1,nz,nx,z2,false});
			table.insert(layout.cells,{nx,nz,x2,z2,false});
		else -- horizontally
			table.insert(layout.cells,{x1,z1,nx,z2,false});
			table.insert(layout.cells,{nx,z1,x2,z2,false});
		end
	else
		if vertically then -- vertically
			table.insert(layout.cells,{x1,z1,x2,nz,false});
			table.insert(layout.cells,{x1,nz,x2,z2,false});
		else
			return false; -- no subdivide possible
		end
	end
	layout.cells[cell_index][5] = true; -- mark cell for removal
	return true;
end

layout.iterate = function ()
	local not_finished = false; 
	for i = 1, #layout.cells do -- try subdivide all cells in cell list
		if layout.subdivide(i) then not_finished=true end -- at least one remains to be subdivided
	end
	-- remove cells scheduled for removal
	for i = #layout.cells, 1, -1 do -- remove from back to start to prevent idx messup after removal
		if layout.cells[i][5] then table.remove(layout.cells,i) end
	end
  return not_finished; -- if false then its finished
end

layout.generate = function ()
  layout.cells = {{0,0,layout.width,layout.height}};
  layout.roads = {};
  local not_finished = true;
  while not_finished==true do
    not_finished=layout.iterate();
  end
end



-- JUST FOR TEST RENDERING IN THE WORLD
minetest.register_chatcommand("road", { 
	description = "/road seed, will generate and render layout of roads starting at player position",
	privs = {
		interact = true
	},
	func = function(name, param)
		local player = minetest.get_player_by_name(name);
		local pos = player:getpos();
		layout.pos = pos;
		math.randomseed(tonumber(param) or 1);
		local t = os.clock();
		layout.generate();
		local t = os.clock()-t;
		local road,length,dir;
		minetest.chat_send_all("#ROAD LAYOUT GENERATOR: number of roads " .. #layout.roads .. " generation time " .. t .. " seconds ");
		-- rendering
		for i = 1,#layout.roads do
			road = layout.roads[i];
			--minetest.chat_send_all("road " .. i .. " : " .. road[1] .. " " .. road[2] .. " " .. road[3] .. " " .. road[4])
			length = road[3]-road[1] + road[4]-road[2];
			dir = {x=(road[3]-road[1])/length,y=0,z=(road[4]-road[2])/length};
			for j=1,length do
				minetest.set_node({x=pos.x+road[1]+dir.x*j,y=pos.y+dir.y*j,z=road[2]+pos.z+dir.z*j},{name = "default:diamondblock"});
			end
		end
end
});

minetest.register_chatcommand("roadc", { 
	description = "/roadc, will clear render of previously made layout ",
	privs = {
		interact = true
	},
	func = function(name, param)
		local pos = layout.pos;
		for i = 1,#layout.roads do
			road = layout.roads[i];
			--minetest.chat_send_all("road " .. i .. " : " .. road[1] .. " " .. road[2] .. " " .. road[3] .. " " .. road[4])
			length = road[3]-road[1] + road[4]-road[2];
			dir = {x=(road[3]-road[1])/length,y=0,z=(road[4]-road[2])/length};
			for j=1,length do
				minetest.set_node({x=pos.x+road[1]+dir.x*j,y=pos.y+dir.y*j,z=road[2]+pos.z+dir.z*j},{name = "air"});
			end
		end
end
});


