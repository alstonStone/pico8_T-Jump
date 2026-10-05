pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--main--------------------------------------------------------------------------

function _init()
	state="title"
	gm_init()
	kl_init(0,0)
	plr_init()
	bm_init()
end


function _update()
	if state=="title" then
		ts_update()
	elseif state=="game" then
		gm_update()
	elseif state=="game over" then
		go_update()
	end
end


function _draw()
		if state=="title" then
		ts_draw()
	elseif state=="game" then
		gm_draw()
	elseif state=="game over" then
		go_draw()
	end
end
-->8
--block manager-----------------------------------------------------------------

function bm_init()
	bw=8 --block width--
	bh=8 --block height
	blocks={}
end


function bm_update()
	for b in all(blocks) do
		b:update()
	end
end


function bm_draw()
	if plr.is_alive==1 then
		for b in all(blocks) do
			b:draw()
		end
	end
end


function spawn_block(x,y)
	local block={
		x=x,
		y=y,
		w=8,
		h=8,
		landed=false,

		--update position--
		update = function(self)
			if(not self.landed) then
				self.y += gravity
				if check_collision_with_tile(self.x,self.y,bw,bh) or check_block_collisions(self) then
					local tile_y= flr((self.y-bh-1)/8)
					self.y=(tile_y*8)+bh
					self.landed=true
				end
			end
		end,
		
		--draw block--
		draw =function(self)
			spr(3,self.x,self.y)
		end
	}
	if plr.is_alive==1 then
		score+=1*difficulty
	end
	return block
end


-- function spawn_block_random_X()
-- 	add(blocks,spawn_block(flr(rnd(16))*8,0))
-- end

function spawn_block_random_X()
	add(blocks,spawn_block(flr(rnd(16))*8,-8))
end


function remove_blocks_above_yvalue(yval)
	old_blocks=blocks
	blocks={}
	for b in all(old_blocks) do
		if(b.y<yval) then
			add(blocks,b)
		end
	end
	old_blocks=nil
	enable_gravity_for_all_blocks()
end


function enable_gravity_for_all_blocks()
	for b in all(blocks) do
		b.landed = false
	end
end


function bell_curve_16()
    local roll1 = flr(rnd(8))
    local roll2 = flr(rnd(9))
    return roll1 + roll2   -- range 1-16
end



-->8
--player------------------------------------------------------------------------

function plr_init()
	plr={}
	plr.x=63
	plr.y=63
	plr.dx=0
	plr.dy=0
	plr.w=8
	plr.h=8
	
	plr.speed=2
	plr.slow=1
	plr.max_speed=4
	plr.jumped=false
	plr.jump_str=10
	plr.is_gnd=false
	plr.is_alive=1
end


function plr_update()
	if plr.is_alive==1 then
		get_input()
		apply_player_movement_physics()
		move_player()
		plr.is_alive=is_player_alive()
		if plr.is_alive==0 then
			explode(plr.x+4,plr.y+4,50)
			sfx(4,1)
			death_transition()
		end
	end
	update_parts()
end


function plr_draw()
	if plr.is_alive==1 then 
		spr(1,plr.x,plr.y)
	end
	draw_parts()
	print("score: "..tostr(score))
end

function get_input()
	if (btn(⬅️)) plr.dx-=plr.speed
	if (btn(➡️)) plr.dx+=plr.speed
	if plr.is_gnd and (btnp(❎)) then
		plr.dy= -plr.jump_str-(difficulty/2)
		sfx(0,1)
		plr.jumped=true
	end
end


function apply_player_movement_physics()
	if plr.dy>=plr.max_speed then
		plr.dy=plr.max_speed
	end
	if plr.dx>0 then
		plr.dx-=plr.slow
		if plr.dx>plr.max_speed then 
			plr.dx=plr.max_speed
		end
	end
	if plr.dx<0 then
		plr.dx+=plr.slow
		if plr.dx< -plr.max_speed then
			plr.dx= -plr.max_speed
		end
	end
	if (plr.x<0) plr.x=0
	if (plr.x>120) plr.x=120		
end


function move_player()
	--horizontal--
	plr.x+=plr.dx
	if check_collision_with_tile(plr.x,plr.y,plr.w,plr.h) or check_block_collisions(plr) then
		if plr.dx>0 then
			--hit a wall on the right side--
			local tile_x=flr((plr.x+plr.w-1)/8)
			plr.x = (tile_x*8)-plr.w
		elseif plr.dx<0 then
			--hit a wall on the left--
			local tile_x=flr(plr.x/8)
			plr.x=tile_x*8+8
		end
		plr.dx=0
	end
	--vertical--
	apply_gravity()
	plr.is_gnd=false
	plr.y+=plr.dy
	if check_collision_with_tile(plr.x,plr.y,plr.w,plr.h) or check_block_collisions(plr)then
		if plr.dy>0 then
			--landed--
			local tile_y=flr((plr.y-plr.h-1)/8)
			plr.y=(tile_y*8)+plr.h
			plr.is_gnd=true
			if plr.jumped==true then
				sfx(1,1)
				plr.jumped=false
			end
		elseif plr.dy<0 then
			--hit head--
			local tile_y=flr((plr.y+plr.h)/8)
			plr.y=tile_y*8+4
		end
		plr.dy=0
	end
end


function is_player_alive()
	local plr_tile_x=flr(plr.x/8)
	local plr_tile_y=flr(plr.y/8)
	for b in all(blocks) do
		local b_tile_x=flr(b.x/8)
		local b_tile_y=flr(b.y/8)
		if plr_tile_x==b_tile_x and plr_tile_y==b_tile_y then
			return 0		
		end
	end
	return 1
end

parts = {}

function explode(x, y, n)
  for i=1,n do
    local a = rnd(1)             -- random direction (PICO-8 angles are 0-1)
    local spd = 0.5 + rnd(2.5)   -- random speed
    add(parts, {
      x=x, y=y,
      dx=cos(a)*spd,
      dy=sin(a)*spd,
      r=1+rnd(2),                -- starting radius
      age=0,
      life=15+rnd(15)            -- frames until it dies
    })
  end
end

function update_parts()
  for p in all(parts) do
    p.x += p.dx
    p.y += p.dy
    p.dx *= 0.92                 -- friction
    p.dy *= 0.92
    p.r -= 0.05                  -- shrink
    p.age += 1
    if p.age > p.life or p.r <= 0 then
      del(parts, p)
    end
  end
end

function draw_parts()
  for p in all(parts) do
    local t = p.age / p.life
    local c = 7                  -- white
    if t > 0.3 then c = 6 end    -- light gray
    if t > 0.6 then c = 13 end   -- indigo-gray
    if t > 0.8 then c = 5 end    -- dark gray
    circfill(p.x, p.y, p.r, c)
  end
end

function death_transition()
	add(timers,call_function_after_x_seconds(1,switch_game_over))
end

function switch_game_over()
	state="game over"
	go_init()
end

-->8
--physics-----------------------------------------------------------------------
	

function check_collision_with_tile(x,y,w,h)
	return solid_at(x    ,y)
		or    solid_at(x+w-1,y)
		or    solid_at(x    ,y+h-1)
		or    solid_at(x+w-1,y+h-1)
end


function solid_at(pixel_x,pixel_y)
	local tile_x=flr(pixel_x/8)
	local tile_y=flr(pixel_y/8)
	for b in all(blocks) do
		if b.x==pixel_x or b.y==pixel_x then
			local block_collision=true
		end
	end
	return fget(mget(tile_x,tile_y),0) or block_collision
end


function check_block_collisions(object)
	for b in all(blocks) do
		if b ~= object then
			if check_collision_with_object(b,object) then
				return true
			end
		end
	end
end


function check_collision_with_object(a, b)
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end


function apply_gravity()
	plr.dy+=gravity
	if (plr.dy>=gravity_max) plr.dy=gravity_max
end



-->8
--game logic--------------------------------------------------------------------

--gm is Game Manager--
function gm_init()
	gravity=2
	gravity_max=15
	score=0
	difficulty=0
	timers={}
	add(timers,call_function_every_x_seconds(.5,spawn_block_random_X))
	-- add(timers,call_function_every_x_seconds(10,remove_blocks_above_yvalue,96))
	add(timers,kill_line_timer(4))
end


function gm_update()
	for t in all (timers) do
		t:update()
	end
	kl_update()
	plr_update()
	bm_update()
end

function gm_draw()
	cls()
	map()
	kl_draw()
	plr_draw()
	bm_draw()
end


function call_function_after_x_seconds(seconds,func_to_call)
	return{
	time_left=seconds*60,
	update=function(self)
		self.time_left-=1
		if self.time_left<=0 then
			func_to_call()
		end
	end
	}
end




function call_function_every_x_seconds(seconds,func_to_call)
	return{
	time_left=seconds*60,
	update=function(self)
		self.time_left-=1
		if self.time_left<=0 then
			func_to_call()
			--self.time_left=self.start_time
			self.time_left=seconds*60
		end
	end
	}
end


function call_function_every_x_seconds(seconds,func_to_call,value)
	return{
	time_left=seconds*60,
	update=function(self)
		self.time_left-=1
		if self.time_left<=0 then
			func_to_call(value)
			--self.time_left=self.start_time
			self.time_left=seconds*60
		end
	end
	}
end


function call_function_every_x_seconds(seconds,func_to_call,value1,value2)
	return{
	time_left=seconds*60,
	update=function(self)
		self.time_left-=1
		if self.time_left<=0 then
			func_to_call(value1,value2)
			--self.time_left=self.start_time
			self.time_left=seconds*60
		end
	end
	}
end


function kill_line_timer(seconds)
	return{
	time_left=seconds*60,
	update=function(self)
		self.time_left-=1
		if self.time_left<=0 then
			kl_init(difficulty,1.6)
			--self.time_left=self.start_time
			self.time_left=seconds*60
		end
	end
	}
end


-->8
--kill line---------------------------------------------------------------------

function kl_init(row,time)
	kl={}
	kl.y=(120-(row*8))
	kl.row=row
	kl.active=true
	kl.displayed=false
	kl.display_count=3
	kl.display_frames=5
	kl.display_frames_count=0
	kl.countdown_time=time*60
	kl.countdown_interval=kl.countdown_time/kl.display_count
end


function kl_update()
	if kl.active then
		kl.countdown_time-=1
		if kl.countdown_time<=(kl.countdown_interval*kl.display_count) then
			kl_display()
			sfx(3,2)
			kl.display_count-=1
		end
		
		if kl.displayed then
			if kl.display_frames_count<=kl.display_frames then
				kl.display_frames_count+=1
			else
				kl.displayed=false
				kl.display_frames_count=0
			end
		end

		if kl.display_count<0 then
			remove_blocks_above_yvalue(kl.y)
			if plr.y>=kl.y then
				if plr.is_alive==1 then
					plr.is_alive=0
					explode(plr.x+4,plr.y+4,50)
					sfx(4,1)
					death_transition()
				end
			end
			sfx(2,2)
			add(timers,call_function_every_x_seconds(rnd(2)+.5,spawn_block_random_X))
			difficulty+=1
			kl.active=false
			kl.displayed=false
		end
	end
end

function kl_activate()
	kl.active=true
end

function kl_display()
	kl.displayed=true
end

function kl_draw()
	if(kl.displayed) then
		for yv=1,kl.row do
			for xv=1,16 do
				spr(9,(xv-1)*8,120-(yv*8))
			end
		end
	end
end



-->8
--game over--

function go_init()

end


function go_update()
	if btn(❎) then
		run()
	end

end


function go_draw()
	cls()
	print("score: "..score,50,50,7)
	print("press ❎ to play again",30,100,7)

end


-->8
--title screen--

function ts_init()

end


function ts_update()
	if btn(❎) then
		state="game"
		gm_init()
	end
end


function ts_draw()
	cls()
	print("t-jump",50,50,7)
	print("press ❎ to start",30,60,7)

end



__gfx__
00000000007777000000000066666666999999996666666666666666550000000000005588888888000000000000000000000000000000000000000000000000
00000000077777700111111064444466000000006644444444444466685500000000558688888888000000000000000000000000000000000000000000000000
00700700777777770111111064444646000000006464444444444646686855500555868688888888000000000000000000000000000000000000000000000000
00077000777777770111111064446446000000006446444444446446686868688686868688888888000000000000000000000000000000000000000000000000
00077000777777770111111064464446000000006444644444464446686868688686868688888888000000000000000000000000000000000000000000000000
00700700777777770111111064644446000000006444464444644446686855500555868688888888000000000000000000000000000000000000000000000000
00000000077777700111111066444446000000006444446446444446685500000000558688888888000000000000000000000000000000000000000000000000
00000000007777000000000066666666000000006444444664444446550000000000005588888888000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006444444664444446000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006444446446444446000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006444464444644446000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006444644444464446000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006446444444446446000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006464444444444646000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006644444444444466000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000180501605013050110500d050090500505003050020500105001050070500f0501905020050250502c05032050380503b0503e0003e0003e0003e0003e0003d0003d0003c0003c0003b0003b0003b000
000100003d61037610326102f6102b610296102761024610216101e6101a6101761013610106100c6100961005610036100061000600006000060000600006000060000600006000060000600006000060000600
00010000036500365004650056500665007650086500a6500c6500f65014650186501e650256502f650366503a6503c6503a6503765031650296501e65016650116500e6500a6500765004650026500165001650
00200000084501745018400014000140001400014000140001400014000040000400004000a4000a4002340023400234002340023400224002240022400224002240022400234002340023400234000040000400
000100003937039370393703a37039370393703937039370393703937039370393703837038370373703737037370363703637036370363703637033370303702d37029370223701e3701b37015370113700d370
