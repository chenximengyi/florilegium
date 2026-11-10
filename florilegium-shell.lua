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

-- ---------------------------------------------------------------- bivalves
-- A valve is drawn from its outline, as the report recommends over the sweep: its beak up,
-- the valve about 1 long and `aspect` high. The outline is an ellipse and the beak above it
-- joined by the two tangents from the beak (their touching points in closed form): a beak
-- just over the ellipse is a cockle's or a clam's umbo, one well above it a scallop's fan
-- with its straight sides, one low at an end a mussel's wedge with its straight lower edge.
-- A valve grows at its edge, so a growth line is the outline shrunk toward the beak, and a
-- rib runs from the beak to the edge.
local V = {}
local function tobeak(p, t) return { V.B[1] + t * (p[1] - V.B[1]), V.B[2] + t * (p[2] - V.B[2]) } end
local function shrink(pts, t)
  local out = {}
  for i, p in ipairs(pts) do out[i] = tobeak(p, t) end
  return out
end
local function line(p, q, n)
  local out = {}
  for i = 0, n do out[i + 1] = { p[1] + (q[1] - p[1]) * i / n, p[2] + (q[2] - p[2]) * i / n } end
  return out
end
local function lengths(pts)
  local acc = { 0 }
  for i = 2, #pts do acc[i] = acc[i - 1] + sqrt((pts[i][1] - pts[i - 1][1]) ^ 2 + (pts[i][2] - pts[i - 1][2]) ^ 2) end
  return acc
end
-- the point d along the polyline (acc its lengths)
local function along(pts, acc, d)
  for i = 2, #pts do
    if acc[i] >= d or i == #pts then
      local f = max(0, min(1, (d - acc[i - 1]) / max(1e-9, acc[i] - acc[i - 1])))
      return { pts[i - 1][1] + f * (pts[i][1] - pts[i - 1][1]), pts[i - 1][2] + f * (pts[i][2] - pts[i - 1][2]) }
    end
  end
end
local function atan2(y, x) return math.atan(y, x) / RAD end
-- the point p moved d away from the beak
local function outward(p, d)
  local dx, dy = p[1] - V.B[1], p[2] - V.B[2]
  local l = max(1e-9, sqrt(dx * dx + dy * dy))
  return { p[1] + d * dx / l, p[2] + d * dy / l }
end
-- the beak, the ellipse, the touching points and the arc between them (the margin a rib
-- reaches), its light; m 1 or -1 sets which side is the front (the beak leans that way)
local function valve_shape(s, m)
  local H, kind = s.aspect, s.kind
  local a, b, bx, by = 0.5
  if kind == "mussel" then
    b = H / 2
    bx, by = -0.64 + s.beak, -0.7 * b                 -- at the front end, low: a straight lower edge
  else
    local u = kind == "scallop" and 0.2 * H or kind == "oyster" and 0.12 or kind == "clam" and 0.06 or 0.035
    local lean = kind == "scallop" and 0 or kind == "cockle" and 0.6 or 0.9
    b = (H - u) / 2
    bx, by = (s.beak - 0.5) * lean, b + u
  end
  bx = bx * m
  V.B, V.a, V.b, V.H = { bx, by }, a, b, max(H, 2 * b)
  local uu, vv = bx / a, by / b
  local ph, de = atan2(vv, uu), math.acos(1 / sqrt(uu * uu + vv * vv)) / RAD
  local t1, t2 = ph + de, ph - de + 360
  local n = ceil((t2 - t1) / 4)
  local arc, L = {}, {}
  -- an oyster's edge is lumpy and ragged
  local p1, p2, p3, p4 = range(0, 360), range(0, 360), range(0, 360), range(0, 360)
  for i = 0, n do
    local th = t1 + (t2 - t1) * i / n
    local x, y = a * cos(th), b * sin(th)
    if kind == "oyster" then
      local k = 1 + 0.06 * sin(3 * th + p1) + 0.04 * sin(5 * th + p2) + 0.02 * sin(11 * th + p3) + 0.012 * sin(23 * th + p4)
      x, y = x * k, y * k
    end
    arc[i + 1] = { x, y }
    L[i + 1] = cos(atan2(sin(th) / b, cos(th) / a) - 135)
  end
  V.arc, V.L, V.T1, V.T2 = arc, L, arc[1], arc[#arc]
  V.round = kind ~= "scallop" and kind ~= "mussel"   -- an umbo, not a point
end
-- the outline from the beak round the margin and back, as points for `curve`
local function valve_outline(arc)
  local k = V.round and 2 or 6
  local pts = line(V.B, arc[1], k)
  for i = 2, #arc - 1 do pts[#pts + 1] = arc[i] end
  for _, p in ipairs(line(arc[#arc], V.B, k)) do pts[#pts + 1] = p end
  return pts
end
-- a point at the beak (a scallop's, a mussel's), or an umbo rounded through it
local function outlinepath(pts)
  if V.round then ink.smooth(slice(pts, 1, #pts - 1), true) else curve(pts, true) close() end
end
-- a scallop's ears: flat wings on the straight hinge either side of the beak, the front one
-- the larger when they are unequal, with the notch for the byssus under it
local function ears(s, m)
  local B, H = V.B, V.H
  local front, back = s.ears == "unequal" and 0.3 or 0.25, s.ears == "unequal" and 0.2 or 0.25
  local out = {}
  for side = -1, 1, 2 do
    local e = (side == -m) and front or back
    local T = side < 0 and V.T1 or V.T2
    if (T[1] - B[1]) * side < 0 then T = side < 0 and V.T2 or V.T1 end
    -- a wing: the hinge out to its end, the outer edge down and in a little, the lower edge
    -- sloping into the valve's side (where a front ear has the notch)
    local f = min(0.9, 0.17 * H / max(1e-6, B[2] - T[2]))
    local Q = { B[1] + f * (T[1] - B[1]), B[2] + f * (T[2] - B[2]) }
    local pts = { { B[1], B[2] }, { B[1] + side * e, B[2] + 0.01 * H }, { B[1] + side * e * 0.9, B[2] - 0.1 * H } }
    if s.ears == "unequal" and side == -m then
      pts[#pts + 1] = { B[1] + side * e * 0.62, B[2] - 0.075 * H }
      pts[#pts + 1] = { B[1] + side * e * 0.5, B[2] - 0.11 * H }
    end
    pts[#pts + 1] = Q
    out[#out + 1] = { pts = pts, e = e, side = side }
  end
  return out
end
local function bivalve(s, size)
  local m = chance(0.5) and 1 or -1
  valve_shape(s, m)
  local arc = V.arc
  local H = V.H
  local ribbed = s.ribs > 0
  -- ribs: where they meet the margin, evenly along it; the margin scalloped by them
  local acc = lengths(arc)
  local total = acc[#acc]
  local gap = ribbed and total / s.ribs or 0
  local marc = arc
  if ribbed then
    marc = {}
    for i, p in ipairs(arc) do
      local c = cos(360 * (acc[i] - 0.5 * gap) / gap)
      marc[i] = outward(p, (s.kind == "scallop" and 0.1 or 0.08) * gap * c)
    end
  end
  local outline = valve_outline(marc)
  local wings = s.kind == "scallop" and ears(s, m) or {}
  -- the frame: the valve `size` across at most, its base on the origin
  local x0, x1, y0, y1 = 1e9, -1e9, 1e9, -1e9
  local function box(p) x0, x1, y0, y1 = min(x0, p[1]), max(x1, p[1]), min(y0, p[2]), max(y1, p[2]) end
  for _, p in ipairs(outline) do box(p) end
  for _, w in ipairs(wings) do for _, p in ipairs(w.pts) do box(p) end end
  local sc = size / max(x1 - x0, y1 - y0)
  local unit = ink.unit()
  ink.push()
  ink.translate(-(x0 + x1) / 2 * sc, -y0 * sc)
  ink.scale(sc)
  D.cm = sc * unit
  local across_cm = size * unit
  D.lod = across_cm < K(0.5) and 2 or across_cm < K(1.2) and 1 or 0
  D.pen = max(0.3, min(0.85, 0.028 * across_cm * 28.3465))
  local inside = s.view == "inside"
  local t = s.tone - 0.04
  if s.ground == "pale" then t = min(0.72, t + 0.25) elseif s.ground == "dark" then t = t - 0.12 end
  if inside then t = min(0.8, t + 0.26) end
  D.t = t
  local spacing_cm = gap * D.cm
  local showribs = ribbed and D.lod < 2 and spacing_cm > K(0.05)
  -- the ears, behind the valve
  for _, w in ipairs(wings) do
    ink.poly(w.pts, true) fill(tone(t + sym(0.02)), 1)
    if D.lod < 2 then
      ink.poly(w.pts, true) ink.clip()
      for k = 1, 2 do
        local y = V.B[2] - 0.045 * H * k
        moveto(V.B[1], y) lineto(V.B[1] + w.side * w.e * 1.1, y) stroke(tone(0.08), 0.3 * D.pen, 0.28, true)
      end
      if D.lod == 0 then
        for k = 1, 4 do
          local x = V.B[1] + w.side * w.e * k / 4.5
          moveto(V.B[1], V.B[2]) lineto(x, V.B[2] - 0.14 * H) stroke(tone(0.1), 0.3 * D.pen, 0.25, true)
        end
      end
      ink.unclip()
    end
    ink.poly(w.pts, true) stroke(tone(0.05), 0.8 * D.pen, 0.85, true)
  end
  -- the valve: its wash, then in its clip the light, the grain, the pattern, the ribs or
  -- ridges, the growth lines; inside up, the pale nacre or porcelain, the rim, the scars
  local nacre = inside and (s.kind == "oyster" or s.kind == "mussel")
  outlinepath(outline) fill(tone(t), 1)
  outlinepath(outline) ink.clip()
  local n = #marc
  local C = { 0, 0 }
  if s.kind == "oyster" then
    -- layers stacked toward the beak, each edge ragged
    local layers = s.ridges
    for j = 1, layers do
      local tj = 1 - 0.62 * j / (layers + 1)
      local pts = {}
      for i, p in ipairs(shrink(marc, tj)) do pts[i] = { p[1] + sym(0.012 * H), p[2] + sym(0.012 * H) } end
      local o = valve_outline(pts)
      outlinepath(o) fill(tone(t + (j % 2 == 0 and 0.05 or -0.03)), 0.5)
      if D.lod < 2 then curve(pts, true) stroke(tone(0.08), 0.4 * D.pen, 0.5, true) end
    end
  end
  if nacre then
    N.pen.accent = true
    outlinepath(valve_outline(shrink(marc, 0.86))) fill(tone(t + 0.1), 0.6)
    N.pen.accent = false
  end
  if D.lod < 2 then
    -- the dome: shadow along the margin toward the lower right (inside: the upper left, the
    -- hollow's far wall), light on the upper left toward the beak (inside: the lower right)
    local dark = inside and function(i) return V.L[i] > K(0.2) end or function(i) return V.L[i] < K(-0.2) end
    local b0, b1 = run(n, dark)
    if b0 and b1 - b0 >= 3 then
      local w = H * (inside and 0.14 or 0.08 + 0.18 * s.inflation)
      N.streak(slice(marc, b0, b1), 0.4 * w, w, tone(0.08), inside and 0.28 or 0.18 + 0.3 * s.inflation)
    end
    -- where the margin faces the light most (inside: least), toward the beak
    local li = 1
    for i = 2, n do if (inside and V.L[i] < V.L[li]) or (not inside and V.L[i] > V.L[li]) then li = i end end
    local lit = arc[li]
    local hl = {}
    for i = 0, 4 do hl[i + 1] = tobeak(lit, 0.18 + 0.5 * i / 4) end
    swell(hl, 0.1 * H, WHITE, inside and 0.35 or 0.42)
    if inside then
      local deep = {}
      for i = 0, 3 do deep[i + 1] = tobeak(C, 0.05 + 0.4 * i / 3) end
      swell(deep, 0.1 * H, tone(0.1), 0.14)
    end
    if D.lod == 0 then
      N.mottle(x0, y0, x1, y1, 5, 0.12 * H, t - 0.14, t + 0.18, 4)
    end
    -- the pattern, outside
    local ct = s.contrast
    if not inside and s.pattern ~= "none" then
      if s.pattern == "bands" then
        local nb = floor(range(2, 4.99))
        for j = 1, nb do
          local ta = 0.3 + 0.65 * (j - 0.5) / nb
          local tb = ta + range(0.04, 0.09)
          curve(shrink(marc, min(1, tb)), true) curve(reversed(shrink(marc, ta)), false) close()
          fill(tone(t - 0.22), 0.3 + 0.35 * ct)
        end
      elseif s.pattern == "rays" then
        local nr = floor(range(3, 6.99))
        for j = 1, nr do
          local d0 = total * (j - range(0.75, 0.95)) / nr
          local d1 = d0 + total * range(0.05, 0.1)
          local pts = { V.B }
          for i = 0, 4 do pts[#pts + 1] = along(marc, acc, d0 + (d1 - d0) * i / 4) end
          ink.poly(pts, true) fill(tone(t - 0.2), 0.2 + 0.3 * ct, true)
        end
      elseif s.pattern == "zigzags" then
        for j = 1, 4 do
          local tj = 0.35 + 0.6 * j / 4.5
          local z = {}
          for i = 1, n, 2 do z[#z + 1] = tobeak(marc[i], tj + ((i // 2) % 2 == 0 and 0.035 or -0.035)) end
          ink.poly(z, false) stroke(tone(t - 0.26), 0.6 * D.pen, 0.3 + 0.4 * ct, true)
        end
      else
        for _ = 1, floor(range(14, 30)) do
          local p = tobeak(along(marc, acc, range(0, total)), range(0.3, 0.95))
          local r = H * range(0.018, 0.035)
          ink.smooth(N.blob(p[1], p[2], r, r * 0.8, 0.25, 7), true) fill(tone(t - 0.24), 0.35 + 0.4 * ct, true)
        end
      end
    end
    -- ribs: a groove between each two, from the beak to a trough of the margin, a light crest
    -- along each; inside, the grooves show faintly
    if showribs then
      for j = 1, s.ribs do
        local p = along(arc, acc, (j - 0.5) * gap)
        if j < s.ribs then
          local q = outward(along(arc, acc, j * gap), -(s.kind == "scallop" and 0.1 or 0.08) * gap)
          local g = { tobeak(q, 0.06), tobeak(q, 0.37), tobeak(q, 0.68), q }
          taperpts(g, 0.02 * gap, 0.34 * gap, tone(t - 0.2), inside and 0.15 or 0.36)
        end
        if D.lod == 0 and not inside then
          local crest = {}
          for i = 0, 4 do crest[i + 1] = tobeak(p, 0.15 + 0.8 * i / 4) end
          swell(crest, 0.16 * gap, WHITE, 0.32)
        end
      end
    end
    -- concentric ridges (a clam's): a dark line with a light one just past it, closer
    -- together toward the margin; growth lines everywhere else
    if s.sculpture == "ridges" then
      for j = 1, s.ridges do
        local tj = 0.22 + 0.76 * (j / (s.ridges + 0.6)) ^ 0.8
        curve(shrink(marc, tj), true) stroke(tone(t - 0.2), 0.45 * D.pen, 0.42, true)
        if D.lod == 0 then curve(shrink(marc, tj + 0.012), true) stroke(WHITE, 0.4 * D.pen, 0.4) end
      end
    elseif D.lod == 0 and s.kind ~= "oyster" then
      local light = t < K(0.32)                       -- on a dark shell the lines are paler
      for _, tj in ipairs({ 0.94, 0.87, 0.78, 0.66 }) do
        curve(shrink(marc, tj + sym(0.015)), true)
        if light then stroke(WHITE, 0.3 * D.pen, 0.22) else stroke(tone(t - 0.15), 0.3 * D.pen, 0.25, true) end
      end
    end
    if inside then
      -- the rim, the pallial line, the muscle scars, the hinge
      N.streak(marc, 0.03 * H, 0.03 * H, tone(t - 0.12), 0.45)
      if s.kind ~= "scallop" and s.kind ~= "oyster" then
        curve(shrink(marc, 0.8), true) stroke(tone(0.1), 0.45 * D.pen, 0.35, true)
      end
      local scars = (s.kind == "scallop" or s.kind == "oyster") and { { 0.12 * m, -0.05, 0.11 } }
        or s.kind == "mussel" and { { 0.22 * m, 0.04 * H, 0.1 }, { -0.38 * m, -0.1 * H, 0.04 } }
        or { { -0.3 * m, 0.25 * H, 0.07 }, { 0.3 * m, 0.25 * H, 0.08 } }
      for _, c in ipairs(scars) do
        local r = 0.8 * c[3] * H
        ink.smooth(N.blob(c[1], c[2], r, r * 0.75, 0.25, 7), true) fill(tone(t - 0.16), 0.26, true)
      end
      if D.lod == 0 and s.kind ~= "oyster" then
        for k = -2, 2 do
          if k ~= 0 then
            local p = tobeak(k < 0 and V.T1 or V.T2, 0.06 * abs(k) + 0.03)
            local q = tobeak(p, 0.82)
            moveto(p[1], p[2] - 0.012 * H) lineto(q[1], q[2] - 0.03 * H) stroke(tone(0.08), 0.6 * D.pen, 0.55, true)
          end
        end
      end
      if nacre and D.lod == 0 then
        N.pen.accent = true
        local g = {}
        for i = 0, 4 do g[i + 1] = tobeak(along(arc, acc, total * 0.6), 0.3 + 0.4 * i / 4) end
        swell(g, 0.06 * H, WHITE, 0.5)
        N.pen.accent = false
      end
    end
  end
  ink.unclip()
  -- the outline, and the beak's tip
  outlinepath(outline) stroke(tone(0.05), D.pen, 0.85, true)
  if D.lod < 2 and s.kind ~= "mussel" then
    local b = V.B
    local r = 0.035 * H
    moveto(b[1] - m * r, b[2] - 0.6 * r) curveto(b[1] - m * 0.3 * r, b[2] + 0.4 * r, b[1] + m * 0.5 * r, b[2] + 0.3 * r, b[1], b[2])
    stroke(tone(0.05), 0.7 * D.pen, 0.7, true)
  end
  ink.pop()
  return (x1 - x0) * sc, (y1 - y0) * sc
end

-- ---------------------------------------------------------------- gastropods
-- A sea snail's empty shell seen from the side, as plates show it: the axis upright, the
-- apex up, the mouth facing us (on the right of a dextral shell; seen from the back, the
-- whole drawing mirrored and no mouth). The ring of growth angle th sits y0 l from the axis
-- at height -x0 l (x0 = T y0, l = W^(th/360)), at polar angle a = -th about the axis, the
-- front half where a runs 0..180. Each whorl shows the front half of its turn: the sweep of
-- its ring from the left silhouette to the right, bounded by the ring's top and bottom and,
-- at each end, the ring's outer half. The whorls are painted oldest first, each one's top
-- edge the suture on the one above. At the mouth the ring lies in the picture plane, so the
-- aperture is seen face on: the snail's tube with its rings seen from above (the visitor's,
-- florilegium-native.lua's gs*) would hide it.
local GA = {}
-- the ring's point at psi (0 away from the axis, 90 up): a circle S tall, its top flattened
-- to a shoulder, a topshell's bottom flattened to its base
local function gc(psi)
  local S = GA.S
  local x, y = cos(psi), S * sin(psi)
  if GA.shoulder == "angular" and y > 0.55 * S then
    y = 0.55 * S + 0.3 * (y - 0.55 * S) x = x * 1.06
  elseif GA.shoulder == "rounded" and y > 0.7 * S then
    y = 0.7 * S + 0.6 * (y - 0.7 * S)
  end
  if GA.flatbase and y < -0.45 * S then y = -0.45 * S + 0.12 * (y + 0.45 * S) end
  if GA.egg and psi % 360 > 180 then
    -- a whelk's ring is an egg, drawn down to a point where it runs into the canal
    local k = -sin(psi)
    y, x = y * (1 + 0.35 * k), x * (1 - 0.18 * k)
  end
  return x, y
end
-- the page point of the ring at growth angle th, at its point psi, and the ring's center
local function gp(th, psi)
  local lam = GA.W ^ (th / 360)
  local gx, gy = gc(psi)
  return { GA.hx * (GA.y0 + gx) * lam * cos(GA.ph - th), (gy - GA.x0) * lam }
end
local function gcenter(th)
  local lam = GA.W ^ (th / 360)
  return { GA.hx * GA.y0 * lam * cos(GA.ph - th), -GA.x0 * lam }
end
-- the growth angle where whorl W's ring lies at polar angle a
local function gth(W, a) return W.tb + W.ab - a end
-- whorl j's front half (0 the body whorl): its top and bottom edges from left to right,
-- its caps (the right one from top to bottom, the left from bottom to top), its height
local function gwhorl(j)
  -- the shell is turned GA.ph about its axis, so the mouth lies a little toward the front:
  -- the body whorl's front half runs from the left silhouette to the mouth, the others' from
  -- the left silhouette to the right one
  local tb = j == 0 and 0 or GA.ph - 360 * j
  local ta = GA.ph - 180 - 360 * j
  local W = { j = j, ta = ta, tb = tb, ab = j == 0 and GA.ph or 0, top = {}, bot = {}, rcap = {}, lcap = {} }
  for i = 0, 18 do
    local th = ta + (tb - ta) * i / 18           -- the body whorl's ends at its mouth
    W.top[i + 1], W.bot[i + 1] = gp(th, 90), gp(th, -90)
  end
  for i = 0, 12 do
    W.rcap[i + 1] = gp(tb, 90 - 180 * i / 12)
    W.lcap[i + 1] = gp(ta, -90 + 180 * i / 12)
  end
  W.h = W.top[10][2] - W.bot[10][2]                -- across the whorl at its front
  return W
end
local function gpath(W)
  curve(W.rcap, true) curve(reversed(W.bot), false) curve(W.lcap, false) curve(W.top, false) close()
end
-- its outline but for the bottom edge, which a canal hides: the base runs into the canal
local function gline_nobase(W)
  curve(slice(W.lcap, 3, #W.lcap), true) curve(W.top, false) curve(W.rcap, false)
end
-- a line across the whorl's front half at growth angle th (a rib's, from top to bottom), or
-- along it at psi (a cord's, from left to right)
local function gacross(th) return { gp(th, 80), gp(th, 28), gp(th, -28), gp(th, -80) } end
local function galong(W, psi, a0, a1)
  a0, a1 = max(a0, W.ab), max(a1, W.ab)
  local pts = {}
  for i = 0, 12 do pts[i + 1] = gp(gth(W, a0 + (a1 - a0) * i / 12), psi) end
  return pts
end
local RIBBY = { ribs = true, cancellate = true, nodes = true }
local function gsurface(s, W)
  local h = W.h
  local t = D.t
  -- the shading: under the suture, the underside, the side away from the light, and a
  -- light on the side toward it, a little above the middle
  N.streak(W.top, 0.14 * h, 0.2 * h, tone(0.08), 0.28)
  N.streak(reversed(W.bot), 0.18 * h, 0.3 * h, tone(0.08), 0.22)
  local darkcap = GA.hx > 0 and W.rcap or W.lcap
  N.streak(darkcap, 0.25 * h, 0.25 * h, tone(0.08), 0.24)
  local lit = GA.hx > 0 and galong(W, 25, 165, 100) or galong(W, 25, 15, 80)
  swell(lit, 0.22 * h, WHITE, W.j == 0 and 0.45 or 0.35)
  if D.lod == 0 and h * D.cm > K(0.25) then
    local x0, x1, y0, y1 = 1e9, -1e9, 1e9, -1e9
    for _, p in ipairs(W.top) do x0, x1, y1 = min(x0, p[1]), max(x1, p[1]), max(y1, p[2]) end
    for _, p in ipairs(W.bot) do y0 = min(y0, p[2]) end
    N.mottle(x0, y0, x1, y1, 3, 0.25 * h, t - 0.14, t + 0.18, 3)
  end
  -- the pattern
  local ct = s.contrast
  if s.pattern == "bands" then
    for b = 1, 2 do
      local p0 = 50 - 70 * b / 2
      curve(galong(W, p0, 0, 180), true) curve(reversed(galong(W, p0 - 16, 0, 180)), false) close()
      fill(tone(t - 0.22), 0.25 + 0.35 * ct)
    end
  elseif s.pattern == "flammules" then
    local nf = 7
    for k = 1, nf do
      local a = 180 * (k - range(0.3, 0.7)) / nf
      local pts = {}
      for i = 0, 4 do pts[i + 1] = gp(gth(W, max(W.ab, a)) - sym(6), 80 - 160 * i / 4) end
      N.streak(pts, 0.04 * h, 0.12 * h * range(0.7, 1.3), tone(t - 0.26), 0.25 + 0.4 * ct)
    end
  elseif s.pattern == "dots" then
    for _ = 1, floor(range(6, 12)) do
      local c = gp(gth(W, range(max(15, W.ab), 165)), range(-60, 60))
      local r = h * range(0.04, 0.07)
      ink.smooth(N.blob(c[1], c[2], r, r * 0.8, 0.25, 7), true) fill(tone(t - 0.26), 0.35 + 0.4 * ct, true)
    end
  end
  -- the sculpture: axial ribs across the whorl where they stand 0.5 mm apart at its front,
  -- spiral cords along it, knobs on the shoulder
  local lam = GA.W ^ (W.tb / 360)
  if RIBBY[s.sculpture] and s.ribs > 0 then
    local half = s.ribs / 2
    local gap = GA.y0 * lam * (180 / half) * RAD
    if gap * D.cm > K(0.05) then
      local wide = s.sculpture == "cancellate" and 0.14 or 0.22
      for k = 1, floor(half + 0.5) do
        local a = max(W.ab, 180 * (k - 0.5) / half)
        local th = gth(W, a)
        local f = max(0.15, sin(a))                    -- foreshortened toward the silhouettes
        if s.sculpture ~= "nodes" then
          swell(gacross(th), wide * gap * f, tone(t - 0.2), 0.38)
          if D.lod == 0 then swell(gacross(th + GA.hx * 4), 0.4 * wide * gap * f, WHITE, 0.35) end
        else
          local c = gp(th, 62)
          local r = 0.3 * gap * f
          ink.smooth(N.blob(c[1], c[2], r, 0.8 * r, 0.2, 7), true) fill(tone(t - 0.2), 0.45, true)
          ink.circle(c[1] - 0.3 * r, c[2] + 0.3 * r, 0.3 * r) fill(WHITE, 0.4)
        end
      end
    end
  end
  if (s.sculpture == "cords" or s.sculpture == "cancellate") and s.cords > 0 and h * D.cm > K(0.08) then
    for c = 1, s.cords do
      local psi = 75 - 150 * c / (s.cords + 1)
      curve(galong(W, psi, 3, 177), true) stroke(tone(t - 0.2), 0.45 * D.pen, 0.42, true)
      if D.lod == 0 then curve(galong(W, psi + 5, 3, 177), true) stroke(WHITE, 0.35 * D.pen, 0.35) end
    end
  end
end
-- the canal: the body whorl's base drawn down under the mouth to a tip bent a little
-- toward the axis, its left edge from the base, its right from the mouth's lower outer side
local function gcanal_len(s) return (s.canal == "long" and 1.5 or 0.6) * GA.S end
local function gcanal_tip(s)
  local B = gp(0, -90)
  return { B[1] - GA.hx * 0.3, B[2] - gcanal_len(s) }
end
local function gcanal(s, body)
  local tip = gcanal_tip(s)
  local A = body.lcap[3]                             -- low on the left side, before it turns in
  local O = gp(0, -40)                               -- the mouth's lower outer side
  local mid = { 0.45 * A[1] + 0.55 * tip[1] + GA.hx * 0.1, 0.5 * (A[2] + tip[2]) }
  local mid2 = { 0.5 * (O[1] + tip[1]) + GA.hx * 0.05, 0.45 * O[2] + 0.55 * tip[2] }
  local function path() curve({ A, mid, tip }, true) curve({ tip, mid2, O }, false) close() end
  path() fill(tone(D.t + sym(0.02)), 1)
  if D.lod < 2 then
    path() ink.clip()
    N.streak({ O, mid2, tip }, 0.35, 0.05, tone(0.08), 0.3)
    swell({ A, mid, tip }, 0.12, WHITE, 0.3)
    ink.unclip()
  end
  path() stroke(tone(0.05), 0.9 * D.pen, 0.85, true)
end
-- the canal's open channel, on from the mouth: porcelain, its left edge the columella's
local function gchannel(s)
  local B, tip = gp(0, -90), gcanal_tip(s)
  local c = { B, { 0.5 * (B[1] + tip[1]) + GA.hx * 0.06, 0.5 * (B[2] + tip[2]) }, { tip[1] + GA.hx * 0.03, tip[2] + 0.12 * gcanal_len(s) } }
  N.streak(c, 0.32, 0.04, tone(min(0.82, D.t + 0.3)), 1)
  local edge = { { B[1] - GA.hx * 0.12, B[2] + 0.05 }, { c[2][1] - GA.hx * 0.08, c[2][2] }, c[3] }
  curve(edge, true) stroke(tone(0.08), 0.6 * D.pen, 0.7, true)
end
-- the mouth, face on: the dark inside, the pale callus along the columella with its folds,
-- the lip thickened or flared
local function gmouth(s)
  local ring = {}
  for i = 0, 23 do ring[i + 1] = gp(0, 15 * i) end
  local c = gcenter(0)
  if s.lip == "flared" then
    local flange = {}
    for i = -5, 5 do
      local p = gp(0, 14 * i)
      flange[#flange + 1] = { c[1] + 1.2 * (p[1] - c[1]), c[2] + 1.06 * (p[2] - c[2]) }
    end
    local inner = {}
    for i = 5, -5, -1 do inner[#inner + 1] = gp(0, 14 * i) end
    curve(flange, true) curve(inner, false) close() fill(tone(D.t + 0.06), 1)
    curve(flange, true) stroke(tone(0.05), 0.8 * D.pen, 0.85, true)
  end
  -- the inside is porcelain, pale, going dark where it turns away into the shell: toward the
  -- columella and the top
  ink.smooth(ring, true) fill(tone(min(0.82, D.t + 0.3)), 1)
  if D.lod < 2 then
    local deep, glow = {}, {}
    for i = 0, 6 do
      local p = gp(0, 95 + 110 * i / 6)
      deep[i + 1] = { c[1] + 0.72 * (p[1] - c[1]), c[2] + 0.75 * (p[2] - c[2]) }
      local q = gp(0, -60 + 120 * i / 6)
      glow[i + 1] = { c[1] + 0.72 * (q[1] - c[1]), c[2] + 0.78 * (q[2] - c[2]) }
    end
    ink.smooth(ring, true) ink.clip()
    swell(deep, 0.5, tone(0.12), 0.45)
    swell(deep, 0.25, tone(0.08), 0.35)
    swell(glow, 0.3, WHITE, 0.45)
    ink.unclip()
    local col = {}
    for i = 0, 6 do
      local p = gp(0, 125 + 110 * i / 6)
      col[i + 1] = { c[1] + 0.82 * (p[1] - c[1]), c[2] + 0.88 * (p[2] - c[2]) }
    end
    swell(col, 0.22, WHITE, 0.35)
    if D.lod == 0 then
      -- columella folds: short ridges slanting down into the mouth
      for k = 1, s.folds do
        local p = gp(0, 200 + 14 * (k - (s.folds + 1) / 2))
        local q = { c[1] + 0.82 * (p[1] - c[1]), p[2] - 0.12 }
        moveto(p[1], p[2]) lineto(q[1], q[2]) stroke(WHITE, 0.6 * D.pen, 0.45)
      end
    end
    if s.lip == "thick" then
      local lip = {}
      for i = -5, 5 do
        local p = gp(0, 14 * i)
        lip[#lip + 1] = { c[1] + 0.9 * (p[1] - c[1]), c[2] + 0.94 * (p[2] - c[2]) }
      end
      swell(lip, 0.16, WHITE, 0.55)
    end
  end
  ink.smooth(ring, true) stroke(tone(0.05), D.pen, 0.85, true)
end
local function gastropod(s, size)
  GA.W, GA.S, GA.shoulder = s.expansion, s.aperture, s.shoulder
  GA.y0 = (1 + s.umbilicus) / (1 - s.umbilicus)
  GA.x0 = s.spire * GA.y0
  GA.flatbase = s.kind == "topshell"
  GA.egg = s.kind == "whelk"
  local back = s.view == "back"
  GA.hx = (s.hand == "sinistral" and -1 or 1) * (back and -1 or 1)
  GA.ph = range(18, 30)
  -- the whorls, as many as show: down to a ring 0.3 mm across, or the shell's own count
  local whorls = {}
  for j = 0, ceil(s.whorls) - 1 do whorls[j + 1] = gwhorl(j) end
  local x0, x1, y0, y1 = 1e9, -1e9, 1e9, -1e9
  local function box(p) x0, x1, y0, y1 = min(x0, p[1]), max(x1, p[1]), min(y0, p[2]), max(y1, p[2]) end
  for _, W in ipairs(whorls) do
    for _, part in ipairs({ W.top, W.bot, W.rcap, W.lcap }) do for _, p in ipairs(part) do box(p) end end
  end
  if s.canal ~= "none" then box(gcanal_tip(s)) end
  if s.lip == "flared" then local c = gcenter(0) box({ c[1] + GA.hx * 1.2 * 1.06, c[2] }) end
  box({ 0, 0 })                                     -- the apex
  local sc = size / max(x1 - x0, y1 - y0)
  local unit = ink.unit()
  ink.push()
  ink.translate(-(x0 + x1) / 2 * sc, -y0 * sc)
  ink.scale(sc)
  D.cm = sc * unit
  local across_cm = size * unit
  D.lod = across_cm < K(0.5) and 2 or across_cm < K(1.2) and 1 or 0
  D.pen = max(0.3, min(0.85, 0.028 * across_cm * 28.3465))
  local t = s.tone - 0.04
  if s.ground == "pale" then t = min(0.72, t + 0.25) elseif s.ground == "dark" then t = t - 0.12 end
  D.t = t
  if s.canal ~= "none" then gcanal(s, whorls[1]) end
  for j = #whorls, 1, -1 do
    local W = whorls[j]
    if W.h * D.cm > K(0.02) or j == 1 then
      N.pen.accent = s.preservation == "nacre" and j > #whorls - 3     -- worn at the apex
      gpath(W) fill(tone(t + sym(0.03)), 1)
      if D.lod < 2 and W.h * D.cm > K(0.05) then
        gpath(W) ink.clip()
        gsurface(s, W)
        ink.unclip()
      end
      N.pen.accent = false
      if j == 1 and s.canal ~= "none" then gline_nobase(W) else gpath(W) end
      stroke(tone(0.05), (j == 1 and 1 or 0.75) * D.pen, 0.85, true)
    end
  end
  -- the apex's tip, where the whorls are too small to draw
  ink.circle(0, gp(-360 * #whorls, 90)[2], 0.02 / max(1e-6, D.cm)) fill(tone(0.08), 0.8)
  if not back then
    gmouth(s)
    if s.canal ~= "none" then gchannel(s) end
  end
  ink.pop()
  return (x1 - x0) * sc, (y1 - y0) * sc
end

-- a cowrie: a glossy egg 1 long and `aspect` wide, lying along x; from above its dome, its
-- spots and the pale line where the mantle met; from beneath its paler base and the long
-- toothed slit
local function cowrie(s, size)
  local A = s.aspect
  local egg = {}
  for i = 0, 35 do
    local u = 10 * i
    egg[i + 1] = { 0.5 * cos(u), 0.5 * A * sin(u) * (1 + 0.08 * cos(u)) }
  end
  local sc = size / 1
  local unit = ink.unit()
  ink.push()
  ink.translate(0, 0.5 * A * 1.08 * sc)
  ink.scale(sc)
  D.cm = sc * unit
  local across_cm = size * unit
  D.lod = across_cm < K(0.5) and 2 or across_cm < K(1.2) and 1 or 0
  D.pen = max(0.3, min(0.85, 0.028 * across_cm * 28.3465))
  local t = s.tone - 0.04
  if s.ground == "pale" then t = min(0.72, t + 0.25) elseif s.ground == "dark" then t = t - 0.12 end
  local under = s.view == "mouth"
  if under then t = min(0.78, t + 0.22) end
  D.t = t
  ink.smooth(egg, true) fill(tone(t), 1)
  if D.lod < 2 then
    ink.smooth(egg, true) ink.clip()
    N.streak(slice(egg, 21, 33), 0.04 * A, 0.12 * A, tone(0.08), 0.3)     -- the lower edge's shadow
    if under then
      -- the base: the back's color round its edge, the slit with its teeth
      N.streak(egg, 0.1 * A, 0.1 * A, tone(t - 0.3), 0.35)
      local slit = {}
      for i = 0, 8 do
        local x = -0.46 + 0.92 * i / 8
        slit[i + 1] = { x, 0.04 * A * sin(180 * i / 8) - 0.02 * A }
      end
      swell(slit, 0.06 * A, tone(0.08), 0.9)
      if D.lod == 0 then
        for k = 1, 16 do
          local x = -0.4 + 0.8 * (k - 0.5) / 16
          local y = 0.04 * A * sin(180 * (x + 0.46) / 0.92) - 0.02 * A
          for side = -1, 1, 2 do
            moveto(x, y + side * 0.035 * A) lineto(x, y + side * 0.11 * A) stroke(tone(t - 0.25), 0.5 * D.pen, 0.55, true)
          end
        end
      end
    else
      if s.pattern == "dots" then
        for _ = 1, floor(range(18, 34)) do
          local x, y = range(-0.4, 0.4), range(-0.38, 0.38) * A
          local r = A * range(0.025, 0.06)
          ink.smooth(N.blob(x, y, r, 0.85 * r, 0.25, 7), true) fill(tone(t - 0.28), 0.35 + 0.45 * s.contrast, true)
        end
      elseif s.pattern == "bands" then
        for b = 1, 3 do
          local x = -0.3 + 0.3 * (b - 1)
          local stripe = { { x, -0.6 * A }, { x + 0.02, 0 }, { x, 0.6 * A } }
          N.streak(stripe, 0.1, 0.1, tone(t - 0.24), 0.25 + 0.35 * s.contrast)
        end
      end
      -- the mantle line, and the gloss: a long light along the upper left of the dome
      local ml = {}
      for i = 0, 6 do ml[i + 1] = { -0.42 + 0.84 * i / 6, 0.1 * A + 0.015 * sin(360 * i / 6) } end
      if D.lod == 0 then ink.poly(ml, false) stroke(WHITE, 0.6 * D.pen, 0.5) end
      local gl = {}
      for i = 0, 4 do gl[i + 1] = { -0.3 + 0.45 * i / 4, 0.22 * A + 0.03 * A * sin(180 * i / 4) } end
      swell(gl, 0.12 * A, WHITE, 0.6)
    end
    ink.unclip()
  end
  ink.smooth(egg, true) stroke(tone(0.05), D.pen, 0.85, true)
  -- the canals at either end
  for side = -1, 1, 2 do
    moveto(side * 0.5, 0.03 * A) lineto(side * 0.45, 0) lineto(side * 0.5, -0.03 * A)
    stroke(tone(0.05), 0.7 * D.pen, 0.8, true)
  end
  ink.pop()
  return size, A * 1.08 * size
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
  local w, h
  if s.group == "planispiral" then w, h = planispiral(s, size)
  elseif s.group == "bivalve" then w, h = bivalve(s, size)
  elseif s.kind == "cowrie" then w, h = cowrie(s, size)
  else w, h = gastropod(s, size) end
  N.pen.lift, N.pen.accent = lift, accent
  return w, h
end

return M
