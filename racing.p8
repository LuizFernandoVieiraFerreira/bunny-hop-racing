pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

-- MAIN

function _init()
  change_color_pallete()
  init_vec3()
  init_global_constants()
  init_global_variables()
  set_state(STATE_MENU)
end   

function change_color_pallete()
  _pal = { 131, 131, 131, 131, 3, 3, 139, 138, 139, 139, 138, 3, 3, 3, 139, 138 }
  --if current_color_pallete == 1 then
    --_pal = { 3, 3, 3, 3, 139, 139, 138, 135, 138, 138, 135, 139, 139, 139, 138, 135 }
  --elseif current_color_pallete == 2 then
    --_pal = { 0, 0, 0, 0, 5, 5, 6, 7, 6, 6, 7, 5, 5, 5, 6, 7 }
  --elseif current_color_pallete == 3 then
    --_pal = { 132, 132, 132, 132, 4, 4, 143, 15, 143, 143, 15, 4, 4, 4, 143, 15 }
  --elseif current_color_pallete == 4 then 
    --_pal = { 129, 129, 129, 129, 1, 1, 140, 12, 140, 140, 12, 1, 1, 1, 140, 12 }
  --elseif current_color_pallete == 5 then 
    -- = { 130, 130, 130, 130, 2, 2, 136, 14, 136, 136, 14, 2, 2, 2, 136, 14 }
  --end
  for i, c in pairs(_pal) do
    pal(i-1, c, 1)
  end
  palt(0, false)
  palt(14, true)
end

function init_global_constants()
  STATE_MENU = 1
  STATE_GAME = 2
  STATE_POSTRACE = 3
  ACCELERATION = 0.002
  BRAKE = 0.0045
  COAST = 0.001
  LAPS = 3
  STUN_FRAMES = 30
  SEGMENT_LENGTH = 1
  SEGMENT_WIDTH = 3
  ANGLE_F = 0.005
  TUNNEL_HEIGHT = 4
  SCREEN_DIST = 64
  NPC_COUNT = 9
  CAR_ELASTIC = .4
  NPC_NAMES = {
    "npc1",
    "npc2",
    "npc3",
    "npc4",
    "npc5",
    "npc6",
    "npc7",
    "npc8",
    "npc9"
  }
end

function init_global_variables()
  current_color_pallete = 0
  key={
    left = 0,
    right = 1,
    up = 2,
    down = 3,
    a = 5,
    b = 4,
  }
  clp = {
    l = 0,
    r = 128,
    t = 0,
    b = 128
  }
  state = 0
  stage = 1
  demo = false
  demo_counter = 0
  bg_co = {}
  fg_co = {}
  draw_co = {}
  sprites = {}
  camoffs = vec3.new(0, -2.5, -2)
  cam = { n=1, s=0, pos = vec3.zero }
  drawsegct = 40
  segxtiles = 2
  segytiles = 1
  framect = 0
  hideui = false
  sky_color = 7
  sprbuf = {}
  carbox = {
    mn = vec3.new(-.5, 0, -.2),
    mx = vec3.new(.5, .5, .2)
  }
  carwid = .5
  autoaccel = false
  npctypes = {}
  player = {}
  npcs = {}
  cars = {}
  leaderboard = {}
  podium = {}
end

function init_vec3()
  vec3 = {}
  vec3.new = function(x, y, z)
    local v = { x = x, y = y, z = z }
    setmetatable(v, vec3.mt)
    return v
  end

  vec3.copy = function(v)
    return vec3.new(v.x, v.y, v.z)
  end

  vec3.neg = function(a)
    return vec3.new(-a.x, -a.y, -a.z)
  end

  vec3.add = function(a,b)
    return vec3.new(a.x + b.x, a.y + b.y, a.z + b.z)
  end

  vec3.sub = function(a,b)
    return vec3.new(a.x - b.x, a.y - b.y, a.z - b.z)
  end

  vec3.scale = function(v,scale)
    return vec3.new(v.x * scale, v.y * scale, v.z * scale)
  end

  vec3.div = function(v,d)
    return vec3.new(v.x / d, v.y / d, v.z / d)
  end

  vec3.len = function(v)
    return sqrt(vec3.dot(v, v))
  end

  vec3.mt = {}
  vec3.mt.__unm = vec3.neg
  vec3.mt.__add = vec3.add
  vec3.mt.__sub = vec3.sub
  vec3.mt.__mul = function(a, b)
    if getmetatable(a) ~= vec3.mt then
      return vec3.scale(b, a)
    elseif getmetatable(b) ~= vec3.mt then
      return vec3.scale(a, b)
    else
      return vec3.dot(a, b)
    end
  end
  vec3.mt.__div = vec3.div
  vec3.mt.__tostring = vec3.tostring
  vec3.mt.__len = vec3.len
  vec3.mt.__concat = function(a, b)
    if getmetatable(a) == vec3.mt then
      a = vec3.tostring(a)
    end
    if getmetatable(b) == vec3.mt then
      b = vec3.tostring(b)
    end
    return a..b
  end

  vec3.zero = vec3.new(0, 0, 0)
end

function _update()
  if (run_fg()) return
  run_co(bg_co)
  if state == STATE_MENU then
    update_menu()
  elseif state == STATE_GAME then
    update_game()
  elseif state == STATE_POSTRACE then
    update_post_race()
  end
end

function _draw()
  if state == STATE_MENU then
    draw_menu()
  elseif state == STATE_GAME then 
    draw_game()
  elseif state == STATE_POSTRACE then
    draw_post_race()
  end
 run_co(draw_co)
end

function set_state(m)
  if (state == m) return

  if state == STATE_GAME then
    menuitem(1)
    menuitem(2)
  end
 
  fg_co={}
  bg_co={}
  draw_co={}

  state = m
  sprites = {}
  demo_counter = 0

  if state == STATE_MENU then
    init_menu()
  elseif state == STATE_GAME then
    init_game()
    menuitem(
      1,
      "restart race",
      function()
        set_state(0)
        set_state(STATE_GAME)
      end)
    menuitem(2,"quit to menu", function() set_state(STATE_MENU) end)  
  elseif state == STATE_POSTRACE then
    init_post_race()
  end
end

-- MENU

function init_menu()
  menu_track = 1
  menu_tracks = {
    { name = "forest", sp = 224 },
    { name = "desert", sp = 228 },
    { name = "snow", sp = 230 },
    { name = "haunted", sp = 226 },
  }
end

function update_menu()
  demo_counter += 1

  if (btnp(➡️) and (menu_track == 1 or menu_track == 3)) menu_track += 1 demo_counter = 0
  if (btnp(⬅️) and (menu_track == 2 or menu_track == 4)) menu_track -= 1 demo_counter = 0
  if (btnp(⬆️) and (menu_track == 3 or menu_track == 4)) menu_track -= 2 demo_counter = 0
  if (btnp(⬇️) and (menu_track == 1 or menu_track == 2)) menu_track += 2 demo_counter = 0

  if btnp(key.a) then 
    demo = false
    stage = menu_track
    set_state(STATE_GAME)
  elseif btnp(key.b) then
    change_color_pallete()
    current_color_pallete = wrap(current_color_pallete, 5)
  elseif demo_counter > 900 then
    demo = true
    stage = flr(rnd(#menu_tracks)) + 1
    set_state(STATE_GAME)
  end
end

function draw_menu()
  framect += 1
  cls(7)
  spr(202, 24, 8, 6, 2)
  spr(234, 76, 8, 4, 2)
  spr(48, 20, 30, 1, 1)
  spr(48, 28, 30, 1, 1)
  spr(48, 36, 30, 1, 1)
  spr(48, 44, 30, 1, 1)
  spr(238, 58, 28, 2, 2)
  spr(48, 76, 30, 1, 1)
  spr(48, 84, 30, 1, 1)
  spr(48, 92, 30, 1, 1)
  spr(48, 100, 30, 1, 1)
  draw_centered_text("-by gamb", 118, 5, 6)
  rect(46-1, 50-1, 46+16, 50+16, cond(menu_track == 1, 0, 6))
  rect(66-1, 50-1, 66+16, 50+16, cond(menu_track == 2, 0, 6))
  rect(46-1, 70-1, 46+16, 70+16, cond(menu_track == 3, 0, 6))
  rect(66-1, 70-1, 66+16, 70+16, cond(menu_track == 4, 0, 6))
  spr(224, 46, 50, 2, 2)
  spr(228, 66, 50, 2, 2)
  spr(230, 46, 70, 2, 2)
  spr(226, 66, 70, 2, 2)
  draw_centered_text(menu_tracks[menu_track].name, 90, 5, 6)
  draw_text("⬅️➡️ select 🅾️ start", 20, 106, 5, 6)
end

-- GAME

function init_game()
  init_game_variables()
  init_types()
  init_track()
  init_cars()
  init_race()
  update_sprites(cam, drawsegct)
end

function init_game_variables()
  npcs = {}
  cars = {}
  leaderboard = {}
  podium = {}
  track = {}
  topspd = 0.3
  segct = 0
  podiumspots = { "1st", "2nd", "3rd" }
  player = {
    lap = 1,
    n = 1,               
    s = 0,               
    pos = vec3.zero,
    vel = vec3.new(0, 0, 0),
    sp = nil,
    index = 0,
    name = "player",
    fin = false,
    topspd = topspd,
    stun = 0,
    steer = 0
  }
  sprites = {
    from = { n=1, s=0 },
    to = { n=1, s=0 },
    range = 0,
    s = {}
  }
  pr={}
end

function init_types()
  init_car_types()
  init_player_types()
  init_npc_types()
  init_other_types()
end

function init_car_types()
  cartype = {
    name = "car",
    tex = {
      { sx = 24, sy = 8, sw = 8, sh = 8, maxw = 10 },
      { sx = 24, sy = 16, sw = 16, sh = 16, maxw = 18 },
      { sx = 96, sy = 64, sw = 32, sh = 32 }
    },
    w = 1,
    h = 1,
  }
  cartypel = duplicate(cartype)
  cartypel.tex = {{ sx = 64, sy = 64, sw = 32, sh = 32 }}
  cartyper = duplicate(cartypel)
  cartyper.flipx = true
  cartypes = { cartypel, cartype, cartyper }
end

function init_player_types()
  playertype = {
    name = "car",
    tex = {
      { sx = 96, sy = 0, sw = 32, sh = 32 }
    },
    w = 1,
    h = 1,
  }
  playertypel = duplicate(playertype)
  playertypel.tex = {{ sx = 96, sy = 32, sw = 32, sh = 32 }}
  playertyper = duplicate(playertypel)
  playertyper.flipx = true
  playertypes = { playertypel, playertype, playertyper }
end

function init_npc_types() 
  local speeds = {}
  for i=1,NPC_COUNT do
    add(speeds, ((i/NPC_COUNT)*.45+.4)*topspd)
  end
  shuffle(speeds)
  for i=1,NPC_COUNT do
    add(npctypes, {
      name = NPC_NAMES[i],
      topspd = speeds[i]
    })
  end 
end

function init_other_types()
  -- forest
  bg_tree = {
    tex = {
      { sx=0, sy=64, sw=32, sh=32 }
    }, 
    w = 4,
    h = 4,
    spacing = 3,
  }
  bg_carot = {
    tex = {
      { sx = 32, sy = 32, sw = 16, sh = 16 }
    }, 
    w = 1,
    h = 1,
    spacing = 2,
  }
  bg_lamp = {
    tex = {
      { sx = 24, sy = 0, sw = 16, sh = 8 }
    }, 
    w = .5,
    h = .25,
    spacing = 2,
  }
  tnl_whitelit = {
    front = 0,
    wall = { 0, 0 },
    wallspacing = 1,
    bgceil = bg_lamp
  }
  road_pebbles = {
    tex = {
      { sx = 0, sy = 16, w = 8, h = 8, maxw = 6 },
    },
    gnd = { 6, 5 },
    gndspacing = 2
  }
  road_asphalt = {
    tex = {
      { sx = 8, sy = 16, w = 16, h = 16 }
    },
    gnd = { 6, 5 },
    gndspacing = 2
  }
  sc_forest_leafs = {
    road = road_asphalt,
    bgl = bg_tree,
    bgr = bg_tree,
    tnl = tnl_whitelit
  }
  sc_forestasphalt = {
    road = road_pebbles,
    bgl = bg_carot,
    bgr = bg_carot,
    tnl = tnl_whitelit
  }

  -- desert
  bg_cactus = {
    tex = {
      { sx = 40, sy = 0, sw = 16, sh = 32 }
    },
    w = 1,
    h = 2,
    spacing=4,
  }
  bg_skeleton = {
    tex = {
      { sx = 32, sy = 80, sw = 16, sh = 16 }
    },
    w = 1.5,
    h = 1.5,
    spacing = 6,
  }
  bg_sign_right = {
    tex = {
      { sx = 0, sy = 32, sw = 16, sh = 16 }
    },
    w = 1,
    h = 1,
    spacing = 4,
  }
  bg_sign_left = duplicate(bg_sign_right)
  bg_sign_left.flipx = true
  road_desert = {
    tex = {
      { sx = 0, sy = 48, w = 16, h = 16 }
    },
    gnd = { 7, 7 },
    gndspacing = 2
  }
  tnl_desert = {
    front = 0,
    wall = { 5, 0 },
    wallspacing = 1,
    bgceil = bg_lamp
  }
  sc_desert_cactus = {
    road = road_desert,
    bgl = bg_cactus,
    bgr = bg_cactus,
    tnl = tnl_desert
  }
  sc_desert_skeleton = {
    road = road_desert,
    bgl = bg_skeleton,
    bgr = bg_skeleton,
    tnl = tnl_desert
  }
  sc_desert_sign_left = {
    road = road_desert,
    bgl = bg_sign_right,
    tnl = tnl_desert
  }
  sc_desert_sign_right = {
    road = road_desert,
    bgr = bg_sign_left,
    tnl = tnl_desert
  }

  -- snow
  bg_snowman = {
    tex = {
      { sx = 48, sy = 80, sw = 16, sh = 32 }
    }, 
    w = 1,
    h = 2,
    spacing = 4,
  }
  bg_iglu = {
    tex = {
      { sx = 32, sy = 56, sw = 32, sh = 24 }
    }, 
    w = 3,
    h = 2.25,
    spacing = 10,
  }
  bg_ice_wall_left={
    tex = {
      { sx = 56, sy = 0, sw = 8, sh = 32 }
    },
    w = 1,
    h = 4,
    spacing = 2,
  }
  bg_ice_wall_right={
    tex = {
      { sx = 88, sy = 32, sw = 8, sh = 32 }
    },
    w = 1,
    h = 4,
    spacing = 2,
  }
  bg_ice_ceil = {
    tex = {
      { sx = 32, sy = 48, sw = 32, sh = 8 }
    },
    w = 5,
    h = 1,
    spacing = 2
  }
  tnl_snow = {
    front = 6,
    wall = { 7, 7 },
    wallspacing = 1,
    bgl=bg_ice_wall_left,
    bgr=bg_ice_wall_right,
    bgceil = bg_ice_ceil
  }
  road_snow = {
    tex = {
      { sx = 16, sy = 48, w = 16, h = 16 }
    },
    gnd = { 7, 7 },
    gndspacing = 2
  }
  sc_snow = {
    road = road_snow,
    bgl = bg_snowman,
    bgr = bg_snowman,
    tnl = tnl_snow
  }
  sc_snow_iglu = {
    road = road_snow,
    bgl = bg_iglu,
    bgr = bg_iglu,
    tnl = tnl_snow
  }
  sc_snow_iglu_left = {
    road = road_snow,
    bgl = bg_iglu,
    tnl = tnl_snow
  }
  sc_snow_iglu_right = {
    road = road_snow,
    bgr = bg_iglu,
    tnl = tnl_snow
  }

  -- haunted
  bg_ghost = {
    tex = {
      { sx = 80, sy = 16, sw = 16, sh = 16 }
    }, 
    w = 1,
    h = 1,
    spacing = 6,
  }
  bg_tombstone = {
    tex={
      { sx = 48, sy = 32, sw = 16, sh = 16 }
    }, 
    w = 1,
    h = 1,
    spacing = 8,
  }
  bg_lantern = {
    tex = {
      { sx = 64, sy = 16, sw = 16, sh = 16 }
    }, 
    w = 1,
    h = 1,
    spacing = 2,
  }
  bg_chandelier  = {
    tex = {
      { sx = 64, sy = 0, sw = 32, sh = 16 }
    }, 
    w = 2,
    h = 1,
    spacing = 4,
  }
  road_haunted = {
    tex = {
      { sx = 64, sy = 48, w = 16, h = 16 }
    },
    gnd = { 5, 5 },
    gndspacing = 5
  }
  road_haunted_bridge={
    tex = {
      { sx = 64, sy = 32, w = 16, h = 16 }
    },
    gnd = { 1, 1 },
    gndspacing = 5
  }
  tnl_haunted = {
    front = 6,
    wall = { 5, 0 },
    wallspacing = 1,
    bgceil = bg_chandelier
  }
  sc_haunted_ghost = {
    road = road_haunted_bridge,
    bgl = bg_ghost,
    bgr = bg_ghost,
    tnl = tnl_haunted
  }
  sc_haunted_lantern = {
    road = road_haunted,
    bgl = bg_lantern,
    bgr = bg_lantern,
    tnl = tnl_haunted
  }
  sc_haunted_tombstone = {
    road = road_haunted,
    bgl = bg_tombstone,
    bgr = bg_tombstone,
    tnl = tnl_haunted
  }

  -- finish
  bg_finish = {
    tex = {
      { cx = 1, cy = 14, cw = 6, ch = 1, maxw = 8 },
      { cx = 2, cy = 7, cw = 12, ch = 2 }
    },
    w = 6,
    h = 1,
    spacing = 2,
    offset = { x=0, y=-3.5 }
  }
  road_finish = {
    tex = {
      { sx = 0, sy = 24, w = 8, h = 8 }
    },
    gnd = { 7 },
    gndspacing = 1
  }
  sc_finish = {
    road = road_finish,
    bg = bg_finish,
    tnl = tnl_whitelit
  }
end

function init_track()
  track = {}
  segct = 0   
  sky_color = 7

  -- first segment has always lenght one
  -- 5 < ct < 15
  -- -8 < turn < 8
  -- -25 < pitch < 25
  if stage == 1 then
    track = {
      { ct = 1, tu = 0, pi = 0, sc = sc_forest_leafs, tnl = false },
      { ct = 15, tu = 0, pi = 15, sc = sc_forest_leafs, tnl = false },
      { ct = 15, tu = 0, pi = -25, sc = sc_forest_leafs, tnl = false },
      { ct = 10, tu = -4, pi = 5, sc = sc_forest_leafs, tnl = false },
      { ct = 15, tu = 6, pi = 5, sc = sc_forest_leafs, tnl = false },
      { ct = 20, tu = 0, pi = -20, sc = sc_forest_leafs, tnl = false },
      { ct = 20, tu = 0, pi = 20, sc = sc_forestasphalt, tnl = false },
      { ct = 20, tu = 0, pi = 20, sc = sc_forestasphalt, tnl = false },
      { ct = 15, tu = 0, pi = 0, sc = sc_forestasphalt, tnl = true },
      { ct = 15, tu = 4, pi = 4, sc = sc_forestasphalt, tnl = true },
      { ct = 15, tu = -4, pi = 4, sc = sc_forestasphalt, tnl = true },
      { ct = 25, tu = 0, pi = 0, sc = sc_forestasphalt, tnl = false },
    }
  elseif stage == 2 then
    sky_color = 6
    track = {
      { ct = 1, tu = 0, pi = 0, sc = sc_desert_cactus, tnl = false },
      { ct = 30, tu = 1, pi = 0, sc = sc_desert_cactus, tnl = false },
      { ct = 30, tu = -1, pi = 0, sc = sc_desert_cactus, tnl = false },
      { ct = 25, tu = -3, pi = -15, sc = sc_desert_sign_left, tnl = false },
      { ct = 25, tu = 4, pi = 10, sc = sc_desert_sign_right, tnl = false },
      { ct = 25, tu = 3, pi = 10, sc = sc_desert_skeleton, tnl = false },
      { ct = 30, tu = -4, pi = -20, sc = sc_desert_skeleton, tnl = false },
      { ct = 30, tu = -4, pi = -10, sc = sc_desert_cactus, tnl = true },
      { ct = 15, tu = 4, pi = 4, sc = sc_desert_cactus, tnl = true },
      { ct = 15, tu = -4, pi = 4, sc = sc_desert_cactus, tnl = true },
      { ct = 25, tu = 0, pi = -4, sc = sc_desert_cactus, tnl = true },
    }
  elseif stage == 3 then
    track = {
      { ct = 1, tu = 0, pi = 0, sc = sc_snow, tnl = false },
      { ct = 40, tu = 1, pi = -4, sc = sc_snow, tnl = false },
      { ct = 25, tu = -4, pi = 0, sc = sc_snow_iglu_left, tnl = false },
      { ct = 25, tu = 6, pi = 20, sc = sc_snow_iglu_right, tnl = false },
      { ct = 15, tu = -4, pi = -2, sc = sc_snow_iglu_left, tnl = false },
      { ct = 10, tu = 0, pi = 5, sc = sc_snow_iglu, tnl = false },
      { ct = 10, tu = 4, pi = -5, sc = sc_snow_iglu, tnl = false },
      { ct = 60, tu = 0, pi = 25, sc = sc_snow, tnl = true },
      { ct = 30, tu = -4, pi = -10, sc = sc_snow, tnl = true },
      { ct = 30, tu = 4, pi = 0, sc = sc_snow, tnl = true },
      { ct = 30, tu = -4, pi = 0, sc = sc_snow, tnl = true },
      { ct = 40, tu = -1, pi = -4, sc = sc_snow, tnl = false },
    }
  elseif stage == 4 then
    sky_color = 1
    track = {
      { ct = 1, tu = 0, pi = 0, sc = sc_haunted_tombstone, tnl = false },
      { ct = 70, tu = 0, pi = 10, sc = sc_haunted_tombstone, tnl = false },
      { ct = 15, tu = -4, pi = -4, sc = sc_haunted_lantern, tnl = false },
      { ct = 15, tu = 4, pi = 4, sc = sc_haunted_lantern, tnl = false },
      { ct = 15, tu = -4, pi = 0, sc = sc_haunted_lantern, tnl = false },
      { ct = 10, tu = -4, pi = 0, sc = sc_haunted_ghost, tnl = false },
      { ct = 4, tu = 0, pi = 0, sc = sc_haunted_ghost, tnl = false },
      { ct = 5, tu = 4, pi = 0, sc = sc_haunted_ghost, tnl = false },
      { ct = 10, tu = 0, pi = 0, sc = sc_haunted_ghost, tnl = false },
      { ct = 5, tu = -8, pi = -5, sc = sc_haunted_ghost, tnl = true },
      { ct = 5, tu = 8, pi = 5, sc = sc_haunted_ghost, tnl = true },
      { ct = 40, tu = 0, pi = -25, sc = sc_haunted_ghost, tnl = true },
      { ct = 80, tu = 2, pi = 20, sc = sc_haunted_ghost, tnl = true },
      { ct = 30, tu = -2, pi = 0, sc = sc_haunted_ghost, tnl = true },
      { ct = 20, tu = 0, pi = 0, sc = sc_haunted_tombstone, tnl = false },
    }
  end

  track[1].sc = sc_finish
  track[1].ct = 1
  track[1].pi = track[#track-1].pi

  local prvpi = track[#track].pi
  segct = 0
  for i=1,#track do
    track[i].sp = prvpi
    track[i].pd = (track[i].pi-track[i].sp)/track[i].ct
    track[i].seg = segct
    segct += track[i].ct    
    prvpi = track[i].pi
  end 
end

function init_cars()
  local p={n=2,s=0}
  shuffle(npctypes)   
   
  for i=0,NPC_COUNT do   
   
    local x=(i%2)*2-1
    local pos=vec3.new(x*SEGMENT_WIDTH*.33,0,0)
   
    local sp={}
    if i>0 then
      sp={
        typ=cartype,
        pos=pos,
        n=p.n,
        s=p.s,
        temp=false,
        index=i
      }
    end

    if i==0 then
      sp={
        typ=playertype,
        pos=pos,
        n=p.n,
        s=p.s,
        temp=false,
        index=i
      }
    end

    add(sprites.s,sp)
       
    if i==0 then
      player.sp=sp
      player.n=p.n
      player.s=p.s
      player.pos=pos
      add(cars,player)
      add(leaderboard,player)
    else
      local typ=npctypes[i]
      local npc={
        lap=1,
        n=p.n,
        s=p.s,
        pos=pos,
        vel=vec3.new(0,0,0),
        sp=sp,
        topspd=typ.topspd,
        index=i,
        name=typ.name,
        fin=false,
        stun=0
      }
      add(npcs,npc)
      add(cars,npc)
      add(leaderboard,npc)
    end
    
    for j=1,15 do
      advance_ptr(p)
    end
  end
  
  position_cam()
  sort_leaderboard()
end

function position_cam()
  copy_ptr(player,cam)   
  cam.pos.x*=0.85
end 

function init_race()
  do_infg(pre_race_sequence)
end

function do_infg(fn)
  add(fg_co, cocreate(fn))
end

function update_sprites(from,range)
  local sp=sprites.s
  sort_ptrs(sp)

  -- advance from pointer. 
  -- remove any off-screen sprites
  local f=sprites.from
  while f.n~=from.n or f.s~=from.s do
    for s in all(sp) do
    if s.temp and s.n==f.n and s.s==f.s then
      del(sp,s)
    end
    end    
    advance_ptr(f)
    sprites.range-=1
  end
 
  -- advance to pointer
  local t=sprites.to
  while sprites.range<range do
    local tr=track[t.n]
    local sc=tr.sc
    local seg=tr.seg+t.s
    if not tr.tnl then
      if sc.bgl~=nil and seg%sc.bgl.spacing==0 then
        make_bg_sprite(sc.bgl,t,-1,tr.tnl)
      end
      if sc.bgr~=nil and seg%sc.bgr.spacing==0 then
        make_bg_sprite(sc.bgr,t,1,tr.tnl)
      end
      if sc.bg~=nil and seg%sc.bg.spacing==0 then
        make_bg_sprite(sc.bg,t,0,tr.tnl)
      end
    else
      local tnl=sc.tnl
      if tnl.bgl~=nil and seg%tnl.bgl.spacing==0 then
        make_bg_sprite(tnl.bgl,t,-1,tr.tnl)
      end
      if tnl.bgr~=nil and seg%tnl.bgr.spacing==0 then
        make_bg_sprite(tnl.bgr,t,1,tr.tnl)
      end
      if tnl.bgceil~=nil and seg%tnl.bgceil.spacing==0 then
        make_bg_sprite(tnl.bgceil,t,0,tr.tnl)
      end
    end
    advance_ptr(t)  
    sprites.range+=1
  end

  sort_ptrs(sp) 
end

function update_game()
  if stage == 3 then
    if (rnd(10)>2) then add_pr() end
    foreach(pr, upd_pr)
  end

  update_cars()
  update_collisions() 
  update_sprites(cam,drawsegct)
  update_leaderboard()
  update_podium()
 
  if(demo and btnp(key.a))set_state(STATE_MENU)
  if player.lap>LAPS then 
    demo_counter+=1
    if demo and demo_counter>300 then
      set_state(STATE_MENU)
    end
    if btnp(key.a) then
      for i=1,#leaderboard do
          local car=leaderboard[i]
          if(not car.fin)add(podium,car)
      end               
      set_state(STATE_POSTRACE)
    end
  end 
end

function update_cars()
  sort_ptrs(cars)
  update_player()
  update_npcs()  
end

function update_player()
  local fin=player.lap>LAPS
 
  if fin or demo then
    do_car_ai(player)
    player.sp.typ=cartype
  else 
    do_player_input()
  end

  update_car_sprite(player)
  if fin then 
    if(cam.pos.x>-2.7)cam.pos.x-=0.03
    if(not track[1].tnl and cam.pos.y>-5)cam.pos.y-=0.03
  else
    position_cam()
  end
end

function do_player_input() 
  -- centrifugal force
  local t=track[player.n]
  player.vel.x=t.tu*player.vel.z*0.11
 
  -- ground friction
  if abs(player.pos.x)>SEGMENT_WIDTH and player.vel.z>0.05 then
    player.vel.z-=0.0075
    autoaccel=false
  end   

  -- player input
  local steer=min(player.vel.z/0.075,1)
  if (btn(⬆️) or autoaccel) and player.stun==0 then
    player.vel.z+=ACCELERATION
    autoaccel=true
  else
    player.vel.z-=COAST
  end
  if btn(⬇️) then
    player.vel.z-=BRAKE
    autoaccel=false
  end
  if btnp(key.b) then
    change_color_pallete()
    current_color_pallete = wrap(current_color_pallete, 5)
  end
  local lbtn=btn(⬅️)
  local rbtn=btn(➡️) 
  if(lbtn)player.steer-=0.25
  if(rbtn)player.steer+=0.25
  if(not lbtn and not rbtn)player.steer=move_to(player.steer,0,0.15)
  player.steer=clamp(player.steer,-1,1)
  player.vel.x+=0.16*player.steer*steer

  -- max speed (and don't go backwards!)
  player.vel.z=clamp(player.vel.z,0,topspd) 

  -- move player
  player.prevpos=player.pos
  player.pos+=player.vel
  if player.pos.z>=SEGMENT_LENGTH then
    player.pos.z-=SEGMENT_LENGTH
    advance_ptr(player)
  end
 
  -- clamp position
  local xlimit=cond(t.tnl,-carwid/2,carwid*3)
  local prevx=player.pos.x
  player.pos.x=clamp(player.pos.x,-SEGMENT_WIDTH-xlimit,SEGMENT_WIDTH+xlimit)
  player.vel.z-=abs(player.pos.x-prevx)*0.03
   
  if(player.stun>0)player.stun-=1   
   
  player.sp.typ=playertypes[clamp(flr(player.steer+2.5),1,3)]   
end

function update_leaderboard()
  sort_leaderboard()
end

function update_podium()
  for c in all(cars) do
    if not c.fin and c.lap>LAPS then
      c.fin=true
      add(podium,c)
    end
  end
end

function update_npcs()
  for npc in all(npcs) do 
    do_car_ai(npc)
    update_car_sprite(npc)
  end
end

function do_car_ai(car)
  local z=getz(car,car.pos.z)
 
  -- horizontal range
  -- start with full road
  local h={-SEGMENT_WIDTH-carwid,SEGMENT_WIDTH+carwid}

  -- find current car in cars array  
  local cari=indexof(cars,car)
  local i=(cari%#cars)+1        -- look at next car
  nxtz=get_relz(cars[i],cars[i].pos.z,z)

  while nxtz>=0 and nxtz<5 and i~=cari do
   if cars[i].vel.z<car.vel.z+0.05 then
    -- find car x position
    local x=cars[i].pos.x
    -- sorted insert into horizontal array
    add(h,x)
    local k=#h
    while k>1 and h[k-1]>x do
     local temp=h[k-1]
     h[k-1]=h[k]
     h[k]=temp
     k-=1
    end       
   end
   i=(i%#cars)+1
   nxtz=get_relz(cars[i],cars[i].pos.z,z)
  end

  -- if no cars to avoid, steer
  -- back towards center
  local steer=min(car.vel.z/0.075,1)
  steer*=0.16
  steer*=0.5
  if #h==2 then
    h[1]=-SEGMENT_WIDTH/2
    h[2]= SEGMENT_WIDTH/2
    steer*=0.5
  end

  -- find nearest horizontal gap
  local nx=nil
  for j=1,#h-1 do
    l=h[j]+carwid*2.75
    r=h[j+1]-carwid*2.75
    if r>l then
      local tx=clamp(car.pos.x,l,r)
      if nx==nil or abs(car.pos.x-tx)<abs(car.pos.x-nx) then
        nx=tx
      end
    end     
  end
  
  -- steer towards gap
  if nx~=nil then
    local d=nx-car.pos.x
    if abs(d)>steer then
      car.vel.x=sgn(d)*steer
    else
      car.vel.x=d
    end
  else
   car.vel.x=0
  end
 
  -- advance car
  if car.stun>0 then
    car.vel.z-=COAST
  elseif car.vel.z<car.topspd-ACCELERATION then
    car.vel.z+=ACCELERATION
  elseif car.vel.z>car.topspd+BRAKE*.3 then
    car.vel.z-=BRAKE*.3
  else
    car.vel.z=car.topspd
  end
  car.vel.z=max(car.vel.z,0)
  car.prevpos=car.pos
  car.pos+=car.vel
  if car.pos.z>SEGMENT_LENGTH then
    car.pos.z-=SEGMENT_LENGTH
    advance_ptr(car)
  end
  
  if(car.stun>0)car.stun-=1
  
  car.sp.typ=cartypes[clamp(flr((cam.pos.x-car.pos.x)*.5+2.5), 1,3)]  
end

function update_car_sprite(car)
  copy_ptr(car,car.sp)
end

function update_collisions()

 -- loop through cars in order
 for i=1,#cars do
  local car=cars[i]
  local p0=get_prev_pos(car)
  local c0=get_pos(car)
  local v0=vec3.copy(car.vel)
  
  -- search forward for nearby cars
  local j=(i%#cars)+1
  while j~=i and get_relz(cars[j],cars[j].pos.z,c0.z)<2 do
   local other=cars[j]
   local p1=get_prev_pos(other)
   local c1=get_pos(other)
   local v1=vec3.copy(other.vel)

   if boxes_intersect(c0,carbox,c1,carbox) then
    
    -- determine collision axes by 
    -- moving boxes back to previous 
    -- positions on each axis
    local isx=not boxes_intersect(
     vec3.new(p0.x,c0.y,c0.z),carbox,
     vec3.new(p1.x,c1.y,c1.z),carbox)
    local isy=not boxes_intersect(
     vec3.new(c0.x,p0.y,c0.z),carbox,
     vec3.new(c1.x,p1.y,c1.z),carbox)
    local isz=not boxes_intersect(
     vec3.new(c0.x,c0.y,p0.z),carbox,
     vec3.new(c1.x,c1.y,p1.z),carbox)

    local msg=""
    if(isx)msg=msg.."x"
    if(isy)msg=msg.."y"
    if(isz)msg=msg.."z"
     
    -- if boxes were already intersecting
    -- treat every axis as a collision
    if not(isx or isy or isz) then 
     isx=true
     isy=true
     isz=true
    end
    
    -- filter out axes along which 
    -- the cars are not moving towards
    -- each other.
    isx=isx and sgn(p1.x-p0.x)~=sgn(v1.x-v0.x)
    isy=isy and sgn(p1.y-p0.y)~=sgn(v1.y-v0.y)
    isz=isz and sgn(p1.z-p0.z)~=sgn(v1.z-v0.z)

    msg=""
    if(isx)msg=msg.."x"
    if(isy)msg=msg.."y"
    if(isz)msg=msg.."z"
    
    -- adjust velocities
    local f0=(1-CAR_ELASTIC)/2
    local f1=(1+CAR_ELASTIC)/2

    if isx then
      car.vel.x  =f0*v0.x+f1*v1.x
      other.vel.x=f0*v1.x+f1*v0.x
    end
    if isy then
      car.vel.y  =f0*v0.y+f1*v1.y
      other.vel.y=f0*v1.y+f1*v0.y
    end
    if isz then
      car.vel.z  =f0*v0.z+f1*v1.z
      other.vel.z=f0*v1.z+f1*v0.z
    end
    
    if isz and car.vel.z<other.vel.z then
      car.stun=STUN_FRAMES
    end
    if isz and other.vel.z<car.vel.z then
      car.stun=STUN_FRAMES
    end
   end

   j=(j%#cars)+1
  end   
 end
end

function sort_leaderboard()
  sort(leaderboard,compare_leaderboard_pos) 
end

function compare_leaderboard_pos(a,b) 
  local r=b.lap-a.lap
  if(r==0)r=getz(b)-getz(a)
  return r
end

function pre_race_sequence()
  hideui=true
  
  local params={}
  local ct=4
  local texty=10
  for i=1,ct do
    local p={
      done=false,
      lit=false,
      x=56+(i-(ct+1)/2)*20,
      y=23
    }
    add(params,p)
    do_draw(function()draw_stoplight(p)end)
  end
  
  local showready=true
  do_draw(function()
    while showready do
      draw_centered_text("get ready...",texty,5,6)
      yield()
    end
  end)
  
  for i=1,ct do
    wait(30)
    for j=1,ct do
      params[j].lit=j==i
    end
  end
 
  for i=1,ct do
    params[i].lit=true
  end
 
  showready=false
 
  local stayonscreen=60
 
  do_inbg(function()
    wait(stayonscreen)
    for i=1,ct do
      params[i].done=true
    end
    wait(15)
    hideui=false
  end)
 
  do_draw(function()
    for i=1,stayonscreen do
    draw_centered_text("!!! go !!!",texty,5,6)
    yield()
    end
  end)
end

function make_bg_sprite(typ,t,side,istnl)
  -- sprite offset
  local offset
  if typ.offset~=nil then
    offset=typ.offset
  else
    -- default offset based on position
    offset={x=0,y=0}
    if(side==0 and istnl)offset.y=typ.h
  end

  -- base position
  local pos=vec3.new(side*(SEGMENT_WIDTH+typ.w/2*cond(istnl,-1,1)),0,0)
  if(side==0 and istnl)pos.y-=TUNNEL_HEIGHT

  -- apply offset
  if side<0 then 
    pos.x-=offset.x
  else
    pos.x+=offset.x
  end
  pos.y+=offset.y

  add(sprites.s,{
    typ=typ,
    n=t.n,
    s=t.s,
    temp=true,
    pos=pos
  })
end

function sort_ptrs(sp)
  sort(sp,compare_ptrs) 
end

function compare_ptrs(a,b) 
  local camz=getz(cam,cam.pos.z)
  return get_relz(a,a.pos.z,camz)-get_relz(b,b.pos.z,camz)
end

function draw_game()
  framect+=1
  fillp(0)
  cls(sky_color)
  draw_scene()
  draw_effects()
  draw_ui()
end

function draw_effects()
  if stage == 3 then
    foreach(pr,show_pr)
  end
end

function show_pr(s)
  pset(s.x,s.y,6)
end

function draw_ui()
  clip(0,0,128,128)
  if player.lap<=LAPS then
    if not hideui then
      draw_laps()
      draw_leaderboard()
      draw_podium(82,1,3,false)
      if demo and flr(framect/15)%2==0 then
        draw_centered_text("demo",30,6)
        draw_centered_text("press \151 to continue",40,6)
      end
    end
    draw_speedo()   
  else
    if flr(framect/15)%2==0 then
      draw_centered_text("race complete!",8,6)
    end
    draw_centered_text("press \151 to continue",20,6)
    rectfill(10,30,56,101,0)
    draw_podium(13,32,NPC_COUNT+1,true)
  end
end

function draw_scene()
  -- reset state
  clp={
    l=0,
    r=128,
    t=0,
    b=128
  }
  sprbuf={} 
  clip(0,0,128,128)

  -- walk forward along track
  local n=cam.n
  local s=cam.s
  local tr=track[n]
  local f=cam.pos.z/SEGMENT_LENGTH
  local tu=-tr.tu*f*ANGLE_F
  local pi=(tr.sp+cam.s*tr.pd)*ANGLE_F
  local tnl=nil
   
  -- walk along sorted sprites 
  -- in parallel
  local camz=getz(cam,cam.pos.z)
  local si=1
  while si<#sprites.s and get_relz(sprites.s[si],sprites.s[si].pos.z,camz)<0 do
    si+=1
  end

  local t=get_tangent(tu,pi)
  local pos=adjust_pos(cam.pos,t)

  -- road 3d cursor
  local r0=-pos-camoffs
  local pr0=project(r0)
  for i=1,drawsegct do
    t=get_tangent(tu,pi)

    -- next road 3d position
    local r1=r0+t*SEGMENT_LENGTH
    local pr1=project(r1)

    -- add sprites
    while si<#sprites.s and sprites.s[si].n==n and sprites.s[si].s==s do
      local sp=sprites.s[si]
    
      -- calculate projected position
      local spos=r0+adjust_pos(sp.pos,t)
      spos=project(spos)

      -- add to buffer
      add(sprbuf, {
        typ=sp.typ,
        pos=spos,
        clp={
          l=clp.l,
          r=clp.r,
          t=clp.t,
          b=clp.b
        }
      })
    
      si+=1
    end   

    -- render
    local sct=tr.seg+s

    if tr.tnl then
      if tnl==false then
        draw_tunnel_face(pr0,tr.sc.tnl)
      end
      draw_tunnel_walls(pr0,pr1,tr.sc.tnl,sct)
    end

    draw_road(pr0,pr1,t,tr.sc.road,tr.tnl,sct)

    -- adjust clip region
    if tr.tnl then
      local r=get_tunnel_rect(pr1)
      adjust_clip_rect(r)
    else
      clp.b=min(clp.b,ceil(pr1.y))
    end

    -- update direction
    tu+=tr.tu*ANGLE_F
    pi+=tr.pd*ANGLE_F     
      
    -- update tunnel flag
    tnl=tr.tnl
     
    -- next segment
    r0=r1
    pr0=pr1
    s+=1
    if s>=tr.ct then
      s-=tr.ct
      n+=1
      if n>#track then
        n-=#track
      end
      tr=track[n]
      pi=tr.sp*ANGLE_F        -- redundant but for rounding errors
    end     
  end

  -- render sprite buffer in reverse
  for i=#sprbuf,1,-1 do
    draw_sprite(sprbuf[i])
  end       
end

function project(v)
  f=SCREEN_DIST/v.z
  return vec3.new(v.x*f+64,v.y*f+48,f)
end

function draw_road(p0,p1,t,su,tnl,sct)   
  local top=ceil(p1.y)
  local bot=ceil(p0.y)
  top=max(top,clp.t)
  bot=min(bot,clp.b)
  if(top>=bot)return

  set_clip_rect(clp)
   
  -- draw ground
  local gndi=flr(sct/su.gndspacing)%#su.gnd+1   
  if not tnl then
    rectfill(0,top,127,bot-1,su.gnd[gndi])
  end
   
  local h=p1.y-p0.y
  local rasteradj=top-p1.y

  -- road line
  local dr=(p1-p0)/h      -- gradient
  local r=p1+dr*rasteradj -- step to nearest raster line
  
  -- vertical texture coord
  local dv=segytiles/h                -- delta v
  local v=dv*rasteradj       -- step to nearest raster line
   
  -- step down raster lines
  while r.y<bot do
  
    -- single tile width
    local tilew=SEGMENT_WIDTH*r.z/segxtiles

    -- choose "mipmap" texture
    local ti=1
    local t=su.tex[ti]
    while ti<#su.tex and tilew>t.maxw do
      ti+=1
      t=su.tex[ti] 
    end

    -- render tiles
    local sy=flr(t.sy+(v%1)*t.h)
    for i=-segxtiles,segxtiles-1 do
      local x0=r.x+i*tilew
      local x1=x0+tilew
      sspr(t.sx,sy,t.w,1, ceil(x0),r.y,ceil(x1)-ceil(x0),1)
    end
  
    r+=dr
    v+=dv
  end
end

function adjust_pos(p,t)
  return vec3.new(p.x,p.y,0)+t*p.z
end

function draw_sprite(s)
  local t=s.typ

  set_clip_rect(s.clp)

  -- find texture for screen width
  local w=t.w*s.pos.z
  local h=t.h*s.pos.z
  local i=1
  local tex=t.tex[i]
  while i<#t.tex and tex.maxw<w do
    i+=1
    tex=t.tex[i]
  end

  -- draw sprite/map
  if tex.cw~=nil then 
    draw_smap(s.pos,w,h,tex,s.clp)
  else
    draw_sspr(s.pos,w,h,tex,t.flipx)
  end
end

function draw_speedo()
  -- speed to display
  local spdf=600
  local speed=player.vel.z*spdf
  local mspeed=topspd*spdf
 
  -- speedo position & radius
  local x=112
  local y=112
  local r=10
  
  -- text offset
  local tx=-5
  local ty=2
  
  -- needle range
  local mn=-.3
  local mx=.3
  local nr=r*.7
  
  -- markings
  local ds=20
  local dl=100
  local dr=r*.8
  
  -- gauge
  circfill(x,y,r+4,7)
  circfill(x,y,r+3,6)
  circfill(x,y,r+2,5)
  circfill(x,y,r,0)

  -- text
  local txt=""..ceil(speed)
  while #txt<3 do txt="0"..txt end
  print(txt,x+tx,y+ty,6)

  -- markings
  for i=0,mspeed,ds do
    local a=mn+(mx-mn)*(i/mspeed)
    pset(x-sin(a)*dr,y-cos(a)*dr,5)
  end
  for i=0,mspeed,dl do
    local a=mn+(mx-mn)*(i/mspeed)
    pset(x-sin(a)*dr,y-cos(a)*dr,6)
  end

  -- needle
  local n=mn+(mx-mn)*(speed/mspeed)
  line(x-1,y-1,x-1-sin(n)*nr,y-1-cos(n)*nr,7)
end

function draw_laps()
  draw_text("lap",1,8,6)
  spr(192+(player.lap-1)*2,10,0,2,2)
end

function draw_leaderboard()
  local i=indexof(leaderboard,player)
  i-=1
  i=clamp(i,1,#leaderboard-2)
  for y=0,2 do
    local sy=y*7+1
    local sx=28
    local car=leaderboard[i]
    local col=6
    if(car==player)col=5
    local place=""..i
    if(i<10)place=" "..place
    draw_text(place,sx,sy,col)
    draw_car_name(car,sx+12,sy)
    i+=1
  end 
end

function get_podium_spot(i)
  if(i<=#podiumspots)return podiumspots[i]
  return i.."th"
end

function draw_podium(sx,sy,ct,includeempty)
  for i=1,ct do
    if i<=#podium or includeempty then   
      local spot=get_podium_spot(i)
      draw_text(spot,sx,sy,6,5)
    end
    if i<=#podium then   
      draw_car_name(podium[i],sx+18,sy)
    end
    sy+=7
  end
end

function draw_car_name(car,x,y)
  local col=5
  local shadow=0
  if car~=player then
    col=6
    shadow=5
  end
  draw_text(car.name,x,y,col,shadow)
end

function draw_text(txt,x,y,col,shadow)
  if(col==nil)col=7
  if(shadow==nil)shadow=5
  if(col==shadow)shadow=0
  print(txt,x,y+1,shadow)
  print(txt,x,y,col)
end

function draw_centered_text(txt,y,col,shadow,centerx)
  if(centerx==nil)centerx=64
  local x=centerx-#txt*4/2
  draw_text(txt,x,y,col,shadow)
end

function draw_tunnel_face(p,tnl)
  local r=get_tunnel_rect(p)
  local t=r.t-.5*p.z
  set_clip_rect(clp)
  if r.l>0 then
    rectfill(
      0,  
      r.t,
      r.l-1,
      r.b-1,
      tnl.front)
  end
  if r.r<128 then
    rectfill(
      r.r,
      r.t,
      128,
      r.b-1,
      tnl.front)
  end
  rectfill(0,t,128,r.t,tnl.front)
  adjust_clip_rect(r)
end

function draw_tunnel_walls(p0,p1,tnl,seg)
  local r=get_tunnel_rect(p1)
  local coli=flr(seg/tnl.wallspacing)%#tnl.wall+1
  local col=tnl.wall[coli]
  set_clip_rect(clp)
  rectfill(0,0,128,r.t-1,col)
  rectfill(0,r.t,r.l-1,128,col)
  rectfill(r.r,r.t,128,128,col)
end

function get_tunnel_rect(p)
  return {
    l=ceil(p.x-SEGMENT_WIDTH*p.z),
    r=ceil(p.x+SEGMENT_WIDTH*p.z),
    t=ceil(p.y-TUNNEL_HEIGHT*p.z),
    b=ceil(p.y)
  }
end

function set_clip_rect(r)
  clip(r.l,r.t,r.r-r.l,r.b-r.t)
end

function adjust_clip_rect(r)
  clp.l=max(clp.l,r.l)
  clp.r=min(clp.r,r.r)
  clp.t=max(clp.t,r.t)
  clp.b=min(clp.b,r.b)
end

function get_tangent(tu,pi)
  return vec3.new(-tu*8,pi*8,1)
end

function draw_sspr(pos,sw,sh,tex,flipx)
  local x0=ceil(pos.x-sw/2)
  local x1=ceil(x0+sw)
  local y0=ceil(pos.y-sh)
  local y1=ceil(y0+sh)
  sspr(
    tex.sx,
    tex.sy,
    tex.sw,
    tex.sh,
    x0,
    y0,
    x1-x0,
    y1-y0,
    flipx==true)
end

function draw_smap(pos,sw,sh,tex,cl)
  -- find top left
  local x,y=pos.x-sw/2,pos.y-sh
 
  -- clipped rectangle
  local x1=min(ceil(x+sw),cl.r)
  local y0,y1=max(ceil(y),cl.t),min(ceil(y+sh),cl.b)
  local x0=max(ceil(x),cl.l)        -- must be set last, or becomes nil somehow!

  if(x0>=x1 or y0>=y1)return
 
  -- map coordinates and deltas
  local dx,dy=tex.cw/sw,tex.ch/sh
 
  -- map coords, adjusted for clip/sub pixel correction
  local mx,my=tex.cx+dx*(x0-x),tex.cy+dy*(y0-y)

  if y1-y0<x1-x0 then
    for y=y0,y1-1 do
      tline(x0,y,x1-1,y,mx,my,dx,0)
      my+=dy
    end
  else
    for x=x0,x1-1 do
      tline(x,y0,x,y1-1,mx,my,0,dy)
      mx+=dx
    end
 end
end

function draw_stoplight(p)
  while not p.done do
    if not p.lit then
      pal(0,6)
    end
    spr(66,p.x,p.y,2,2)
    pal()
    change_color_pallete()
    yield()
  end
end

function clamp(v,lo,hi)
  return min(max(v,lo),hi)
end

function advance_ptr(p)
  local ct=track[p.n].ct
  p.s+=1
  if p.s>=ct then
    p.s-=ct
    p.n+=1
    if p.n>#track then 
      p.n-=#track
      if(p.lap~=nil)p.lap+=1
    end
  end
end

function copy_ptr(src,dst)
  dst.n=src.n
  dst.s=src.s
  dst.pos=vec3.copy(src.pos)
end

function getseg(p)
  return track[p.n].seg+p.s
end

function getz(p,z)
  if(z==nil)z=p.pos.z
  return getseg(p)*SEGMENT_LENGTH+z
end

function get_relz(p,z,reltoz) 
  local rz=getz(p,z)-reltoz
  if abs(rz)>segct*SEGMENT_LENGTH/2 then
    rz-=sgn(rz)*segct*SEGMENT_LENGTH
  end
  return rz
end

function get_pos(p)
  return vec3.new(
    p.pos.x,
    p.pos.y,
    getz(p,p.pos.z))
end

function get_prev_pos(p)
  return vec3.new(
    p.prevpos.x,
    p.prevpos.y,
    getz(p,p.prevpos.z))
end  

function indexof(array,elem)
  for i=1,#array do
    if(array[i]==elem)return i
  end
  return 0
end

function sort(array,compare_fn)
 for i=2,#array do
    local j=i
    while j>1 and compare_fn(array[j-1],array[j])>0 do
      local temp=array[j-1]
      array[j-1]=array[j]
      array[j]=temp
      j-=1
    end
 end 
end

function boxes_intersect(pos1,box1,pos2,box2)
  local mn1=pos1+box1.mn
  local mx1=pos1+box1.mx
  local mn2=pos2+box2.mn
  local mx2=pos2+box2.mx
  if(mx1.x<mn2.x)return false
  if(mn1.x>mx2.x)return false
  if(mx1.y<mn2.y)return false
  if(mn1.y>mx2.y)return false
  if(mx1.z<mn2.z)return false
  if(mn1.z>mx2.z)return false
  return true
end

function shuffle(array)
  for i=1,#array-1 do
    local j=i+flr(rnd(#array-i+1))
    local tmp=array[i]
    array[i]=array[j]
    array[j]=tmp
  end
end

function cond(c,a,b)
  if(c)return a
  return b
end

function move_to(v,target,delta)
  if(abs(target-v)<delta)return target
  return v+sgn(target-v)*delta
end

function run_fg()
  run_co(fg_co)
  return #fg_co~=0
end

function run_co(co)
  for c in all(co) do
    if costatus(c)=="dead" then
      del(co,c)
    else
      assert(coresume(c))
    end
  end
end

function do_inbg(fn)
  add(bg_co,cocreate(fn))
end

function do_draw(fn)
  add(draw_co,cocreate(fn))
end

function wait(framect)
  for i=1,framect do
    yield()
  end
end

-- POST RACE

function init_post_race()
 do_inbg(function() wait(100) end)
end

function update_post_race()
  if(btnp(key.a))set_state(STATE_MENU)
  if btnp(key.b) then
    change_color_pallete()
    current_color_pallete = wrap(current_color_pallete, 5)
  end
end

function draw_post_race() 
  cls()
  draw_text("race results",4,10,5,6)
  local t=menu_tracks[stage]
  draw_centered_text(t.name,10,5,6,96)
  sspr((t.sp%16)*8, flr(t.sp/16)*8, 16, 16, 80, 21, 32, 32)
  rect(79,20,112,53,5)
  rectfill(4,20,50,91,0)
  draw_podium(7,22,NPC_COUNT+1,true)
  local place=indexof(podium,player)
  local spot=get_podium_spot(place)
  draw_centered_text("you placed "..spot,70,5,6,96) 
     
  if place <= 1 then
    spr(232,88,80,2,2)
  end

  draw_centered_text("press \151 to continue",115,5,6)
end

-- UTILS

function wrap(current, max)
  if current + 1 > max then
    return 0
  end
  return current + 1
end

function duplicate(o)
  local r={}
  for k,v in pairs(o) do
    r[k]=v
  end
  return r
end

function add_pr()
  local s={}
  s.x=flr(rnd(128))
  s.y=-1
  add(pr,s)
end

function upd_pr(s)
  s.y+=0.5+flr(rnd(10))/10
  s.x+=(rnd(20)-10)/10
  if(s.y>128 or s.x<0 or s.x>128) then
    del(pr,s)
  end
end


__gfx__
0000000077777777777777776666676777777766eeeeeeeeeeeeeeee77676766eeeeeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000077777777777777770666676777777760eeeeeeeeeeeeeeee7676766eeeeeeeeeeeeeee7007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
007007007777777777777777eee0000ee0000eeeeeeeeeeeeeeeeeee776766eeeeeeeeeeeeeeee7557eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000770007777777777777777ee555555555555eeeeeeeeeeeeeeeeee767676eeeeeeeeeeeeeee700007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000770007777777777777777e77777777777777eeeeeeeeeeeeeeeee776766eee777eeeeeeee70600607eeeeeeee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
007007007777777777777777e67777777777776eeeeeee6ee6ee6eee76766eee7eee7eeeeee7060660607eeeeee7eee7eeeeeeeeee7777eeee7777eeeeeeeeee
000000007777777777777777e77777777777777eeeeee6e05550e6ee77676eee7eee7eeeeee706e66e607eeeeee7eee7eeeeeeeee766667ee766667eeeeeeeee
000000007777777777777777eeeeeeeeeeeeeeeeeeee6e0555550e6e7676eeee7e0e7eee7ee7060660607ee7eee7eee7eeeeeeee7666667ee7666667eeeeeeee
777777777777777777777777eeeeeeeeeeeeeeeeeeeee055565550ee7766eeeeee7eeee7e7e706e66e607e7e7eeee0eeeeeeeeee7666657ee7566667eeeeeeee
777777777777777777777777eeeeeeeeeeeeeeeeeeeee555555555ee7766eeeee666eeee0ee7060660607ee0eeee666eeeeeeeee7765567ee765567eeeeeeeee
777777777777777777777777e757757eeeeeeeeeeeee65555555556e7676eeee066607ee66ee70000007ee66ee706660eeeeeeeeee76667ee76667eeeeeeeeee
777777777777777777777777e755557eeeeeeeeeeeeee055565550ee7766eeee60007e706607e775577e706607e70006eeeeeeeeee766667766667eeeeeeeeee
777777777777777777777777e666666eeeeeeeeee6e6e555555555ee7766eeeee607eee7007eee7007eee7007eee706eeeeeeeeee76666666666667eeeeeeeee
77777777777777777777777777666677eeeeeeeeee0ee5555555556e7766eeeeee607eee707e77000077e707eee706eeeeeeeeeee75555500555557eeeeeeeee
77777777777777777777777755777755eeeeeeee6055e055565550ee7776eeeeeee607777707006ee600707777706eeeeeeeeeee7655555005555567eeeeeeee
777777777777777777777777006ee600eeeeeeeee565e555555555ee776eeeeeeeee600000006eeeeee600000006eeeeeeee7e7ee76666666666667ee7e7eeee
777777776666666666666666eeeeeeeeeeeeeeeee555e0555555506e776eeeeeeeeee000000000eeeeeeeeeeeeeeeeeeeee70707766666666666666770707eee
777777776666666666666666eeeeeeeeeeeeeeee65560555565555ee7776eeeeeeeee000eeee000eeeeeeeeeeeeeeeeeeeee70075576666666666e557007eeee
777777776666666666666666eeeeeeeeeeeeeeeee0556555555550ee7766eeeeeee0066600eee000eeeee77777eeeeeeeee70775555777666677755557707eee
777777776666556666666666eeeeeeeeeeeeeeeeee0555555555556e7766eeeee00000000000ee00eee77777777eeeeeeeee7755555ee777777ee5555577eeee
777777776665500666666666eeeeee7ee7eeeeeeeee05555565550ee7766eeee0000000000000e00ee7777777777eeeeeeeee7555555766666675555557eeeee
777777776666556666666666eeeee757757eeeeeee6e0555555555ee7676eeeeeee6666666eeee00ee7766776677eeeeee7777755505666666665055577777ee
777777776666666666666666eeee75577557eeeeeee6e0555555506e7766eeeeeee6776776eeee00ee7766776677eeeee700700750555666666555057007007e
777777776666666666666556eeee75555557eeeeeeeee555565555ee7766eeeeeee6777776eeee00ee7766776677eeeee5007000755500666600555700070007
775577556666666666665056eee7755555577eeeeeeee555555555ee7676eeeeeee6777776eeee00ee77777777777eee70007000e65000666600056e00070007
775577556666666666660566ee756666666657eeeeee60555555506e77676eeeeee6777776eeee00ee77777777777eee70000005755555555555555750000007
5577557766666666666066667755500000055577eeeee555565555ee76766eeeeee6777776eeee00ee77777777777eee70070005777777777777777750007007
5577557766556666666666667666666666666667eeeee555555555ee776766eeeee6777776eeee00eee77777777777ee70070005777775755757777750007007
7755775566505666666666667666656666566667eeee60555555506e767676eeeee6666666eeee00eeee7777777eeeee70070005777757577575777750007007
7755775566650666666666667555777777775557eeeee055565550ee776766eeeeee76667eee6666eeeeeeeeeeeeee7e70000005776757577575767750000007
5577557766666666666666667555767777675557eeeee055555550ee7676766eeeeeeeeeeeee0000eeeeeeeeeeeeeeee75007000e66757577575766e00070057
55775577666666666666666670007eeeeee70007eeeee055555550ee77676766eeeeeeeeeee00000eeeeeeeeeeeeeeeee7557507eeeeeeeeeeeeeeee7057557e
0555555555555550eeeeeeeee5555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666666eeeeeeee66767677eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5555555555555555eeeeeeeee56555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666606666666eeeeeeeee6676767eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5775557755577555eeeeeeeeee55555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666666eeeeeeeeee667677eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5577555775557755eeeeee555e555555eeeeeeeeeeeeeeeeeeeee000000eeeee6666666666666666eeeeeeeeee676767eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5577755777557775eeeee56665655655eeeeeeeee000eeeeeeee00000000eeee5555555555555555eeeeeeeeee667677eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5577755777557775eeee56000656e565eeeee00e05000eeeeee0077777700eee6666566666666666eeeeeeeeeee66767eeeeeeeeeeeeee777eeeee777eeeeeee
5577555775557755eee560000065ee5eeeee000000500eeeee007700007700ee6665056666666666eeeeeeeeeee67677eeeeeeeeeeeee76667eee76667eeeeee
5775557755577555ee56007000065eeeeeee00500000eeeeee077000000770ee6666566666666666eeeeeeeeeeee6767eeeeeeeeeeee766666e77666667eeeee
5555555555555555e560077700065eeeeeeee000500eeeeeee070007700070ee6666666666656666eeeeeeeeeeee6677eeeeeeeeeeee765666e76666667eeeee
0555555555555550e56000700065eeeeeeeeeee555eeeeeeee070077770070ee6666666666666666eeeeeeeeeeee6677eeeeeeeeeeee766557e7665667eeeeee
e00000000000000e560000000065eeeeeeeeee77777eeeeeee070077770070ee5555555566666666eeeeeeeeeeee6767eeeeeeeeeeee76667ee76667eeeeeeee
ee606eeeeee606ee56000000065eeeeeeeeee7777777eeeeee070007700070ee6666666655555555eeeeeeeeeeee6677eeeeeeeeeeee766667766667eeeeeeee
ee666eeeeee666ee5600000065eeeeeeeeeee6777777eeeeee070007700070ee6666666666666666eeeeeeeeeeee6677eeeeeeeeeee76666666666667eeeeeee
ee666eeeeee666eee56000665eeeeeeeeee5576677555eeeee070000000070ee6666666666666666eeeeeeeeeeee6677eeeeeeeeeee75555500555557eeeeeee
ee666eeeeee666eeee566655eeeeeeeeee555557555555eeee070000000070ee6666666000056666eeeeeeeeeeee6777eeeeeeeeee7655555005555567eeeeee
ee000eeeeee000eeeee555eeeeeeeeeeee555555555555eeee070000000070ee5555555555555555eeeeeeeeeeeee677eeeeeeeeeee76666666666667eee777e
55555555555555556677776666666666777777777777777777777777777777770000000000000000eeeeeeeeeeeee677eeeeeeeeee7000006666666667e70007
55555555555555556777777666666666767676767767777777777677676767670000000000000000eeeeeeeeeeee6777eeeeeeeee7077666666666675570777e
55556555565555556777777767777676676767676676667667666766767676760000000000000000eeeeeeeeeeee6677eeeeeeee75055700066677755557007e
55565555555555556677777677777766767676766666666ee6666666676767670000000000000000eeeeeeeeeeee6677eeeeeee7505557e777777e75555577ee
555555555555555566666666777777666767666eeeeeeeeeeeeeeeee666676760000000000000000eeeeeeeeeeee6677eeeee777555555766666675555557eee
5555555555555555676777776777766676666eeeeeeeeeeeeeeeeeeeeee666670000000000000000eeeeeeeeeeee6767eee776666555056666666650555777ee
5555555655556655666777777677666666eeeeeeeeeeeeeeeeeeeeeeeeeeee660000000000000000eeeeeeeeeeee6677ee70007006505555666665550500707e
555566655556555566776777776666766eeeeeeeeeeeeeeeeeeeeeeeeeeeeee60000000000000000eeeeeeeeeeee6677e7550070006555000666005550007007
55566555556555556776777777667666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeee676775005070006650000666000560007007
55665555556555556767677777677766eeeeeeeeeeee55555555eeeeeeeeeeee0000000000000000eeeeeeeeeee6767775005000056555555555555557000007
55655555555555556776777776677776eeeeeeeeee557777777755eeeeeeeeee0000000000000000eeeeeeeeeee6676775005007056777777777777777000707
55655555555555556777777766777777eeeeeeee5577777777777755eeeeeeee0000000000000000eeeeeeeeee66767775005007056777757557577777000707
56555555555555556677777667767777eeeeeee577666666666666775eeeeeee0000000000000000eeeeeeeeee67676775005007056777575775757777000707
55555555655555556677776677677777eeeeee57777677777777677775eeeeee0000000000000000eeeeeeeeee66767775005000057767575775757677000007
55555556555555556667766677777777eeeee5777767777777777677775eeeee0000000000000000eeeeeeeee6676767e755007000e667575775757660007057
55555555555555556666666667777776eeee576777677777777776777675eeee0000000000000000eeeeeeee66767677ee7555750eeeeeeeeeeeeeeee755757e
eeeee5555555555550eeeee0555eeeeeeee57776666676766767666667775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0555555555555555555555550eeeeee57767777777777777777776775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e05555555555555555555555555550eeee5777677777767777677777767775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0555555555555555555555555555550eee5777677777767777677777767775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5555655555565555655555555555555ee566776777777677775777777677655eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5556555555556666555555555665555ee567766676766655555557776667765eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
55565555555555555555555555565555e577777777777577666665777777775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e5555555555555555555555555555555e576777776775776555556577777675eeeeeeeeeeeeeee77eeeee77eeeeeeeeeeeeeeeeeeeee77eeeee77eeeeeeeeeee
e5555555555555555555655555555555e576777776775765555555657777675eeeeeeeeeeeeee7557eee7557eeeeeeeeeeeeeeeeeee7557eee7557eeeeeeeeee
e5555555555555555555555555555555e576777776757765555555657777675eeeeeeeeeeeee75657eee75657eeeeeeeeeeeeeeeee75657eee75657eeeeeeeee
5655566555556555555555555555555556667676766577655555556567676675eeeeeeeeeee756555777555657eeeeeeeeeeeeeee756555777555657eeeeeeee
5566556555556655555556555566555e57777767777577655555556576777775eeeeeeeeeee755555555555557eeeeeeeeeeeeeee755555555555557eeeeeeee
5655665666555666555565556655560e57777777777577655555556577777775eeeeeeeeeee755555555555557eeeeeeeeeeeeeee755555555555557eeeeeeee
056665555666666666665566555660ee56777767777577655555556576777765eeeeeeeeeee755555555555557eeeeeeeeeeeeeee755555555555557eeeeeeee
e0550055500555666665500055500eee57677767777577655555556576777675eeeeeeeeeee755555555555557eeeeeeeeeeeeeee755555555555557eeeeeeee
ee00e000057555555000070000055eeee555555555555555555555555555555eeeeeeeeeeee755555555555557eeeeeeeeeeeeeee755555555555557eeeeeeee
eee5ee77757055077775570eeeee5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7e7555555555557eeeeeeeeeeeee777e7555555555557e77eeeeee
eee5ee5775770077777557eeeeee5eeeeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeeeee7566666666666666667eeeeeeeee7555666666666666665557eeeee
eee5ee5ee577777777775eeeeeee5eeeeeeeeeee0e0770eeeee666eeeeeeeeeeeeeeeeee755666666666666666657eeeeeeee5557770000000000777555eeeee
eeee5e5ee577777677705eeeeeee5eeeeeeeee00eee0770eee67776ee66eeeeeee777ee75557700000000007775557eeee7775557500000000000057555777ee
eeee5e5ee5e5777777775eeeee5e5eeeeeeee060e0e0670eee67776e6776eeeee76667775566500000000005665557eee766655666666666666666666556677e
eeeee55e5eee777777705eeee5e5eeeee0ee060e070e070eee67776e6776eeeee755557656666666666666666665567e76666666666666666666666666666677
eeeeeee5eeee77776770e55e5e55eeee050e060050600670ee67776e6776eeee7076666666666666666666666666666776666666666666666666666666666667
eeeeeeeeeeee57776770ee55e55eeeee0550000550670670ee6777666676eeee7076666666666666666666666666666776665666566566666666566566656667
eeeeeeee5ee5e7776770eee555eeeeee0557775550670670ee6766777766eeee7076666566656666666666666565656776666666666666666666666666666667
eeeeeeeee55ee7776770eeeeeeeeeeee057777555677000eee6777777776eeee7075555666666666666666666666666775555566555555555555555566555557
eeeeeeeeeeee77777777eeeeeeeeeeee07770075067700eee677777777776eeee7705555556655555555555555666667e755555577777777777777775555557e
eeeeeeeeeeee77777770eeeeeeeeeeee0776007706770eeee677775777576eeeee705555557777777777777777555557e755555577777777777777775555557e
eeeeeeeeeee777777770eeeeeeeeeeee077777770670eeeee677777777776eeeee705555557755577777775557555557e755555575557777777755575555557e
eeeeeeeeee77777767770eeeeeeeeeeee6777770e00eeeeee667777755556eeeee706666660050500000005056666667e766666665050000000050566666667e
eeeeeeee07777777767770eeeeeeeeeeee00000eeeeeeeeee676777755576e5eee700000077755577777775550000007e700000075557777777755570000007e
eeeeeee0777700077777770eeeeeeeeeeeeeeeeeeeeeeeeeee67677777766e55eee605057eee777eeeeeeee775050507e75050507777eeeeeeee77770505057e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee56666677665ee55eee0e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee56555566555ee5eeeee0eeeeeeeeeeee0000000eee00eeee00e00ee0000ee00ee0000ee00eeeee0
eeeeeee666eeeeeeeeeeee6666eeeeeeeeee666666eeeeeee56555566555ee5eeee555ee667eee66000000000e000eeee00e00e000000e00e000000e00eeeee0
eeeeee66666eeeeeeeeee666666eeeeeeeee6666666eeeeee6775556657775eeeee555ee66776666000eee500e000eeee00e000000000e000000000e000eee00
eeeee666666eeeeeeeee66666656eeeeeeee66666566eeeee77777777777776eeee555ee66776666000eeee00e000eeee00e00005ee00e00005ee00e000eee00
eeee6666666eeeeeeeee66666666eeeeeeeeeeee6656eeee677777775577776eeeee5eee66676666000eeee00e000eeee00e0005eee00e0005eee00e0000e000
eeee5566656eeeeeeeee555e6666eeeeeeeeeeeee666eeee675777775577776eeee000ee66666666000eee500e000eeee00e000eeee00e000eeee00ee0000005
eeeeee66666eeeeeeeeeeeee6656eeeeeeeee6666666eeee656777775777776eee66666e66666666000e0000ee000eeee00e000eeee00e000eeee00eee00000e
eeeeee66666eeeeeeeeeeeee6656eeeeeeeee666666eeeee657777777777776eeeeeeeeee566665e060eeee00e000eeee00e000eeee00e000eeee00eee00005e
eeeeee66656eeeeeeeeeeee66666eeeeeeeee5555666eeee567777777777776eeeeeeeeeee5555ee000eeee00e000eeee00e000eeee00e000eeee00eeee000ee
eeeeee66656eeeeeeeeeee66666eeeeeeeeeeeee6666eeee676777775577776eeeeeeeeeeee66eee000eeee00e000eeee00e000eeee00e000eeee00eeee000ee
eeeeee66656eeeeeeeeee66666eeeeeeeeee66666666eeee667677775577776eeeeeeeeeeee55eee000eeee00e0000eee00e000eeee00e000eeee00eeee000ee
eeee666666666eeeeeee66666666eeeeeeee66666656eeee67676777577776eeeeeeeeeeeee55eee000000000e000000000e000eeee00e000eeee00eeee000ee
eeee666666666eeeeeee66666666eeeeeeee6666666eeeeee6767677777776eeeeeeeeeeee0000ee000000000e00000000ee000eeee00e000eeee00eeee000ee
eeee555555555eeeeeee55555555eeeeeeee555555eeeeeeee67676777776eeeeeeeeeeeee6666ee00000005eee000005eee005eeee05e005eeee05eeee005ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee666666666eeeeeeeeeeeee666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666666600000000000000005555555555555555777777777777777766eeeeeeeeeeee66eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee555eeeee
6666666666666666000000000000000055555557555575557777766666677777666ee66ee66ee666e00eeee00eee0000000eee0000000eeeeeeeeee55e5eeeee
66600666666666660000000000000000555555756766575577776777777767775665667777665665000eeee000e0000ee000e000000000eeeeeeeee555e55eee
66600066666666660000077777000000555557566666655577767777777776776665667777665666000eeee000e0005eee00e0005eee00eeeeeeeeee5555e5ee
66660055556666660007777777700000555555666666655577667777777777775565667777665655000eeee000e000eeee00e000eeeee0eeeeee6665555e55ee
6666605555566666007777777777000055555566676667557766777577775767e66567777776566e000eeee000e000eeee00e000eeeee0eeeee666665e5555ee
6666550555556666007766776677000055555566666665557766777777777767e56567777776565e0000eee000e000eeee00e000eeee00eeee6566666ee55eee
6665555055556666007766776677000055755766666665557766777777555567eee5677777765eee0000000000e000eeee00e000000000eeee6666666eeeeeee
6665555055555666007766776677000057565566676667557766677777555777eee5567777655eee0600000000e000eeee00e000000000eee6666666eeeeeeee
6665555505555666007777777777700055666566666665557776667777777667eeee56777765eeee0000000000e000eeee00e00000000eee6666666eeeeeeeee
6665555550555666007777777777700057667666666665557756666677766567eeeeee6776eee0e0000eeee000e000eeee00e000eeeeeeee66666eeeeeeeeeee
6660555555555566007777777777700055666766676667557756555566655567eeeeee6556eee00e000eeee000e000eeee00e000eeeeeeeee66eeeeeeeeeeeee
6666055655555566000777777777770055566666666665557756555566655567e0e0eee55ee55000000eeee000e0005ee000e000eeeeeeeeeeeeeeeeeeeeeeee
6666666555556666000077777770000055756666666665557776555566655577ee055666665555ee000eeee000e000000000e000eeeeeeeeeeeeeeeeeeeeeeee
6666666666666666000000000000007055575566676667557777755566657777e0555556655555ee005eeee05eee0000005ee005eeeeeeeeeeeeeeeeeeeeeeee
6666666666666666000000000000000055555566666665557777777777777777eee5555565555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
