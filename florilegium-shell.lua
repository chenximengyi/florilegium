-- florilegium-shell.lua -- shells for florilegium: an ammonite, a scallop, a whelk ... drawn from its genome.
-- Copyright (c) 2026 Kevin Raymond. MIT License: see LICENSE or florilegium.sty.
--
-- A shell (florilegium-species.lua: M.shsample) drawn with ink in the local unit of the
-- current transform, in the hand of the plants and the snail: florilegium-native.lua's
-- tones, mottle and streaks, from pgf's generator, so the TikZ library can draw it step
-- for step. The coil is Raup's (1966): a tube whose ring widens W times a turn, its inner
-- edge D of its outer from the axis, placed as Okabe and Yoshimura (2017) place it, the
-- ring a circle of radius 1 whose center is y0 = (1 + D) / (1 - D) from the axis. A
-- planispiral seen from the side, down its axis, is flat drawing: a whorl is the band
-- between the spirals r = (y0 - 1) l and r = (y0 + 1) l, l = W^(th/360), and the next
-- whorl, W times wider, covers its outer part (the shells report, part A, step 10). So
-- what shows of each whorl is the band from its own inner edge to the next whorl's inner
-- edge, these bands tile the disc, and the line between two of them, the suture, is one
-- spiral. Angles are degrees, as pgfmath takes them.

local ink = require("florilegium-ink")
local M = {}
M.version = "2.0.1"                 -- the release; florilegium.lua checks that every file has the same

local floor, ceil, min, max, sqrt, abs = math.floor, math.ceil, math.min, math.max, math.sqrt, math.abs
local RAD = math.pi / 180
local function sin(a) return math.sin(a * RAD) end
local function cos(a) return math.cos(a * RAD) end
local moveto, lineto, curveto, close = ink.moveto, ink.lineto, ink.curveto, ink.close
local fill, stroke = ink.fill, ink.stroke

local N                               -- florilegium-native.lua: the pen, tone, mottle, streak
local G                               -- pgf's generator for this drawing
local function range(a, b) return a + (b - a) * G.rnd() end                -- \flo@range
local function sym(a) return a * G.rand() end                              -- \flo@sym
local function chance(p) return G.rnd() * 65536 < floor(p * 65536 + 0.5) end
local function K(x) return floor(x * 65536 + 0.5) / 65536 end              -- a constant as TeX holds it
local function tone(t) return N.tone(t) end
local WHITE = ink.white

-- the drawing: cm and bp per unit of the shell's frame, the pen (bp), the base tone, the
-- level of detail (0 everything, 1 small, 2 tiny)
local D = {}

-- ---------------------------------------------------------------- paths
-- an open Catmull-Rom curve through the points, appended to ink's path as ink.smooth
-- draws a closed one; `first` starts it with a moveto, else a line joins it to the path
local function curve(pts, first)
  local n = #pts
  local function at(i) return pts[max(1, min(n, i))] end
  if first then moveto(pts[1][1], pts[1][2]) else lineto(pts[1][1], pts[1][2]) end
  for i = 1, n - 1 do
    local p0, p1, p2, p3 = at(i - 1), at(i), at(i + 1), at(i + 2)
    curveto(p1[1] + (p2[1] - p0[1]) / 6, p1[2] + (p2[2] - p0[2]) / 6,
      p2[1] - (p3[1] - p1[1]) / 6, p2[2] - (p3[2] - p1[2]) / 6, p2[1], p2[2])
  end
end
local function reversed(pts)
  local out = {}
  for i = #pts, 1, -1 do out[#out + 1] = pts[i] end
  return out
end
-- the points from i to j of a list
local function slice(pts, i, j)
  local out = {}
  for k = i, j do out[#out + 1] = pts[k] end
  return out
end
-- the points f of the way from a to b, pointwise
local function across(a, b, f)
  local out = {}
  for i = 1, #a do out[i] = { a[i][1] + f * (b[i][1] - a[i][1]), a[i][2] + f * (b[i][2] - a[i][2]) } end
  return out
end
-- the longest run of points where ok(i) holds, as its first and last index (nil if none)
local function run(n, ok)
  local b0, b1, c0 = nil, nil, nil
  for i = 1, n do
    if ok(i) then
      c0 = c0 or i
      if not b0 or i - c0 > b1 - b0 then b0, b1 = c0, i end
    else
      c0 = nil
    end
  end
  return b0, b1
end

-- ---------------------------------------------------------------- planispirals
local P = {}
-- the radius at growth angle th (0 the mouth's ring, older whorls negative), f of the way
-- from the tube's inner edge (0) to its outer (1)
local function rad(th, f) return P.W ^ (th / 360) * (P.y0 - 1 + 2 * f) end
-- the point at growth angle th and radius r: the coil winds either way, as either flank shows
local function pt(th, r)
  local a = P.ph + P.sense * th
  return { r * cos(a), r * sin(a) }
end
-- where whorl k (0 the last) shows to at th: its own outer edge on the last turn, else the
-- next whorl's inner edge, which lies on it
local function vout(th, k)
  if k == 0 then return rad(th, 1) end
  return rad(th + 360, 0)
end
-- whorl k's visible band: the growth angles, its inner edge, the edge it shows to, the light
-- on it (the outward normal's cosine with the upper left of the page)
local function band(k)
  local t1 = P.tm - 360 * k
  local t0 = max(P.tmin, t1 - 360)
  local n = max(2, ceil((t1 - t0) / 10))
  local B = { k = k, t0 = t0, t1 = t1, TH = {}, I = {}, O = {}, L = {}, W = {} }
  for i = 0, n do
    local th = t0 + (t1 - t0) * i / n
    local ri, ro = rad(th, 0), vout(th, k)
    B.TH[i + 1] = th
    B.I[i + 1], B.O[i + 1] = pt(th, ri), pt(th, ro)
    B.W[i + 1] = ro - ri
    B.L[i + 1] = cos(P.ph + P.sense * th - 135)
  end
  return B
end
local function bandpath(B)
  curve(B.O, true) curve(reversed(B.I), false) close()
end
-- a rib across band B at growth angle th: its points from the inner edge (u 0) out to the
-- edge it shows to (u 1), leaning toward the mouth, from u0 to u1, turned `turn` degrees at
-- its outer end
local function ribpts(B, th, u0, u1, lean, turn)
  local pts = {}
  for i = 0, 3 do
    local u = u0 + (u1 - u0) * i / 3
    -- back a little near the umbilicus, then forward toward the outer edge (prorsiradiate)
    local a = th + lean * (u ^ 1.6 - 0.25 * sin(180 * u)) + (turn or 0) * ((u - u0) / max(1e-6, u1 - u0)) ^ 1.5
    local ri, ro = rad(a, 0), vout(a, B.k)
    pts[i + 1] = pt(a, ri + u * (ro - ri))
  end
  return pts
end
-- a streak along the points, thin at both ends and w wide in the middle
local function swell(pts, w, c, op)
  ink.smooth(N.ribbonpts(pts, function(d, acc) return w * sin(180 * d / acc) / 2 end), true) fill(c, op)
end
local function taperpts(p, wa, wb, c, op)
  N.taper(p[1][1], p[1][2], p[2][1], p[2][2], p[3][1], p[3][2], p[4][1], p[4][2], wa, wb)
  fill(c, op, true)
end
-- the ribs on band B: n a whorl, simple, forking or knobbed, where they stand at least
-- half a millimeter apart on the page; a mold's are softer
local function ribs(s, B)
  local n = s.ribs
  local d = 360 / n
  local mid = floor(#B.TH / 2) + 1
  local rout = B.O[mid] and sqrt(B.O[mid][1] ^ 2 + B.O[mid][2] ^ 2) or 0
  local gap = rout * d * RAD                          -- the ribs' spacing at the band's outer edge
  if gap * D.cm < K(0.05) then return end
  local mold = s.preservation == "mold"
  local op = mold and 0.3 or 0.42
  local lean = 0.45 * d                              -- toward the mouth, more at the outer edge
  local light = D.lod == 0 and not mold
  local th = B.t1 - d * (0.5 + range(0, 0.4))
  while th > B.t0 + 0.2 * d do
    local wb = gap * range(0.12, 0.17)
    if s.sculpture == "branching" then
      local stem = ribpts(B, th, 0, 0.5, lean)
      taperpts(stem, 0.03 * gap, 0.9 * wb, tone(D.t - 0.18), op)
      if light then taperpts(ribpts(B, th - 0.22 * d, 0.05, 0.5, lean), 0.01 * gap, 0.5 * wb, WHITE, 0.4) end
      local fa = th + lean * (0.5 ^ 1.6 - 0.25)
      for side = -1, 1, 2 do
        local fork = ribpts(B, fa, 0.5, 1, lean * 0.5, side * 0.2 * d)
        taperpts(fork, 0.6 * wb, wb, tone(D.t - 0.18), op)
        if light then taperpts(ribpts(B, fa - 0.18 * d, 0.5, 1, lean * 0.5, side * 0.2 * d), 0.3 * wb, 0.55 * wb, WHITE, 0.4) end
      end
    else
      local r = ribpts(B, th, 0, 1, lean)
      taperpts(r, 0.03 * gap, wb, tone(D.t - 0.18), op)
      if light then taperpts(ribpts(B, th - 0.25 * d, 0.05, 1, lean), 0.01 * gap, 0.6 * wb, WHITE, 0.45) end
      if s.sculpture == "tubercles" then
        for _, u in ipairs({ 0.3, B.k == 0 and 0.85 or nil }) do
          local a = th + lean * u ^ 1.3
          local ri, ro = rad(a, 0), vout(a, B.k)
          local c = pt(a, ri + u * (ro - ri))
          local kr = gap * range(0.26, 0.36)
          ink.smooth(N.blob(c[1], c[2], kr, kr * 0.85, 0.2, 7), true) fill(tone(D.t - 0.2), op + 0.1, true)
          ink.circle(c[1] - 0.35 * kr, c[2] + 0.35 * kr, 0.22 * kr) fill(WHITE, mold and 0.25 or 0.45)
        end
      end
    end
    th = th - d * range(0.85, 1.15)
  end
end
-- the suture lines of the septa on a mold, across the inner whorls and the last one up to
-- its body chamber: lobes (back toward the older whorls) and saddles across the band, as
-- the kind of suture has them: zigzag (goniatitic), the lobes frilled (ceratitic), or all
-- of it frilled (ammonitic)
local function septa(s, B, chamber)
  local d = 360 / 12
  local th = min(B.t1, P.tm - chamber) - d * range(0.2, 0.8)
  local nl = 2.5                                     -- saddles and lobes across the band
  local npts = D.lod == 0 and 96 or 40
  local f1, f2 = range(0, 360), range(0, 360)
  while th > B.t0 + 0.3 * d do
    -- a lobe about as deep as it is wide: its depth a length, a fraction of the whorl's height
    local hw = vout(th, B.k) - rad(th, 0)
    local pts = {}
    for i = 0, npts do
      local u = i / npts
      -- a saddle (forward) is broad and round, a lobe (back) narrower and deeper
      local base = sin(360 * nl * u)
      local w = base > 0 and 0.75 * base ^ 0.7 or -1.15 * (-base) ^ 1.3
      if s.septa == "goniatitic" then
        w = base > 0 and 0.75 * base ^ 0.7 or -1.2 * (1 - math.acos(-base) / (math.pi / 2))   -- pointed lobes
      elseif s.septa == "ceratitic" then
        if base < 0 then w = w + 0.25 * sin(360 * 5 * nl * u + f1) * (-base) end         -- the lobes toothed
      else
        -- ammonitic: frilled everywhere, the frills of frills where there is room
        local fr = 0.3 * sin(360 * 4 * nl * u + f1)
        if D.lod == 0 then fr = fr + 0.14 * sin(360 * 11 * nl * u + f2) end
        w = w + fr * (0.35 + 0.65 * abs(base))
      end
      local ri0 = rad(th, 0)
      local a = th + 0.16 * hw * w / (ri0 + u * hw) / RAD
      local ri, ro = rad(a, 0), vout(a, B.k)
      pts[i + 1] = pt(a, ri + u * (ro - ri))
    end
    curve(pts, true) stroke(tone(0.06), 0.4 * D.pen, 0.55, true)
    th = th - d * range(0.85, 1.15)
  end
end
-- a nautilus's flame stripes: across the older part of its last whorl, fading toward the
-- mouth, wider at the outer edge
local function flames(s, B)
  local n = floor(range(10, 15))
  local span = 360 * 0.62
  for j = 1, n do
    local th = B.t0 + span * (j - range(0.3, 0.7)) / n
    local fade = 1 - (th - B.t0) / span
    local pts = {}
    for i = 0, 5 do
      local u = 0.04 + 0.92 * i / 5
      local a = th + 4 * u + sym(2.5)
      local ri, ro = rad(a, 0), vout(a, 0)
      pts[i + 1] = pt(a, ri + u * (ro - ri))
    end
    local gap = rad(th, 1) * (span / n) * RAD
    N.streak(pts, 0.1 * gap, gap * range(0.4, 0.65), tone(D.t - 0.36), (0.35 + 0.5 * s.contrast) * (0.3 + 0.7 * fade))
  end
end
-- the shading of a visible band: a shadow along the edge it shows to (where the next whorl
-- covers it, or the last whorl's venter curving away), another along its inner edge (the
-- slope into the umbilicus), the venter darker toward the lower right, the light on the
-- flank toward the upper left
local function shade(s, B)
  local n = #B.I
  local w0, w1 = B.W[1], B.W[n]
  N.streak(B.O, 0.34 * w0, 0.34 * w1, tone(0.08), 0.28)
  N.streak(B.I, 0.16 * w0, 0.16 * w1, tone(0.1), 0.16)
  if B.k == 0 then
    local b0, b1 = run(n, function(i) return B.L[i] < K(-0.2) end)
    if b0 and b1 - b0 >= 3 then
      N.streak(slice(B.O, b0, b1), 0.2 * B.W[b0], 0.5 * B.W[b1], tone(0.06), 0.24)
    end
  end
  if B.k <= 2 and s.preservation ~= "mold" then
    local b0, b1 = run(n, function(i) return B.L[i] > K(0.15) end)
    if b0 and b1 - b0 >= 3 then
      local mid = across(B.I, B.O, 0.42)
      swell(slice(mid, b0, b1), 0.17 * B.W[floor((b0 + b1) / 2)], WHITE, B.k == 0 and 0.5 or 0.35)
    end
  end
end
local function planispiral(s, size)
  P.W, P.n = s.expansion, s.whorls
  P.y0 = (1 + s.umbilicus) / (1 - s.umbilicus)
  P.sense = chance(0.5) and 1 or -1
  P.ph = range(20, 80)                               -- where the mouth's ring lies
  P.tm = s.broken == 1 and -range(40, 110) or 0     -- a broken shell ends before its mouth
  P.tmin = P.tm - 360 * P.n
  local J = ceil(P.n)
  local bands = {}
  for k = 0, J - 1 do bands[k + 1] = band(k) end
  local last = bands[1]
  -- the frame: the last whorl's outer edge; the shell `size` across at most, its base on the
  -- origin
  local x0, x1, y0, y1 = 1e9, -1e9, 1e9, -1e9
  for _, p in ipairs(last.O) do x0, x1, y0, y1 = min(x0, p[1]), max(x1, p[1]), min(y0, p[2]), max(y1, p[2]) end
  local sc = size / max(x1 - x0, y1 - y0)
  local unit = ink.unit()                            -- cm per local unit, before the shell's frame
  ink.push()
  ink.translate(-(x0 + x1) / 2 * sc, -y0 * sc)
  ink.scale(sc)
  D.cm = sc * unit                                   -- cm per unit of the shell's frame
  D.bp = D.cm * 28.3465
  local across_cm = size * unit
  D.lod = across_cm < K(0.5) and 2 or across_cm < K(1.2) and 1 or 0
  D.pen = max(0.3, min(0.85, 0.028 * across_cm * 28.3465))
  local mold = s.preservation == "mold"
  local t = s.tone - 0.04
  if s.ground == "pale" then t = min(0.72, t + 0.25) elseif s.ground == "dark" then t = t - 0.12 end
  if mold then t = min(0.74, t + 0.16) end
  local accent = s.preservation == "pyrite"
  if accent then N.pen.accent = true t = t + 0.04 end
  D.t = t
  local chamber = range(180, 260)                    -- the body chamber, the last whorl's front
  local ribbed = s.ribs > 0
  -- inside out, each whorl's band: its wash, then in its clip the shading, the stone's
  -- grain or the shell's mottle, the stripes, ribs and suture lines
  for k = J - 1, 0, -1 do
    local B = bands[k + 1]
    N.pen.accent = accent or (s.preservation == "nacre" and k >= 1)
    local tk = t + sym(0.03)
    bandpath(B) fill(tone(tk), 1)
    local bw = B.W[#B.W] * D.cm                     -- the band across at its widest, cm
    if D.lod < 2 and bw > K(0.03) then
      bandpath(B) ink.clip()
      shade(s, B)
      if D.lod == 0 and bw > K(0.12) then
        local bx0, bx1, by0, by1 = 1e9, -1e9, 1e9, -1e9
        for _, p in ipairs(B.O) do bx0, bx1, by0, by1 = min(bx0, p[1]), max(bx1, p[1]), min(by0, p[2]), max(by1, p[2]) end
        N.mottle(bx0, by0, bx1, by1, mold and 7 or 4, 0.12 * (bx1 - bx0), tk - 0.14, tk + 0.18, mold and 14 or 4)
      end
      if s.kind == "nautilus" and (k == 0 or bw > K(0.1)) then flames(s, B) end
      if ribbed then ribs(s, B) end
      if mold and D.lod == 0 then septa(s, B, chamber) end
      if k == 0 and s.preservation == "nacre" then
        -- worn through to the nacre: copper streaks along the whorl, as wear follows it
        N.pen.accent = true
        -- the inner part of the whorl's older half, out to a ragged edge, and a glint
        local n = #B.I
        local i1 = floor(n * range(0.45, 0.6))
        local edge = across(B.I, B.O, range(0.35, 0.5))
        local patch = {}
        for i = 1, i1 do patch[#patch + 1] = { edge[i][1] + sym(0.05 * B.W[i]), edge[i][2] + sym(0.05 * B.W[i]) } end
        for i = i1, 1, -1 do patch[#patch + 1] = B.I[i] end
        ink.smooth(patch, true) fill(tone(t + 0.18), 0.4)
        swell(slice(across(B.I, B.O, 0.18), 2, i1 - 1), 0.08 * B.W[floor(i1 / 2)], WHITE, 0.45)
        N.pen.accent = false
      end
      ink.unclip()
    end
  end
  N.pen.accent = accent
  -- the lines: each whorl's inner edge, which is the suture on the whorl before it (and the
  -- umbilical seam), then the last whorl's outer edge, a keel inside it, and the mouth
  for k = J - 1, 0, -1 do
    local B = bands[k + 1]
    if D.lod < 2 or k <= 1 then
      curve(B.I, true) stroke(tone(0.06), (k == 0 and 0.75 or 0.6) * D.pen, 0.75, true)
    end
  end
  if s.keel ~= "none" and D.lod < 2 then
    curve(across(last.I, last.O, 0.94), true) stroke(tone(0.08), 0.45 * D.pen, 0.6, true)
    if s.keel == "grooved" then curve(across(last.I, last.O, 0.88), true) stroke(tone(0.06), 0.4 * D.pen, 0.55, true) end
  end
  curve(last.O, true) stroke(tone(0.05), D.pen, 0.85, true)
  -- the mouth: across the tube at its last ring, bowed toward the mouth (a nautilus's back
  -- at its outer edge, the sinus its funnel leaves), a pale lip behind it; a broken shell's
  -- edge is jagged
  local mouth = {}
  local nb = 6
  for i = 0, nb do
    local u = i / nb
    local a = P.tm
    if s.broken == 1 then a = a + (i > 0 and i < nb and sym(5) or 0)
    elseif s.kind == "nautilus" then a = a - 9 * u ^ 2
    else a = a + 3.5 * sin(180 * u) end
    mouth[i + 1] = pt(a, rad(a, 0) + u * (rad(a, 1) - rad(a, 0)))
  end
  -- the opening, seen a little from the front past the mouth's line: deepest toward the outer
  -- edge, darkest within
  local hw = rad(P.tm, 1) - rad(P.tm, 0)
  local a = P.ph + P.sense * P.tm
  local tx, ty = -sin(a) * P.sense, cos(a) * P.sense                -- along the coil, toward the mouth
  local inside = {}
  for i = nb, 0, -1 do
    local u = i / nb
    local h = hw * (s.broken == 1 and 0.05 or 0.1) * sin(180 * u) * (0.35 + 0.65 * u)
    inside[#inside + 1] = { mouth[i + 1][1] + h * tx, mouth[i + 1][2] + h * ty }
  end
  if s.broken == 0 then curve(mouth, true) curve(inside, false) close() fill(tone(0.16), 0.8) end
  if s.broken == 1 then
    ink.poly(mouth, false) stroke(tone(0.05), 0.9 * D.pen, 0.85, true)
  else
    curve(mouth, true) stroke(tone(0.05), 1.1 * D.pen, 0.85, true)
    if D.lod < 2 then
      -- the lip, a pale line just behind the mouth's
      local lip = {}
      for i = 0, nb do
        local u = i / nb
        local b = P.tm - 2.5 + (s.kind == "nautilus" and -9 * u ^ 2 or 3.5 * sin(180 * u))
        lip[i + 1] = pt(b, rad(b, 0) + u * (rad(b, 1) - rad(b, 0)))
      end
      swell(lip, 0.025 * hw, WHITE, 0.45)
    end
  end
  -- the center: the first whorl, or a nautilus's dark callus where it would be
  local r0 = rad(P.tmin, 1)
  if s.kind == "nautilus" then
    local r = rad(P.tm - 360, 0.04)
    ink.smooth(N.blob(0, 0, r, r * 0.9, 0.2, 9), true) fill(tone(0.1), 0.6, true)
  else
    ink.circle(0, 0, r0) fill(tone(t - 0.1), 1)
  end
  ink.pop()
  return (x1 - x0) * sc, (y1 - y0) * sc
end

-- ---------------------------------------------------------------- entry
-- Draw the shell `s` (M.shsample's table) `size` across at most in the local unit, its base
-- on the origin, from pgf's generator seeded with `seed` (as the TikZ library seeds a
-- pic's drawing). Returns its width and height.
function M.draw(s, seed, size)
  if seed < 1 or seed > 2147483646 then seed = (seed - 1) % 2147483646 + 1 end
  G = ink.pgfrng(seed)
  G.step() G.step()
  N = require("florilegium-native")
  N.use(G)
  N.fresh()
  local lift, accent = N.pen.lift, N.pen.accent
  N.pen.lift, N.pen.accent = 0, false
  local w, h = 0, 0
  if s.group == "planispiral" then w, h = planispiral(s, size) end
  N.pen.lift, N.pen.accent = lift, accent
  return w, h
end

return M
