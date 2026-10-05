-- mame_fbird.lua -- MAME "sprinter" autotest driver for the AUTOTEST build of FBIRD.EXE.
--
-- Started by tools/run_mame.sh with -autoboot_script. Types B:\FBIRD\FBIRD.EXE in the DSS File
-- Manager, starts the game and plays it with an autopilot (the AUTOTEST build has an immortal bird).
-- Every displayed frame is checked against a reference picture rendered here from the game state:
-- the AUTOTEST build stores, per video page, the state the page was drawn with (DbgPage0/DbgPage1
-- in the SRAM cache, layout DBG_* in src/cache_render.asm). Also checked: tube geometry and motion,
-- scoring, bird physics, the day/night theme against the score and the palette fade of the switch,
-- and before that the boot: the Sprinter logo fading in and out, then the title.
--
-- Environment: FB_SYM (symbols of the AUTOTEST build), FB_OUT (report, dumps, screenshots),
--              FB_ASSETS (src/assets), FB_PALETTE (src/res_pal.asm; logo_pal.asm and title_pal.asm
--              are taken from the same directory), FB_SCORE (score to play to),
--              FB_MAX_DUMPS (mismatching frames dumped as .act/.exp, default 12)
-- Result: FB_OUT/report.txt ending with "RESULT: PASS|FAIL"; MAME exits.

if _G.__fbird_loaded then return end   -- MAME executes -autoboot_script twice
_G.__fbird_loaded = true

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local screen = machine.screens[":screen"]
local vram = machine.memory.shares[":vram"]
local fast = machine.memory.shares[":fastram"]

local SYM = os.getenv("FB_SYM") or "build/autotest/fbird.sym"
local OUT = os.getenv("FB_OUT") or "build/autotest"
local ASSETS = os.getenv("FB_ASSETS") or "src/assets"
local PALETTE = os.getenv("FB_PALETTE") or "src/res_pal.asm"
local TARGET_SCORE = tonumber(os.getenv("FB_SCORE") or "110")
local MAX_DUMPS = tonumber(os.getenv("FB_MAX_DUMPS") or "12")
local EXE_CMD = "b:\\fbird\\fbird.exe"

-- ---------------------------------------------------------------- report
local out = assert(io.open(OUT .. "/report.txt", "w"))
local failures = 0
local function log(fmt, ...)
  local s = string.format(fmt, ...)
  print(s)
  out:write(s, "\n")
  out:flush()
end
local fail_counts = {}
local function fail(kind, fmt, ...)      -- at most 5 lines per kind of failure, all of them counted
  failures = failures + 1
  fail_counts[kind] = (fail_counts[kind] or 0) + 1
  if fail_counts[kind] <= 5 then log("FAIL [%s] " .. fmt, kind, ...) end
end
local function now() return machine.time:as_double() end
local function frames(n) for _ = 1, n do coroutine.yield() end end
local function shot(name) screen:snapshot(name .. ".png") end

-- ---------------------------------------------------------------- symbols, assets, palette
local sym = {}
for line in io.lines(SYM) do
  local name, hex = line:match("^([%w_%.]+):%s*EQU%s+0x(%x+)")
  if name then sym[name] = tonumber(hex, 16) end
end
local function S(name) return assert(sym[name], "symbol " .. name .. " missing in " .. SYM .. " (AUTOTEST build required)") end

local function load_bin(name)
  local f = assert(io.open(ASSETS .. "/" .. name, "rb"))
  local s = f:read("a")
  f:close()
  local t = {}
  for i = 1, #s do t[i] = s:byte(i) end
  return t
end
local city = { [0] = load_bin("city.bin"), [1] = load_bin("cityn.bin") }
local way = load_bin("way.bin")
local birds = load_bin("birds.bin")
local tubes_bin = load_bin("tubes.bin")
local ui = load_bin("ui.bin")

local function load_palette(path)        -- p[i] = {r, g, b}, i from 1, from a *_pal.asm
  local p = {}
  for line in io.lines(path) do
    local b, g, r = line:match("db%s+0x(%x%x),%s*0x(%x%x),%s*0x(%x%x),%s*0x%x%x")
    if b then p[#p + 1] = { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) } end
  end
  return p
end
local nominal = load_palette(PALETTE)    -- game palette
local SRC_DIR = PALETTE:match("^(.*)/[^/]*$") or "."
local logo_pal, title_pal = load_palette(SRC_DIR .. "/logo_pal.asm"), load_palette(SRC_DIR .. "/title_pal.asm")

-- geometry of the frame (src/fbird.asm, src/cache_render.asm)
local W, ROWS = 320, 231                 -- compared area: playfield and the road; the HUD rows are not modelled
local CITY_Y, CITY_H, CITY_W, CITY_PERIOD = 150, 39, 276, 138
local WAY_Y, WAY_H, WAY_W, WAY_CHUNK = 220, 11, 140, 120
local FIELD_H = 220                      -- tubes live in rows 0..219
local TUBE_W, HEAD_H = S("TubeWidth"), S("TubeHeadHeight")
local TUBE_MIN_Y = S("TubeMinY")
local BIRD_X, BIRD_W, BIRD_H = 16, 17, 12
local MEDAL_X, MEDAL_SIZE = S("FIELD_MEDAL_X"), 24
local COINS = S("UiCoins") - 0xC000
local SPR = {                            -- offsets in tubes.bin
  [false] = { dn = S("RedTubeDn") - 0xC000, up = S("RedTubeUp") - 0xC000, mid = S("RedTubeMiddle") - 0xC000 },
  [true] = { dn = S("GreenTubeDn") - 0xC000, up = S("GreenTubeUp") - 0xC000, mid = S("GreenTubeMiddle") - 0xC000 },
}
local SKY = { [0] = S("DAY_SKY_COLOR"), [1] = S("NIGHT_SKY_COLOR") }
local GRASS = { [0] = S("DAY_GRASS_COLOR"), [1] = S("NIGHT_GRASS_COLOR") }
local MODE = { PLAY = S("DBG_MODE_PLAY"), READY = S("DBG_MODE_READY"), GAMEOVER = S("DBG_MODE_GAMEOVER"), REDRAW = S("DBG_MODE_REDRAW") }
local TUBES, TUBE_SIZE = S("TUBES_COUNT"), S("TUBE_ENTRY_SIZE")

-- requirements checked (specs.md 7, 8): the visual theme and the tube parameters by score.
-- Theme cycles day/night every 50 points forever; difficulty has 10 levels, one per 25 points,
-- capped at level 9 (score >= 200).
local function expected_theme(score) return (score // 50) % 2 end
local LEVEL_SCORES = { 10, 25, 50, 75, 100, 125, 150, 175, 200 }
local function expected_level(score)
  local level = 0
  for _, s in ipairs(LEVEL_SCORES) do if score >= s then level = level + 1 end end
  return level
end
local LEVEL_GAP = { [0] = 80, 80, 78, 76, 74, 72, 70, 68, 66, 64 }
local LEVEL_INTERVALS = { [0] = { 164, 156, 152, 148 }, { 156, 148, 144, 140 }, { 148, 140, 136, 132 },
  { 140, 132, 128, 124 }, { 132, 124, 120, 116 }, { 124, 116, 112, 108 }, { 120, 112, 108, 104 },
  { 116, 108, 104, 100 }, { 108, 100, 96, 92 }, { 104, 96, 92, 88 } }
local TUBE_Y_SETS = { [0] = { 50, 80, 56, 74, 46, 86, 60, 78 }, { 44, 86, 50, 80, 40, 92, 56, 74 },
  { 36, 96, 44, 88, 30, 102, 50, 82 }, { 28, 104, 36, 96, 22, 112, 44, 88 }, { 20, 112, 30, 104, 14, 120, 38, 96 } }
local MEDAL_SCORE = { [0] = 25, 50, 100, 200 }   -- bronze, silver, gold, platinum

-- CacheGetSpawnDistance: one of the level's intervals plus 0/8/16/24 for a height change, at most 176
local function spawn_distance_ok(level, d)
  for _, b in ipairs(LEVEL_INTERVALS[level]) do
    for e = 0, 24, 8 do if math.min(b + e, 176) == d then return true end end
  end
  return false
end
-- CacheSelectTubeY + CacheClampTubeYToCurrentGap: a static tube's y is a table value, clamped
local function static_y_ok(level, gap, y)
  for _, v in ipairs(TUBE_Y_SETS[level // 2]) do
    if math.max(math.min(v, FIELD_H - HEAD_H - 1 - gap), TUBE_MIN_Y) == y then return true end
  end
  return false
end

-- ---------------------------------------------------------------- game state
local fast_off = 0                       -- cache address -> offset in the :fastram share
local function fu8(a) return fast:read_u8(a + fast_off) end
local function fu16(a) return fu8(a) + 256 * fu8(a + 1) end
local function magic_at(off)
  local m = "FBAT"
  for i = 1, #m do if fast:read_u8(S("DbgMagic") + off + i - 1) ~= m:byte(i) then return false end end
  return true
end

local function read_rec(page)
  local b = page == 0 and S("DbgPage0") or S("DbgPage1")
  local r = {
    page = page, seq = fu16(b + S("DBG_SEQ")), mode = fu8(b + S("DBG_MODE")), theme = fu8(b + S("DBG_THEME")),
    city = fu8(b + S("DBG_CITY_POS")), way = fu8(b + S("DBG_WAY_POS")), bird_frame = fu8(b + S("DBG_BIRD_FRAME")),
    bird_y = fu8(b + S("DBG_BIRD_Y")), score = fu16(b + S("DBG_SCORE")), high = fu16(b + S("DBG_HIGH_SCORE")),
    medal_id = fu8(b + S("DBG_MEDAL_ID")), medal_y = fu8(b + S("DBG_MEDAL_Y")), level = fu8(b + S("DBG_LEVEL")),
    gap = fu8(b + S("DBG_GAP")), hits = fu16(b + S("DBG_HITS")), ready = fu8(b + S("DBG_READY")), tubes = {},
  }
  for i = 0, TUBES - 1 do
    local t = b + S("DBG_TUBES") + i * TUBE_SIZE
    local x = fu16(t)
    if x >= 32768 then x = x - 65536 end
    r.tubes[i + 1] = { x = x, y = fu8(t + 2), gap = fu8(t + 3), phase = fu8(t + 4), base = fu8(t + 5) }
  end
  return r
end

local function tube_str(r)
  local t = {}
  for i, tb in ipairs(r.tubes) do
    t[i] = tb.y == 0 and string.format("(x=%d -)", tb.x) or
        string.format("(x=%d y=%d gap=%d %s)", tb.x, tb.y, tb.gap, tb.phase ~= 0 and "moving base=" .. tb.base or "static")
  end
  return table.concat(t, " ")
end

-- Palette as the game left it in VRAM (SetPaletteBoth: colour i is row i, R G B at X #3E0..#3E2).
-- Returns how much darker than the game palette it is: 0 (the game palette) .. 255 (black), every
-- component being max(nominal - d, 0) as SetPaletteDarkened makes it, or "?" for anything else.
local function palette_dark()
  local n = #nominal
  local d, black = nil, true
  for i = 0, n - 1 do
    local a = i * 1024 + 0x3E0
    local m = nominal[i + 1]
    for k = 1, 3 do
      local c = vram:read_u8(a + k - 1)
      if c ~= 0 then
        black = false
        if d == nil then d = m[k] - c elseif d ~= m[k] - c then return "?" end
      end
    end
  end
  if black then return 255 end
  for i = 0, n - 1 do                    -- the components that are 0 must be the dark ones
    local a = i * 1024 + 0x3E0
    for k = 1, 3 do
      if vram:read_u8(a + k - 1) == 0 and nominal[i + 1][k] > d then return "?" end
    end
  end
  return d
end

-- The first n colours in VRAM are exactly pal (n = #pal), or all black when pal is nil.
local function palette_is(pal, n)
  for i = 0, (n or #pal) - 1 do
    local a, m = i * 1024 + 0x3E0, pal and pal[i + 1]
    for k = 1, 3 do
      if vram:read_u8(a + k - 1) ~= (m and m[k] or 0) then return false end
    end
  end
  return true
end

-- ---------------------------------------------------------------- reference picture
local E = {}                             -- expected colour indexes, E[y * W + x + 1]

local function blit(src, off, sw, sh, x0, y0, ymax)   -- transparent (255) sprite, clipped to the compared area
  for r = 0, sh - 1 do
    local y = y0 + r
    if y >= 0 and y <= ymax then
      local so, eo = off + r * sw, y * W
      for c = 0, sw - 1 do
        local x = x0 + c
        if x >= 0 and x < W then
          local v = src[so + c + 1]
          if v ~= 255 then E[eo + x + 1] = v end
        end
      end
    end
  end
end

local function tube_rows(spr_off, x0, y0, n)   -- n rows of the one-row tube body
  for r = 0, n - 1 do blit(tubes_bin, spr_off, TUBE_W, 1, x0, y0 + r, FIELD_H - 1) end
end

local function clamp_tube_y(tb)          -- CacheClampTubeYWithGap
  local y = math.min(tb.y, FIELD_H - HEAD_H - 1 - tb.gap)
  return math.max(y, TUBE_MIN_Y)
end

local function build_expected(rec)
  local sky, grass = SKY[rec.theme], GRASS[rec.theme]
  for i = 1, CITY_Y * W do E[i] = sky end
  local tile = city[rec.theme]
  for r = 0, CITY_H - 1 do
    local so, eo = r * CITY_W + rec.city, (CITY_Y + r) * W
    for x = 0, CITY_PERIOD * 2 - 1 do E[eo + x + 1] = tile[so + x % CITY_PERIOD + 1] end
    for x = CITY_PERIOD * 2, W - 1 do E[eo + x + 1] = tile[so + x - CITY_PERIOD * 2 + 1] end
  end
  for i = (CITY_Y + CITY_H) * W + 1, WAY_Y * W do E[i] = grass end
  for r = 0, WAY_H - 1 do
    local so, eo = r * WAY_W + rec.way, (WAY_Y + r) * W
    for x = 0, WAY_CHUNK * 2 - 1 do E[eo + x + 1] = way[so + x % WAY_CHUNK + 1] end
    for x = WAY_CHUNK * 2, W - 1 do E[eo + x + 1] = way[so + x - WAY_CHUNK * 2 + 1] end
  end
  for _, tb in ipairs(rec.tubes) do
    if tb.y ~= 0 then
      local moving = tb.phase ~= 0
      local spr = SPR[moving]
      local y = clamp_tube_y(tb)
      tube_rows(spr.mid, tb.x, 0, y)                                    -- upper tube: body, then the head
      blit(tubes_bin, spr.dn, TUBE_W, HEAD_H, tb.x, y, FIELD_H - 1)
      blit(tubes_bin, spr.up, TUBE_W, HEAD_H, tb.x, y + tb.gap, FIELD_H - 1)   -- lower tube: head, then the body
      tube_rows(spr.mid, tb.x, y + tb.gap + HEAD_H, FIELD_H - (y + tb.gap + HEAD_H))
    end
  end
  blit(birds, rec.bird_frame * BIRD_W * BIRD_H, BIRD_W, BIRD_H, BIRD_X, rec.bird_y, ROWS - 1)
  if rec.medal_id ~= 255 and rec.medal_y ~= 255 then                    -- the medal flies in over the field
    blit(ui, COINS + rec.medal_id * MEDAL_SIZE * MEDAL_SIZE, MEDAL_SIZE, MEDAL_SIZE, MEDAL_X, rec.medal_y, ROWS - 1)
  end
end

local dumps = 0
local function dump(name, rec, act)
  local f = assert(io.open(OUT .. "/" .. name .. ".act", "wb"))
  local g = assert(io.open(OUT .. "/" .. name .. ".exp", "wb"))
  for y = 0, ROWS - 1 do
    local a, e = {}, {}
    for x = 1, W do a[x] = string.char(act[y * W + x]); e[x] = string.char(E[y * W + x]) end
    f:write(table.concat(a)); g:write(table.concat(e))
  end
  f:close(); g:close()
end

-- Compares the page with the reference; returns the number of differing pixels and a description.
local act = {}
local function compare(rec, name, opts)
  opts = opts or {}
  local mask = opts.mask                 -- { x0, y0, x1, y1 }: pixels not compared
  local allow = opts.allow               -- allow[y * W + x + 1]: another value the pixel may have
  build_expected(rec)
  local bad, x0, x1, y0, y1 = 0, W, -1, ROWS, -1
  local first = {}
  local base = rec.page * W
  for y = 0, ROWS - 1 do
    local vb, eb = y * 1024 + base, y * W
    for x = 0, W - 1 do
      local a = vram:read_u8(vb + x)
      act[eb + x + 1] = a
      if mask and x >= mask[1] and x <= mask[3] and y >= mask[2] and y <= mask[4] then
        E[eb + x + 1] = a
      elseif allow and allow[eb + x + 1] == a then
        E[eb + x + 1] = a
      elseif a ~= E[eb + x + 1] then
        bad = bad + 1
        if x < x0 then x0 = x end
        if x > x1 then x1 = x end
        if y < y0 then y0 = y end
        if y > y1 then y1 = y end
        if #first < 6 then first[#first + 1] = string.format("(%d,%d)=%d exp %d", x, y, a, E[eb + x + 1]) end
      end
    end
  end
  if bad == 0 then return 0 end
  local desc = string.format("%d px in x %d..%d, y %d..%d: %s", bad, x0, x1, y0, y1, table.concat(first, " "))
  if opts.keep or dumps < MAX_DUMPS then
    if not opts.keep then dumps = dumps + 1 end
    dump(name, rec, act)
    shot(name .. "-screen")
    desc = desc .. " -> " .. name .. ".png"
  end
  return bad, desc
end

-- ---------------------------------------------------------------- keyboard
local fields, matrix = {}, {}
for tag, port in pairs(machine.ioport.ports) do
  if tag:find("^:kbd:") then for fname, f in pairs(port.fields) do fields[fname] = f end end
  if tag:find("^:IO_LINE") then for fname, f in pairs(port.fields) do matrix[fname] = f end end
end
local function mkey(name) return assert(matrix[name], "no matrix key " .. name) end
local shifted = { [":"] = ";", ["_"] = "-", ["+"] = "=" }
local HOLD = 3
local function press(ch)
  local name, sh = ch, false
  if ch:match("%l") then name = ch:upper()
  elseif ch == "\n" then name = "Enter"
  elseif shifted[ch] then name, sh = shifted[ch], true end
  local f = assert(fields[name], "no key field for '" .. ch .. "'")
  if sh then fields["Left Shift"]:set_value(1); frames(HOLD) end
  f:set_value(1); frames(HOLD)
  f:set_value(0)
  if sh then frames(HOLD); fields["Left Shift"]:set_value(0) end
  frames(HOLD)
end
local function type_line(s)
  for i = 1, #s do press(s:sub(i, i)) end
  press("\n")
end
local space_down = false
local function space(down)
  if down ~= space_down then mkey("SPACE"):set_value(down and 1 or 0); space_down = down end
end
local function esc()                     -- a PC Esc is CS+Space in the matrix (CheckControlKey)
  space(false)
  mkey("CAPS SHIFT"):set_value(1); frames(1)
  mkey("SPACE"):set_value(1); frames(4)
  mkey("SPACE"):set_value(0); frames(1)
  mkey("CAPS SHIFT"):set_value(0)
end

-- ---------------------------------------------------------------- per-frame checks
local st = {
  shown = 0, compared = 0, bad_frames = 0, slow = 0, spawned = 0, moving = 0, left_clip = 0, right_clip = 0,
  overlap = 0, switches = {}, max_fall = 0, slow_at = {}, medal_seen = {},
  slot_level = {},                       -- tube slot -> level it was spawned at (nil: initial tube)
  by_level = {},                         -- level -> { n = entered, moving = moving }
}

-- A tube slot was reused for a new tube: CacheSpawnTube put it a spawn distance to the right of
-- max(319, the rightmost tube) as it was then; slots after this one were moved 1 px after it.
local function check_spawn(rec, i)
  local base = 319
  for j, t in ipairs(rec.tubes) do
    local x = j > i and t.x + 1 or t.x
    if j ~= i and x >= 0 and x > base then base = x end
  end
  local d = rec.tubes[i].x - base
  if not spawn_distance_ok(rec.level, d) then
    fail("tube-spawn", "frame %d: tube %d spawned %d px after x=%d at level %d", rec.seq, i, d, base, rec.level)
  end
end

local function check_tubes(prev, rec)
  if rec.mode == MODE.READY then st.slot_level = {} end
  local scored = false
  for i, tb in ipairs(rec.tubes) do
    local pt = prev and prev.tubes[i]
    if tb.x < 0 then st.slot_level[i] = nil end   -- the old tube is leaving; a missed respawn stays unchecked
    if tb.y ~= 0 then
      if tb.x < 0 then st.left_clip = st.left_clip + 1 end
      if tb.x + TUBE_W > W then st.right_clip = st.right_clip + 1 end
      if tb.x < -(TUBE_W - 1) or tb.x > W - 4 then fail("tube-x", "frame %d: tube %d drawn at x=%d", rec.seq, i, tb.x) end
      if tb.y < TUBE_MIN_Y or tb.y > FIELD_H - HEAD_H - 1 - tb.gap then
        fail("tube-y", "frame %d: tube %d y=%d gap=%d is outside %d..%d", rec.seq, i, tb.y, tb.gap, TUBE_MIN_Y, FIELD_H - HEAD_H - 1 - tb.gap)
      end
      if tb.phase ~= 0 and math.abs(tb.y - tb.base) > 8 then
        fail("tube-move", "frame %d: moving tube %d y=%d is more than 8 from its base %d", rec.seq, i, tb.y, tb.base)
      end
      if tb.x == -10 then scored = true end
      if tb.x + TUBE_W > BIRD_X and tb.x < BIRD_X + BIRD_W then
        local y = clamp_tube_y(tb)
        if rec.bird_y + 2 < y + HEAD_H or rec.bird_y + 10 >= y + tb.gap then st.overlap = st.overlap + 1 end
      end
    end
    if pt and prev.seq + 1 == rec.seq and rec.mode == MODE.PLAY then
      if tb.x == pt.x - 1 then
        if tb.y ~= 0 and pt.y ~= 0 then
          if tb.gap ~= pt.gap then fail("tube-gap", "frame %d: tube %d gap changed %d -> %d", rec.seq, i, pt.gap, tb.gap) end
          if tb.phase == 0 and tb.y ~= pt.y then fail("tube-y", "frame %d: static tube %d moved vertically %d -> %d", rec.seq, i, pt.y, tb.y) end
          if tb.phase ~= 0 and math.abs(tb.y - pt.y) > 2 then fail("tube-move", "frame %d: moving tube %d jumped %d -> %d", rec.seq, i, pt.y, tb.y) end
        end
      elseif tb.x > pt.x then              -- the slot was reused for a new tube on the right
        st.spawned = st.spawned + 1
        st.slot_level[i] = rec.level
        check_spawn(rec, i)
        if pt.x > -(TUBE_W - 1) then fail("tube-spawn", "frame %d: tube %d respawned from x=%d, still on screen", rec.seq, i, pt.x) end
        if tb.x < W then fail("tube-spawn", "frame %d: tube %d appeared inside the screen at x=%d", rec.seq, i, tb.x) end
      else
        fail("tube-x", "frame %d: tube %d x %d -> %d, expected a 1 px step", rec.seq, i, pt.x, tb.x)
      end
    end
  end
  for i, tb in ipairs(rec.tubes) do        -- a newly visible tube: remember its kind, check its gap
    local pt = prev and prev.tubes[i]
    if tb.y ~= 0 and pt and pt.y == 0 and tb.x > W / 2 then
      if tb.phase ~= 0 then st.moving = st.moving + 1 end
      if os.getenv("FB_TRACE") then log("  tube %d enters: y=%d gap=%d phase=%d base=%d (score %d, level %d)", i, tb.y, tb.gap, tb.phase, tb.base, rec.score, rec.level) end
      local lv = st.slot_level[i]
      if lv then                             -- spawned during play: the parameters of its level
        local s = st.by_level[lv] or { n = 0, moving = 0 }
        st.by_level[lv] = s
        s.n = s.n + 1
        if tb.phase ~= 0 then s.moving = s.moving + 1 end
        if tb.gap ~= LEVEL_GAP[lv] then
          fail("tube-gap", "frame %d: tube %d spawned at level %d has gap %d, expected %d", rec.seq, i, lv, tb.gap, LEVEL_GAP[lv])
        elseif tb.phase == 0 and not static_y_ok(lv, tb.gap, tb.y) then
          fail("tube-y", "frame %d: static tube %d spawned at level %d has y=%d, not from its table", rec.seq, i, lv, tb.y)
        end
        if lv == 0 and tb.phase ~= 0 then fail("tube-move", "frame %d: moving tube %d spawned at level 0", rec.seq, i) end
      else                                   -- InitialTubes
        local known = false
        for _, g in pairs(LEVEL_GAP) do if g == tb.gap then known = true end end
        if not known then fail("tube-gap", "frame %d: tube %d has gap %d", rec.seq, i, tb.gap) end
      end
    end
  end
  return scored
end

local function check_frame(prev, rec, level)
  local consecutive = prev and prev.seq + 1 == rec.seq
  local scored = check_tubes(prev, rec)
  if rec.mode ~= MODE.PLAY then return end
  if prev and prev.mode == MODE.PLAY then
    if not consecutive then fail("seq", "frame %d shown after frame %d", rec.seq, prev.seq) end
    local dy = rec.bird_y - prev.bird_y
    if dy > st.max_fall then st.max_fall = dy end
    if dy < -5 or dy > 19 then fail("bird", "frame %d: bird y %d -> %d", rec.seq, prev.bird_y, rec.bird_y) end
    local ds = rec.score - prev.score
    if ds ~= (scored and 1 or 0) then
      fail("score", "frame %d: score %d -> %d, %s", rec.seq, prev.score, rec.score, scored and "a tube was passed" or "no tube was passed")
    end
  end
  if rec.bird_y > 208 then fail("bird", "frame %d: bird y=%d below the ground", rec.seq, rec.bird_y) end
  if rec.level ~= expected_level(rec.score) then
    fail("level", "frame %d: level %d at score %d, expected %d", rec.seq, rec.level, rec.score, expected_level(rec.score))
  elseif rec.gap ~= LEVEL_GAP[rec.level] then
    fail("level", "frame %d: tube gap %d at level %d, expected %d", rec.seq, rec.gap, rec.level, LEVEL_GAP[rec.level])
  end
end

-- Theme switch: starts with the frame whose score asks for the other theme, ends with the first
-- play frame after it. tr.dark holds the palette darkening of every video frame in between.
local tr
local function check_transition(prev, rec, dark)
  if not tr then
    if rec.mode == MODE.PLAY and rec.theme ~= expected_theme(rec.score) then
      if prev and prev.score == rec.score then
        fail("theme", "frame %d: theme %d at score %d and no switch started", rec.seq, rec.theme, rec.score)
      else
        tr = { pre = rec, dark = {}, redraws = 0, t0 = now() }
        shot(string.format("switch-%d-before", rec.score))
      end
    end
    return
  end
  if rec.mode == MODE.REDRAW then
    tr.redraws = tr.redraws + 1
    local p = tr.pre
    if rec.theme ~= expected_theme(rec.score) then fail("theme", "frame %d: redrawn with theme %d at score %d", rec.seq, rec.theme, rec.score) end
    if rec.score ~= p.score or rec.bird_y ~= p.bird_y then
      fail("switch", "frame %d: the game moved on during the switch (score %d -> %d, bird y %d -> %d)", rec.seq, p.score, rec.score, p.bird_y, rec.bird_y)
    end
    for i, tb in ipairs(rec.tubes) do
      local pt = p.tubes[i]
      if tb.x ~= pt.x or tb.y ~= pt.y then
        fail("switch", "frame %d: tube %d moved during the switch (x %d -> %d, y %d -> %d)", rec.seq, i, pt.x, tb.x, pt.y, tb.y)
      end
    end
    if dark ~= 255 then fail("switch", "frame %d: redrawn page shown with palette darkening %s, expected black", rec.seq, tostring(dark)) end
    return
  end
  -- the first play frame after the switch: the palette went down to black and came back
  local seq = tr.dark
  local s, ok, phase, black, last, lit = {}, true, 1, 0, 0, 0   -- phase 1: fading out, 2: black, 3: fading in
  for i, d in ipairs(seq) do
    s[i] = tostring(d)
    if d == "?" then ok = false
    else
      if d ~= 0 then lit = lit + 1 end
      if phase == 1 then
        if d < last then ok = false elseif d == 255 then phase = 2 end
      end
      if phase == 2 then
        if d == 255 then black = black + 1 else phase = 3 end
      end
      if phase == 3 and d > last then ok = false end
      last = d
    end
  end
  log("  switch at score %d: theme %d -> %d, palette changed for %d frames (%.2f s), darkening per frame: %s", tr.pre.score,
      tr.pre.theme, rec.theme, lit, now() - tr.t0, table.concat(s, " "))
  if not ok or phase ~= 3 or black < 1 then fail("fade", "score %d: the palette did not fade out to black and back in", tr.pre.score) end
  if dark ~= 0 then fail("fade", "score %d: play resumed with palette darkening %s", tr.pre.score, tostring(dark)) end
  if lit > 25 then fail("fade", "score %d: the switch took %d frames, expected a short fade", tr.pre.score, lit) end
  if tr.redraws ~= 2 then fail("switch", "score %d: %d pages redrawn, expected 2", tr.pre.score, tr.redraws) end
  if rec.theme ~= expected_theme(rec.score) then fail("theme", "frame %d: theme %d at score %d after the switch", rec.seq, rec.theme, rec.score) end
  for i, tb in ipairs(rec.tubes) do
    if tb.x ~= tr.pre.tubes[i].x - 1 then
      fail("switch", "frame %d: tube %d x=%d after the switch, expected %d", rec.seq, i, tb.x, tr.pre.tubes[i].x - 1)
    end
  end
  st.switches[#st.switches + 1] = { score = tr.pre.score, theme = rec.theme }
  shot(string.format("switch-%d-after", tr.pre.score))
  tr = nil
end

-- Bird target: the middle of the gap of the nearest tube that has not passed the bird yet.
local tap = 0
local function autopilot(rec)
  local target, best = 100, nil
  for _, tb in ipairs(rec.tubes) do
    if tb.y ~= 0 and tb.x + TUBE_W > BIRD_X and (not best or tb.x < best.x) then best = tb end
  end
  if best then
    local y = clamp_tube_y(best)
    target = y + HEAD_H + (best.gap - HEAD_H - BIRD_H) // 2
  end
  tap = tap + 1
  if rec.bird_y > target + 12 then space(true)
  elseif rec.bird_y > target and tap % 3 == 0 then space(true)
  else space(false) end
end

-- Get Ready banner and countdown digit (CacheDrawGetReadyTitle, CacheDrawReadyCountdown): not in
-- the reference picture. A page redrawn after a pause in the countdown must show them as before.
local READY_BOX = { 112, 112, 207, 163 }
local function read_box(page, box)
  local t = {}
  for y = box[2], box[4] do
    for x = box[1], box[3] do t[#t + 1] = vram:read_u8(y * 1024 + page * W + x) end
  end
  return t
end
local function check_ready_banner(rec)
  st.ready_redraws = (st.ready_redraws or 0) + 1
  local was = st.ready_banner and st.ready_banner[rec.page]
  if not was then return end
  local now_box, bad = read_box(rec.page, READY_BOX), 0
  for i, v in ipairs(was) do if now_box[i] ~= v then bad = bad + 1 end end
  if bad > 0 then
    fail("pause", "frame %d: Get Ready banner redrawn after the pause differs in %d px", rec.seq, bad)
    shot(string.format("ready-banner-%05d", rec.seq))
  end
end

local prev                                -- the last frame seen
local function tick(pilot)
  local rg = cpu.state["RGMOD"].value & 1
  local rec = read_rec(rg)
  local level = palette_dark()
  if tr then tr.dark[#tr.dark + 1] = level end
  if not prev or rec.seq ~= prev.seq then
    st.shown = st.shown + 1
    check_frame(prev, rec, level)
    check_transition(prev, rec, level)
    if rec.mode == MODE.PLAY and rec.medal_y ~= 255 and not st.medal_seen[rec.medal_id] then
      st.medal_seen[rec.medal_id] = rec.score
    end
    local ready_redraw = rec.mode == MODE.REDRAW and rec.ready > 0
    if ready_redraw then check_ready_banner(rec) end
    if rec.mode == MODE.PLAY or rec.mode == MODE.REDRAW then
      st.compared = st.compared + 1
      local bad, desc = compare(rec, string.format("mismatch-%05d", rec.seq), ready_redraw and { mask = READY_BOX } or nil)
      if bad > 0 then
        st.bad_frames = st.bad_frames + 1
        fail("picture", "frame %d (score %d, theme %d): %s; tubes %s; bird y=%d", rec.seq, rec.score, rec.theme, desc, tube_str(rec), rec.bird_y)
      end
    end
    prev = rec
  elseif rec.mode == MODE.PLAY and not tr and level == 0 then
    st.slow = st.slow + 1                 -- the same frame shown twice: the game missed a vsync
    if st.slow <= 10 then st.slow_at[#st.slow_at + 1] = string.format("%d(score %d)", rec.seq, rec.score) end
  end
  if pilot then autopilot(rec) end
  return rec
end

-- ---------------------------------------------------------------- scenario
local function scenario()
  log("mame_fbird.lua: sym=%s target score=%d", SYM:match("[^/]+$"), TARGET_SCORE)
  while now() < 10 do frames(1) end       -- DSS boot to the File Manager takes ~6 emulated seconds
  for i = 0, 3 do fast:write_u8(S("DbgMagic") + i, 0) end
  type_line(EXE_CMD)

  -- boot, followed by the palette in VRAM: the Sprinter logo fades in, stays at full brightness
  -- for at least 3 s (the title is loaded meanwhile), fades out to black; then the title fades in
  -- and, once the rest is loaded, waits for Fire (DbgTitleReady).
  local prog, ready_at = cpu.spaces["program"], S("DbgTitleReady")
  local boot = { state = "pre", fade_in = 0, logo = 0, fade_out = 0, title_in = 0 }
  local t0 = now()
  while now() - t0 < 120 and not (boot.state == "title" and prog:read_u8(ready_at) == 1) do
    frames(1)
    if boot.state == "pre" then
      if not st.console_shot and now() - t0 > 8 then st.console_shot = true; shot("console") end   -- the banner, while the logo loads
      if palette_is(logo_pal) then boot.state, boot.logo = "logo", 1; shot("logo")
      elseif palette_is(nil, #logo_pal) then boot.fade_in = 0
      else boot.fade_in = boot.fade_in + 1 end
    elseif boot.state == "logo" then
      if palette_is(logo_pal) then boot.logo = boot.logo + 1 else boot.state, boot.fade_out = "out", 1 end
    elseif boot.state == "out" then
      if palette_is(nil, #title_pal) then boot.state = "dark" else boot.fade_out = boot.fade_out + 1 end
    elseif boot.state == "dark" then
      if palette_is(title_pal) then boot.state = "title"
      elseif not palette_is(nil, #title_pal) then boot.title_in = boot.title_in + 1 end
    end
  end
  log("boot %.1f s: logo fade in %d frames, at full brightness %d frames (%.1f s), fade out %d frames; title fade in %d frames",
      now() - t0, boot.fade_in, boot.logo, boot.logo / 50, boot.fade_out, boot.title_in)
  if boot.state ~= "title" then fail("boot", "the title did not come in %d s (stopped at %s)", 120, boot.state); shot("no-title"); return end
  if boot.logo < 150 then fail("boot", "the logo stayed %d frames at full brightness, expected at least 150 (3 s)", boot.logo) end
  for _, f in ipairs({ { "logo fade in", boot.fade_in }, { "logo fade out", boot.fade_out }, { "title fade in", boot.title_in } }) do
    if f[2] < 8 then fail("boot", "%s took %d frames: no fade", f[1], f[2]) end
  end
  shot("title")

  -- title: tap Space on the PC/AT (PS/2) keyboard until the render cache (and the debug block
  -- in it) is installed. The PS/2 path (SIO byte -> IRQ vector #FF -> KeysHandler -> KeyPressed)
  -- is the only keyboard when MAME has only "kbd:ms_naturl" enabled; the ZX matrix is used in play.
  local kbd_space = assert(fields["Space"], "no PC keyboard Space field")
  local started = false
  t0 = now()
  while now() - t0 < 30 do
    kbd_space:set_value(1); frames(5); kbd_space:set_value(0)
    frames(40)
    if magic_at(0) then started = true; break end
  end
  if not started then
    for off = 0, 0xC000, 0x4000 do if magic_at(off) then fast_off = off; started = true end end
  end
  if not started then fail("start", "the game did not start in %d s after Fire on the title", 30); shot("no-start"); return end
  log("game started %.1f s after Fire on the title (cache at +%X)", now() - t0, fast_off)

  -- Get Ready countdown, paused in the middle (digit 2 on both pages): the countdown stops with
  -- the message shown, and after Fire both pages are redrawn with the banner and it goes on.
  local rec
  t0 = now()
  repeat frames(1); rec = tick(false) until (rec.mode == MODE.READY and rec.ready <= 100) or now() - t0 > 20
  if rec.mode ~= MODE.READY then fail("start", "no Get Ready countdown 20 s after the start (mode %d)", rec.mode); return end
  st.ready_banner = { [0] = read_box(0, READY_BOX), [1] = read_box(1, READY_BOX) }
  esc()
  frames(40)
  local paused = read_rec(cpu.state["RGMOD"].value & 1)
  shot("pause-ready")
  frames(10)
  rec = read_rec(cpu.state["RGMOD"].value & 1)
  if paused.mode ~= MODE.READY or rec.seq ~= paused.seq or rec.ready ~= paused.ready then
    fail("pause", "Esc in the countdown did not pause it (mode %d, frame %d -> %d, counter %d -> %d)",
         paused.mode, paused.seq, rec.seq, paused.ready, rec.ready)
  end
  space(true)
  repeat frames(1); rec = tick(false) until (rec.mode == MODE.READY and rec.seq ~= paused.seq) or now() - t0 > 20
  space(false)
  if (st.ready_redraws or 0) ~= 2 then fail("pause", "%d pages redrawn after the pause in the countdown, expected 2", st.ready_redraws or 0) end
  if rec.ready ~= paused.ready - 1 then
    fail("pause", "the countdown went on from %d after the pause, expected %d", rec.ready, paused.ready - 1)
  end
  log("pause in the countdown at %d: %d pages redrawn, the countdown went on from %d", paused.ready, st.ready_redraws or 0, rec.ready)
  st.ready_banner = nil
  repeat frames(1); rec = tick(false) until rec.mode == MODE.PLAY or now() - t0 > 20
  if rec.mode ~= MODE.PLAY then fail("start", "no play frame 20 s after the start (mode %d)", rec.mode); return end
  log("play started at frame %d", rec.seq)
  shot("play-day")

  -- play to the target score
  t0 = now()
  local last_score, t_score = -1, now()
  while rec.score < TARGET_SCORE do
    frames(1)
    rec = tick(true)
    if rec.score ~= last_score then
      last_score, t_score = rec.score, now()
      if rec.score == 50 then shot("play-night") end
    end
    if now() - t_score > 30 then fail("stall", "score stuck at %d for 30 s (frame %d)", rec.score, rec.seq); break end
  end
  space(false)
  log("played to score %d: %d frames in %.1f s", rec.score, st.shown, now() - t0)

  -- Pause and continue in the current theme, with a tube under the message. The frame under the
  -- message stays intact; after continue every pixel of it is either still as it was while paused
  -- or already clean, and the frames that follow are whole.
  local box = { S("PAUSE_TEXT_X"), S("PAUSE_TEXT_Y"), S("PAUSE_TEXT_X") + S("PAUSE_TEXT_W") - 1, S("PAUSE_TEXT_Y") + S("PAUSE_TEXT_H") - 1 }
  local function boxed(r)                  -- tubes drawn through the message box
    local n = 0
    for _, tb in ipairs(r.tubes) do
      local y = clamp_tube_y(tb)
      if tb.y ~= 0 and tb.x >= box[1] + 8 and tb.x + TUBE_W <= box[3] - 8 and (y + HEAD_H > box[2] or y + tb.gap <= box[4]) then n = n + 1 end
    end
    return n
  end
  for _ = 1, 600 do                        -- a few frames ahead: the game runs on while Esc is being pressed
    if boxed(rec) > 0 then break end
    frames(1); rec = tick(true)
  end
  local seq = rec.seq
  esc()
  frames(40)
  rec = read_rec(cpu.state["RGMOD"].value & 1)
  shot("pause")
  if rec.seq - seq > 8 then fail("pause", "the game kept running after Esc (%d frames)", rec.seq - seq) end
  local paused = rec.seq
  frames(10)
  rec = read_rec(cpu.state["RGMOD"].value & 1)
  if rec.seq ~= paused then fail("pause", "frames are drawn while paused (%d -> %d)", paused, rec.seq) end
  local bad, desc = compare(rec, "pause-outside-message", { mask = box, keep = true })
  if bad > 0 then fail("pause", "paused frame %d differs outside the message box: %s; tubes %s", rec.seq, desc, tube_str(rec)) end
  local under, was = boxed(rec), {}
  for i, v in pairs(act) do was[i] = v end
  space(true)
  local damaged = false
  for _ = 1, 12 do
    frames(1)
    rec = read_rec(cpu.state["RGMOD"].value & 1)
    if rec.seq ~= paused then break end
    if not damaged then
      bad, desc = compare(rec, "continue-paused-frame", { allow = was, keep = true })
      if bad > 0 then
        damaged = true
        fail("pause", "frame %d is shown damaged after continue (%d tubes cross the message box): %s", paused, under, desc)
      end
    end
  end
  space(false)
  if rec.seq == paused then fail("pause", "the game did not continue after Space") end
  prev = nil
  local resumed = rec.seq
  rec = tick(true)
  for _ = 1, 100 do frames(1); rec = tick(true) end
  space(false)
  if rec.seq - resumed < 50 then fail("pause", "only %d frames in 100 after continue", rec.seq - resumed) end
  log("pause/continue at score %d (theme %d, %d tubes under the message): %d frames after continue", rec.score, rec.theme, under, rec.seq - resumed)

  -- Death and restart in the night theme: the new game starts in the day theme with a whole picture
  local died_theme = rec.theme
  fast:write_u8(S("DbgMortal") + fast_off, 1)
  space(false)
  t0 = now()
  repeat frames(1); rec = tick(false) until rec.mode == MODE.GAMEOVER or now() - t0 > 20
  if rec.mode ~= MODE.GAMEOVER then
    fail("restart", "the mortal bird did not die in 20 s (mode %d)", rec.mode)
  else
    frames(120)                              -- the fall and the restart delay
    shot("game-over")
    space(true); frames(5); space(false)
    t0 = now()
    repeat frames(1); rec = tick(false) until rec.mode == MODE.READY or now() - t0 > 20
    if rec.mode ~= MODE.READY then fail("restart", "no restart 20 s after Space on the game over screen (mode %d)", rec.mode) end
    fast:write_u8(S("DbgMortal") + fast_off, 0)
    t0 = now()
    repeat frames(1); rec = tick(false) until rec.mode == MODE.PLAY or now() - t0 > 20
    local first = st.compared
    for _ = 1, 300 do frames(1); rec = tick(true) end
    space(false)
    shot("restart")
    if rec.mode ~= MODE.PLAY or st.compared - first < 250 then fail("restart", "the restarted game does not play (mode %d)", rec.mode) end
    if rec.theme ~= 0 or rec.score > 5 then fail("restart", "restarted with theme %d, score %d", rec.theme, rec.score) end
    log("death in theme %d and restart: theme %d, score %d, %d frames compared", died_theme, rec.theme, rec.score, st.compared - first)
  end

  -- Esc, Esc: back to DSS
  esc(); frames(40)
  esc(); frames(150)
  local a = read_rec(0).seq + read_rec(1).seq
  frames(50)
  if read_rec(0).seq + read_rec(1).seq ~= a then fail("exit", "the game is still drawing frames after Esc, Esc") end
  shot("after-exit")

  log("frames shown %d, compared %d, with a wrong picture %d, shown twice (slow) %d%s", st.shown, st.compared, st.bad_frames, st.slow,
      st.slow > 0 and ": frames " .. table.concat(st.slow_at, " ") or "")
  log("tubes spawned %d (moving %d), frames with a tube clipped left %d / right %d, max fall %d px/frame", st.spawned, st.moving,
      st.left_clip, st.right_clip, st.max_fall)
  log("autopilot: %d frames inside a tube (immortal bird, hit counter %d)", st.overlap, rec.hits)
  local want = {}
  for s = 50, TARGET_SCORE, 50 do want[#want + 1] = s end
  local got = {}
  for _, s in ipairs(st.switches) do got[#got + 1] = s.score end
  if table.concat(got, ",") ~= table.concat(want, ",") then
    fail("theme", "theme switches at scores [%s], expected [%s]", table.concat(got, ","), table.concat(want, ","))
  end
  local parts = {}
  for lv = 0, #LEVEL_GAP do
    local s = st.by_level[lv]
    if s then parts[#parts + 1] = string.format("L%d %d/%d", lv, s.moving, s.n) end
  end
  log("moving tubes by spawn level (moving/all): %s", table.concat(parts, " "))
  for id, s in pairs(MEDAL_SCORE) do      -- every medal reached appears exactly at its score
    if s <= TARGET_SCORE and st.medal_seen[id] ~= s then
      fail("medal", "medal %d first seen at score %s, expected %d", id, tostring(st.medal_seen[id]), s)
    end
  end
  for id, s in pairs(st.medal_seen) do    -- and none early or unknown (#ff: no medal yet)
    if id ~= 255 and MEDAL_SCORE[id] ~= s then fail("medal", "medal %d appeared at score %d", id, s) end
  end
  if st.compared < 100 then fail("coverage", "only %d frames compared", st.compared) end
  if TARGET_SCORE >= 40 and st.moving == 0 then fail("coverage", "no moving tube in %d tubes", st.spawned) end
end

local co = coroutine.create(function()
  local ok, err = pcall(scenario)
  if not ok then failures = failures + 1; log("SCRIPT ERROR: %s", tostring(err)) end
  for kind, n in pairs(fail_counts) do if n > 5 then log("  [%s]: %d failures in total", kind, n) end end
  log("RESULT: %s (%d failure(s))", failures == 0 and "PASS" or "FAIL", failures)
  out:close()
  machine:exit()
end)

emu.register_frame_done(function()
  if coroutine.status(co) == "suspended" then
    local ok, err = coroutine.resume(co)
    if not ok then print("coroutine error: " .. tostring(err)); machine:exit() end
  end
end)
