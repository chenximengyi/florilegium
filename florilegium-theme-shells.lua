-- florilegium-theme-shells.lua -- a theme for florilegium without plants: shells washed up
-- in the margin, wrack lying among them.
-- Copyright (c) 2026 Kevin Raymond. MIT License: see LICENSE or florilegium.sty.
--
-- The margin as a strip of the shore seen from above:
--   - strands of wrack (a flat strap with a midrib that forks, with paired air bladders and
--     swollen tips, as bladderwrack has) lie from a pebble in the corner up the column and
--     along the bottom, putting out branches as they go;
--   - the document's cabinet of four shells (florilegium-species.lua: M.cabinet) lies low,
--     the largest nearest the corner, so a reader sees the same collection on every page;
--   - then, largest hole first and those near the wrack first, more shells of five kinds the
--     page draws for itself, large low and small up the column and out along the bottom,
--     overlapping a little, now and then one tucked half under its neighbors;
--   - a tuft or three of fine weed, the first in copper, and grit and broken shell along the
--     bottom, thinning out up the column.
-- Every shell is drawn by florilegium-shell.lua from its genome, with a soft shadow to the
-- lower right, and is kept the right way round on a mirrored page, since a whelk's coil
-- has a hand. density sets how much there is; at 0.05 one strand and a few shells.
-- Use: \usepackage[grown,theme=shells]{florilegium}.

local ink = require("florilegium-ink")
local SPC = require("florilegium-species")
local SHL = require("florilegium-shell")
require("florilegium-native")         -- what the shells are drawn with, loaded now so its version is checked
local M = {}
M.version = "2.0.1"                 -- the release; florilegium.lua checks that every file has the same

local sin, cos, sqrt, pi, floor, ceil, max, min, abs, log, exp =
  math.sin, math.cos, math.sqrt, math.pi, math.floor, math.ceil, math.max, math.min, math.abs, math.log, math.exp
local RAD = pi / 180
local tone = ink.tone
local function pgfseed(r) return 1 + floor(r.u() * 2147483645) end
local function lerp(a, b, t) return a + (b - a) * t end
local function smoothstep(a, b, x) local t = min(1, max(0, (x - a) / (b - a))) return t * t * (3 - 2 * t) end
local function clamp(v, a, b) return max(a, min(b, v)) end

-- the traits a scallop is fixed to: the fleuron and the marks beside the headings
local scallop
local function scallops()
  if not scallop then scallop = SPC.fixes("kind=scallop, view=outside, ground=pale", "shell") end
  return scallop
end

-- ---------------------------------------------------------------- wrack
-- A strap along `pts` (local cm), widths w0 at its start to w1 at its end, its edge a little
-- uneven (`wob`), with a rounded end when `tip`. The start needs no cap: it lies under the
-- strap it forks from, or on the pebble. Returns the outline.
local function strap(pts, w0, w1, tip, wob)
  local s, L = ink.arclen(pts)
  local nr = ink.normals(pts)
  local left, right = {}, {}
  for i, p in ipairs(pts) do
    local u = L > 0 and s[i] / L or 0
    local w = (w0 + (w1 - w0) * u) / 2
    if wob then w = w * (1 + 0.12 * wob(s[i] * 2.2)) end
    left[i] = { p[1] + nr[i][1] * w, p[2] + nr[i][2] * w }
    right[i] = { p[1] - nr[i][1] * w, p[2] - nr[i][2] * w }
  end
  local out = left
  if tip then
    local n, p = #pts, pts[#pts]
    local tx, ty = -nr[n][2], nr[n][1]
    local nx, ny = nr[n][1], nr[n][2]
    local rc = w1 / 2
    for a = 30, 150, 30 do
      out[#out + 1] = { p[1] + rc * (nx * cos(a * RAD) + tx * sin(a * RAD)), p[2] + rc * (ny * cos(a * RAD) + ty * sin(a * RAD)) }
    end
  end
  for i = #right, 1, -1 do out[#out + 1] = right[i] end
  return out
end

-- an ellipse's points, centered at (x, y), half-axes a along (ux, uy) and b across it
local function ellipse(x, y, ux, uy, a, b, n)
  local pts = {}
  for i = 0, n - 1 do
    local t = 2 * pi * i / n
    local p, q = a * cos(t), b * sin(t)
    pts[#pts + 1] = { x + ux * p - uy * q, y + uy * p + ux * q }
  end
  return pts
end

-- a pair of air bladders astride the midrib at point i of pts, the strap w wide; lx is the
-- light's side in local x (1, or -1 on a mirrored page)
local function bladders(rng, pts, i, w, t, lx)
  local a, b = pts[max(1, i - 1)], pts[min(#pts, i + 1)]
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local l = sqrt(dx * dx + dy * dy)
  if l < 1e-6 then return end
  local ux, uy = dx / l, dy / l
  local p = pts[i]
  local len = w * rng.range(0.8, 1.0)
  for side = -1, 1, 2 do
    local cx, cy = p[1] - uy * side * w * 0.3, p[2] + ux * side * w * 0.3
    local bw = w * rng.range(0.42, 0.5)
    ink.smooth(ellipse(cx, cy, ux, uy, len, bw, 10), true) ink.fill(tone(t + 0.24))
    ink.smooth(ellipse(cx, cy, ux, uy, len, bw, 10), true) ink.stroke(tone(t - 0.06), 0.3, 0.9)
    -- the light on the bubble, toward the upper left of the page
    ink.smooth(ellipse(cx - 0.3 * bw * lx, cy + 0.3 * bw, ux, uy, len * 0.38, bw * 0.32, 8), true) ink.fill(ink.white, 0.55)
  end
end

-- a swollen fruiting tip at the end of pts, with the pits it is speckled with
local function receptacle(rng, pts, w, t, lx)
  local n = #pts
  local a, b = pts[max(1, n - 2)], pts[n]
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local l = sqrt(dx * dx + dy * dy)
  if l < 1e-6 then return end
  local ux, uy = dx / l, dy / l
  local len, bw = w * rng.range(1.5, 2.2), w * rng.range(0.6, 0.72)
  local cx, cy = b[1] + ux * (len - w * 0.6), b[2] + uy * (len - w * 0.6)
  local out = ellipse(cx, cy, ux, uy, len, bw, 14)
  ink.smooth(out, true) ink.fill(tone(t + 0.12))
  for _ = 1, floor(rng.range(6, 11)) do
    local p, q = rng.sym(0.75) * len, rng.sym(0.6) * bw
    ink.circle(cx + ux * p - uy * q, cy + uy * p + ux * q, w * rng.range(0.05, 0.09))
  end
  ink.fill(tone(t - 0.08), 0.8)
  ink.smooth(out, true) ink.stroke(tone(t - 0.06), 0.3, 0.9)
  ink.smooth(ellipse(cx - 0.25 * bw * lx, cy + 0.25 * bw, ux, uy, len * 0.5, bw * 0.25, 8), true) ink.fill(ink.white, 0.4)
end

-- one piece of a strand: its strap, its midrib, its bladders and its fruiting tip
local function piece(rng, sg, t, lx)
  local wob = ink.fbm1(rng, 2)
  ink.smooth(strap(sg.pts, sg.w0, sg.w1, sg.tip and not sg.rec, wob), true) ink.fill(tone(t))
  -- the midrib, stopping short of a round tip
  local n = #sg.pts
  local stop = sg.tip and max(2, n - 1) or n
  if stop >= 2 then
    local mid = {}
    for i = 1, stop do mid[i] = sg.pts[i] end
    ink.smooth(mid, false) ink.stroke(tone(t + 0.3), 0.3, 0.7)
  end
  for _, i in ipairs(sg.bl or {}) do bladders(rng, sg.pts, i, lerp(sg.w0, sg.w1, (i - 1) / max(1, n - 1)), t, lx) end
  if sg.rec then receptacle(rng, sg.pts, sg.w1, t, lx) end
end

-- the pebble the wrack is fast to, and its holdfast
local function pebble(rng, r, lx)
  local out = ink.blob(rng, 0, 0, r * 1.25, r, 0.12, 11)
  ink.smooth(out, true) ink.fill(tone(0.8))
  ink.smooth(out, true) ink.clip()
  for _ = 1, 7 do
    ink.smooth(ink.blob(rng, rng.sym(r), rng.sym(0.8 * r), r * rng.range(0.15, 0.3), r * rng.range(0.1, 0.22), 0.3, 7), true)
    ink.fill(tone(rng.range(0.62, 0.78)), 0.5, true)
  end
  ink.smooth(ink.blob(rng, -0.35 * r * lx, 0.35 * r, r * 0.55, r * 0.3, 0.2, 9), true) ink.fill(ink.white, 0.45)
  ink.unclip()
  ink.smooth(out, true) ink.stroke(tone(0.35), 0.35, 0.9)
end

-- ---------------------------------------------------------------- weed and grit
-- a tuft of fine red weed, along +y from its foot, L long: an axis with branchlets on
-- alternate sides, each with its own, combed on one side at the last level
local function weed(rng, L, c, depth, w)
  local bend = rng.sym(0.25)
  local x1, y1, x2, y2, x3, y3 = bend * L * 0.4, L * 0.35, bend * L * 0.8, L * 0.7, bend * L, L
  ink.taper(0, 0, x1, y1, x2, y2, x3, y3, w, w * 0.3)
  ink.fill(c, 0.95)
  local f = ink.bezier3(0, 0, x1, y1, x2, y2, x3, y3)
  local n = depth > 0 and 5 or 4
  for k = 1, n do
    local u = (k - 0.3) / (n + 0.4)
    local px, py = f(u)
    local qx, qy = f(min(1, u + 0.02))
    local a = math.atan(qy - py, qx - px) / RAD
    local side = (depth > 0 and (k % 2 == 0 and 1 or -1)) or 1
    ink.push() ink.translate(px, py) ink.rotate(a - 90 + side * rng.range(35, 55))
    if depth > 0 then weed(rng, L * 0.5 * (1 - 0.55 * u), c, depth - 1, w * 0.6)
    else
      local l = L * 0.35 * (1 - 0.5 * u)
      ink.taper(0, 0, 0, l * 0.35, l * 0.1, l * 0.7, l * 0.15, l, w * 0.6, w * 0.15) ink.fill(c, 0.95)
    end
    ink.pop()
  end
end

-- a piece of broken shell r across: part of a ribbed fan with a jagged edge
local function fragment(rng, r, t)
  local a0, span = rng.range(0, 360), rng.range(50, 95)
  local r0 = r * rng.range(0.15, 0.4)
  local out = {}
  for k = 0, 5 do
    local a = (a0 + span * k / 5) * RAD
    local rr = r * (1 + rng.sym(0.14))
    out[#out + 1] = { rr * cos(a), rr * sin(a) }
  end
  for k = 5, 0, -2.5 do
    local a = (a0 + span * k / 5) * RAD
    local rr = r0 * (1 + rng.sym(0.3))
    out[#out + 1] = { rr * cos(a), rr * sin(a) }
  end
  ink.poly(out, true) ink.fill(tone(t))
  for k = 1, 3 do
    local a = (a0 + span * (k - 0.5 + rng.sym(0.2)) / 3) * RAD
    ink.moveto(r0 * 1.1 * cos(a), r0 * 1.1 * sin(a)) ink.lineto(r * 0.92 * cos(a), r * 0.92 * sin(a))
  end
  ink.stroke(tone(t - 0.25), 0.25, 0.8)
  ink.poly(out, true) ink.stroke(tone(0.3), 0.25, 0.9)
end

-- ---------------------------------------------------------------- the fleuron
-- the header's: a small scallop in copper, its line running on into the head rule;
-- returns where the rule starts, on the page
local function fleuron(rng, s, o)
  local sh = SPC.shsample(pgfseed(rng), "any", nil, scallops())
  local z = pgfseed(rng)
  ink.push() ink.scale(s)
  ink.push() ink.rotate(-12) ink.in_accent(function() SHL.draw(sh, z, 1.6, true) end) ink.pop()
  local c = (o and o.color) or ink.accent(0)
  ink.moveto(0.62, -0.1) ink.curveto(0.95, -0.35, 1.25, -0.05, 1.3, 0.12) ink.curveto(1.4, 0.4, 1.7, 0.3, 2.0, 0.28)
  ink.stroke(c, 0.4)
  ink.circle(-0.45, 0.62, 0.035) ink.circle(0.85, 0.55, 0.03) ink.fill(c, 0.85)
  local rx, ry = ink.to_page(2.0, 0.28)
  ink.pop()
  return rx, ry
end

-- ---------------------------------------------------------------- the page
-- Called by grow.page with the page (g) and florilegium-grow.lua. Returns { stats } (and
-- { rec, total } in the animation).
function M.page(g, grow)
  local rng = ink.rng(g.seed * 7919 + 43)
  local layout = rng.fork()
  ink.set_transform(ink.page_transform(g.mirror and g.pw))
  local D = g.density or 1
  local anim = g.anim
  if anim then ink.record(true) end
  local lx = g.mirror and -1 or 1                -- the light's side in layout x: the page's upper left
  local _, col, foot, spill = grow.regions(g, layout)
  -- the strand line along the bottom runs further than the garden's footer
  foot = { foot[1], foot[2], g.textleft + (g.textright - g.textleft) * layout.range(0.6, 0.72), foot[4] }
  local regions = { col, foot, spill, corners = true }
  local fld = grow.field(regions)
  local gx, gy, free, disc, free_at = fld.x, fld.y, fld.free, fld.disc, fld.free_at
  disc(g.colright - 0.5, g.headrule + 0.1, 0.7, 1)        -- the header's fleuron
  local cw, ch = col[3] - col[1], col[4] - col[2]
  local counts = { shell = 0, wrack = 0, weed = 0, grit = 0 }

  -- the animation: things appear in the order they are laid down
  local events, clock = {}, 0.3
  local function event(step, dur)
    local e = { t0 = clock, dur = dur or 0.4 }
    clock = clock + (step or 0.1)
    events[#events + 1] = e
    return e
  end
  local BLOOM = { 0.3, 0.55, 0.75, 0.9 }
  local function place(e, layer, x, y, fn)
    ink.layer(layer)
    if anim then
      local r0, l0 = rng.save(), layout.save()
      for k = 1, #BLOOM do
        ink.tag({ e, (k - 1) / #BLOOM, k / #BLOOM })
        ink.push() ink.translate(x, y) ink.scale(BLOOM[k]) fn() ink.pop()
        rng.load(r0) layout.load(l0)
      end
      ink.tag({ e, 1 })
    end
    ink.push() ink.translate(x, y) fn() ink.pop()
    if anim then ink.tag(nil) end
  end
  -- how far along the margin a point is: 0 in the corner where the column meets the bottom,
  -- 1 at the top of the column or the far end of the strand line
  local function reach(x, y)
    return clamp((y - col[2]) / ch + max(0, x - col[3]) / max(1, foot[3] - col[3]), 0, 1.5)
  end

  -- 1. the strands of wrack: from a pebble in the corner, up the column and along the bottom
  local NSTR = D >= 0.6 and 3 or D >= 0.25 and 2 or 1
  local STRAND = D >= 0.2
  local root = { col[1] + layout.range(0.7, 1.0), col[2] + 0.35 }
  local strands = {}
  -- a strand's points, kept in the column (or the band) and clear of the paper's edge
  local function keep(p, r)
    p[1] = clamp(p[1], r[1] + 0.25, r[3] - 0.25)
    p[2] = clamp(p[2], r[2] + 0.15, r[4] - 0.2)
    return p
  end
  -- a branch from point p of a strand, along angle a (degrees), L long, w wide where it
  -- leaves: a gentle curve that turns by `turn`, forking near its end now and then into two
  -- tips; nil where there is no room for it
  local function branch(p, a, L, w, turn, segs, depth)
    local pts, x, y = { { p[1], p[2] } }, p[1], p[2]
    local n = max(3, floor(L / 0.08))
    for i = 1, n do
      local ai = a + turn * i / n
      x, y = x + L / n * cos(ai * RAD), y + L / n * sin(ai * RAD)
      -- room, once clear of the strand it leaves
      if L * i / n > 0.32 and free_at(x, y) < w * 0.5 + 0.02 then return nil end
      pts[#pts + 1] = { x, y }
    end
    local fork = depth < 2 and L > 0.6 and layout.chance(depth == 0 and 0.6 or 0.35)
    local sg = { pts = pts, w0 = w, w1 = fork and w * 0.8 or w * 0.62, tip = not fork, rec = not fork and layout.chance(0.3) }
    local bl = {}
    if layout.chance(0.45) and n > 6 then bl[1] = floor(n * layout.range(0.45, 0.75)) end
    sg.bl = bl
    segs[#segs + 1] = sg
    if fork then
      local q = pts[#pts]
      local ae = a + turn
      local spread = layout.range(20, 34)
      for side = -1, 1, 2 do
        branch(q, ae + side * spread, L * layout.range(0.45, 0.7), sg.w1, -side * layout.range(5, 20), segs, depth + 1)
      end
    end
    return sg
  end
  -- side branches along a strand's main axis, alternately left and right
  local function sidebranches(pts, w0, w1, segs, short)
    local s, L = ink.arclen(pts)
    local at, side = layout.range(1.0, 1.6), layout.chance(0.5) and 1 or -1
    local i = 1
    while at < L - 0.8 do
      while i < #pts and s[i] < at do i = i + 1 end
      local a, b = pts[max(1, i - 1)], pts[min(#pts, i + 1)]
      local ang = math.atan(b[2] - a[2], b[1] - a[1]) / RAD
      local u = s[i] / L
      local len = layout.range(0.9, 2.0) * (1 - 0.35 * u) * (short or 1)
      local w = lerp(w0, w1, u) * 0.85
      branch(pts[i], ang + side * layout.range(28, 50), len, w, -side * layout.range(10, 35), segs, 0)
      side = -side
      at = at + layout.range(0.9, 1.7) * (short or 1)
    end
  end
  -- the main axis of a strand: from the pebble to (c, top), swaying as the garden's stems do,
  -- ending in a fork
  local TOPS = { layout.range(0.86, 0.95), layout.range(0.6, 0.72), layout.range(0.38, 0.5) }
  for k = 1, NSTR do
    local top = col[2] + ch * TOPS[k]
    local c = col[1] + cw * layout.range(0.28, 0.68)
    local A, lam, ph = layout.range(0.9, 1.4), layout.range(4, 6.5), layout.range(0, 10)
    local f = ink.fbm1(layout, 2)
    local pts = {}
    local x0 = root[1] + (k - 2) * 0.1
    for y = root[2], top, 0.1 do
      local b = smoothstep(root[2], root[2] + 4, y)
      pts[#pts + 1] = keep({ lerp(x0, c + A * f(y / lam + ph), b), y }, col)
    end
    local w0, w1 = 0.2 - 0.02 * (k - 1), 0.12
    local segs = { { pts = pts, w0 = w0, w1 = w1, bl = {} } }
    -- bladders along the axis, a pair every so often
    local s = ink.arclen(pts)
    local at = layout.range(0.8, 1.6)
    for i = 2, #pts - 1 do
      if s[i] >= at then
        if layout.chance(0.6) then segs[1].bl[#segs[1].bl + 1] = i end
        at = at + layout.range(0.9, 1.8)
      end
    end
    strands[#strands + 1] = { segs = segs, x = root[1], y = root[2], t = layout.range(0.22, 0.34), main = pts, w0 = w0, w1 = w1 }
    for i = 1, #pts, 2 do disc(pts[i][1], pts[i][2], w0 * 0.5 + 0.06, 1) end
    -- the fork at the top
    local q, p = pts[#pts], pts[max(1, #pts - 2)]
    local ang = math.atan(q[2] - p[2], q[1] - p[1]) / RAD
    for side = -1, 1, 2 do
      branch(q, ang + side * layout.range(18, 32), layout.range(0.6, 1.0), w1 * 0.85, -side * layout.range(5, 20), segs, 0)
    end
    counts.wrack = counts.wrack + 1
  end
  -- along the bottom, the strand line: one strand lying the length of the band
  if STRAND then
    local fy = foot[2] + (foot[4] - foot[2]) * layout.range(0.3, 0.4)
    local f = ink.fbm1(layout, 2)
    local A, lam, ph = layout.range(0.18, 0.28), layout.range(2, 3.5), layout.range(0, 10)
    local pts = {}
    local x1 = foot[3] - layout.range(0.6, 1.2)
    for x = root[1], x1, 0.1 do
      local b = smoothstep(root[1], root[1] + 2.5, x)
      pts[#pts + 1] = keep({ x, lerp(root[2], fy + A * f(x / lam + ph), b) }, x < col[3] and col or foot)
    end
    if #pts >= 4 then
      local w0, w1 = 0.18, 0.1
      local segs = { { pts = pts, w0 = w0, w1 = w1, bl = {}, tip = true, rec = layout.chance(0.5) } }
      local s = ink.arclen(pts)
      local at = layout.range(0.8, 1.6)
      for i = 2, #pts - 1 do
        if s[i] >= at then
          if layout.chance(0.5) then segs[1].bl[#segs[1].bl + 1] = i end
          at = at + layout.range(1.0, 2.0)
        end
      end
      strands[#strands + 1] = { segs = segs, x = root[1], y = root[2], t = layout.range(0.22, 0.34), main = pts, w0 = w0, w1 = w1, low = true }
      for i = 1, #pts, 2 do disc(pts[i][1], pts[i][2], w0 * 0.5 + 0.05, 1) end
      counts.wrack = counts.wrack + 1
    end
  end
  -- on the last page, strands reach from the column out under the text
  if spill then
    local sh = spill[4] - spill[2]
    local nb = max(1, floor(sh / 7 * D + 0.5))
    for b = 1, nb do
      local src = strands[(b - 1) % NSTR + 1].main
      local y0 = spill[2] + sh * (b - 0.75) / nb
      local best, bi = math.huge, 1
      for i, p in ipairs(src) do local d = abs(p[2] - y0) if d < best then best, bi = d, i end end
      local s0 = src[bi]
      local w = spill[3] - s0[1]
      local x3 = s0[1] + w * layout.range(0.7, 0.88)
      local y3 = min(spill[4] - 1.2, y0 + sh / nb * layout.range(0.3, 0.55))
      local pts = ink.sample(ink.bezier3(s0[1], s0[2], s0[1] + w * 0.25, s0[2] + layout.range(-0.4, 0.8),
        x3 - w * 0.3, y3 + layout.range(-1.2, -0.3), x3, y3), max(4, floor(w / 0.1)))
      local segs = { { pts = pts, w0 = 0.15, w1 = 0.1, bl = {}, tip = true, rec = layout.chance(0.5) } }
      strands[#strands + 1] = { segs = segs, x = s0[1], y = s0[2], t = layout.range(0.22, 0.34), main = pts, w0 = 0.15, w1 = 0.1, arc = true }
      for i = 1, #pts, 2 do disc(pts[i][1], pts[i][2], 0.14, 1) end
      counts.wrack = counts.wrack + 1
    end
  end
  -- the side branches, once every strand is down, so none crosses another's axis
  for _, st in ipairs(strands) do
    sidebranches(st.main, st.w0, st.w1, st.segs, (st.low or st.arc) and 0.6 or nil)
    for j = 2, #st.segs do
      local sg = st.segs[j]
      for i = 1, #sg.pts, 2 do disc(sg.pts[i][1], sg.pts[i][2], sg.w0 * 0.5 + 0.04, 1) end
    end
  end
  -- the distance from each cell to the nearest strand, so the shells gather along the wrack
  -- as the garden's flowers grow from its stems
  local REACH = 1.6
  local sd = {}
  for i = 1, #gx do sd[i] = math.huge end
  for _, st in ipairs(strands) do
    for _, sg in ipairs(st.segs) do
      for i = 1, #sg.pts, 2 do
        local x, y = sg.pts[i][1], sg.pts[i][2]
        fld.each_near(x, y, REACH, function(c)
          local dx, dy = gx[c] - x, gy[c] - y
          local d = sqrt(dx * dx + dy * dy)
          if d < sd[c] then sd[c] = d end
        end)
      end
    end
  end
  -- drawn: the main axes under everything but the pebble; a branch now and then over the
  -- shells, so the wrack weaves through them
  for k, st in ipairs(strands) do
    local over = {}
    for j = 2, #st.segs do over[j] = layout.chance(0.3) end
    local e = event(0.5, 1.2)
    st.ev = e
    place(e, 2, st.x, st.y, function()
      ink.translate(-st.x, -st.y)
      local r = rng.fork()
      for j, sg in ipairs(st.segs) do
        if not over[j] then piece(r, sg, st.t, lx) end
      end
    end)
    for j, sg in ipairs(st.segs) do
      if over[j] then
        place(e, 6, st.x, st.y, function() ink.translate(-st.x, -st.y) piece(rng.fork(), sg, st.t, lx) end)
      end
    end
    if k == 1 then
      place(event(0.2), 3, root[1], root[2] - 0.05, function() pebble(rng.fork(), 0.42, lx) end)
    end
  end
  disc(root[1], root[2] - 0.05, 0.55, 1)

  -- 2. the shells: the document's cabinet and the page's own five kinds, none in the copper
  -- but the cabinet's (which has one at most)
  local cab = SPC.cabinet(g.docseed or 0)
  local own, kinds = {}, {}
  for _ = 1, 50 do
    if #own == 5 then break end
    local s = SPC.shsample(pgfseed(layout), "margin")
    if not kinds[s.kind] and not SPC.shcopper(s) then kinds[s.kind] = true own[#own + 1] = s end
  end
  local tally = {}
  -- the largest a shell may be at a point, in radius: large in the corner, small far off
  local RBIG = min(1.5, cw * 0.24) * (0.75 + 0.25 * D)
  local function cap(x, y)
    local u = min(1, reach(x, y))
    return 0.42 + (RBIG - 0.42) * (1 - u) ^ 1.3
  end
  -- how it lies: a coil flat, a valve on its back or its face, a spired shell on its side
  local function tilt(s)
    if s.group == "planispiral" then return layout.sym(35)
    elseif s.kind == "cowrie" then return layout.range(-90, 90)
    elseif s.group == "bivalve" then return layout.sym(55)
    elseif layout.chance(0.25) then return layout.sym(25) end
    return layout.range(40, 110) * (layout.chance(0.5) and 1 or -1)
  end
  -- lay shell s, `size` across at most, at (x, y), drawn on `layer`, its proxies at k
  local function lay(s, x, y, size, layer, k, step)
    local z = pgfseed(layout)
    local w, h = SHL.measure(s, z, size)
    local a = tilt(s)
    -- proxies along its long axis, so a turret shell leaves the room beside it
    local Lg, Sh = max(w, h), min(w, h)
    local ax = (h >= w and 90 or 0) + a
    local ux, uy = cos(ax * RAD), sin(ax * RAD)
    if Lg <= 1.3 * Sh then disc(x, y, Lg / 2, k)
    else
      local m = ceil((Lg - Sh) / (0.5 * Sh)) + 1
      for i = 0, m - 1 do
        local d = (Lg - Sh) / 2 * (2 * i / (m - 1) - 1)
        disc(x + ux * d, y + uy * d, Sh / 2 * 1.05, k)
      end
    end
    place(event(step or 0.12), layer, x, y, function()
      -- its shadow on the ground, to the lower right of the page whichever way it lies
      ink.push() ink.translate(lx * 0.045 * Lg, -0.065 * Lg) ink.rotate(a)
      for _, f in ipairs({ 1, 0.88 }) do
        ink.push() ink.scale(0.47 * w * f, 0.47 * h * f) ink.circle(0, 0, 1) ink.fill(tone(0.08), 0.09, true) ink.pop()
      end
      ink.pop()
      ink.rotate(a)
      if g.mirror then ink.scale(-1, 1) end       -- the page's mirror undone: its hand and its light kept
      SHL.draw(s, z, size, true)
    end)
    tally[s] = (tally[s] or 0) + 1
    counts.shell = counts.shell + 1
  end
  -- the cell where the most room is, weighted toward the corner (low) or anywhere
  local function biggest(weight)
    local best, bi = -1, nil
    for i = 1, #gx do
      local v = free[i] * layout.range(0.85, 1.15) * weight(gx[i], gy[i], i)
      if v > best then best, bi = v, i end
    end
    return bi
  end

  -- marks: a small copper scallop beside each heading; \florilegiumbloom[kind] a shell of
  -- that kind (or group) in the ink, any of the cabinet's without one
  for _, mk in ipairs(g.marks or {}) do
    if mk.kind == "heading" or mk.kind == "bloom" then
      local heading = mk.kind == "heading"
      local R = heading and (mk.arg == 1 and 0.42 or 0.32) or 0.6
      local x, y = g.colright - R - 0.25, mk.y + 0.12
      if free_at(x, y) >= R + 0.05 then
        local s
        if heading then s = SPC.shsample(pgfseed(layout), "any", nil, scallops())
        else
          local z0, ok = pgfseed(layout), false
          if mk.arg ~= "" then ok, s = pcall(SPC.shsample, z0, mk.arg) end
          if not ok then
            if mk.arg ~= "" and texio then
              texio.write_nl("florilegium warning: \\florilegiumbloom[" .. tostring(mk.arg) .. "] names no kind or group of shells; one of the cabinet's lies there")
            end
            s = cab[layout.int(1, #cab)]
          end
        end
        local z = pgfseed(layout)
        local a = layout.sym(20)
        place(event(0.2), 5, x, y, function()
          ink.rotate(a)
          if g.mirror then ink.scale(-1, 1) end
          if heading then ink.in_accent(function() SHL.draw(s, z, 2 * R, true) end) else SHL.draw(s, z, 2 * R, true) end
        end)
        disc(x, y, R + 0.1, 1)
        counts.mark = (counts.mark or 0) + 1
      end
    end
  end

  -- the cabinet: the largest nearest the corner, the rest low along the column and the band
  local order = {}
  for i = 1, #cab do order[i] = cab[i] end
  table.sort(order, function(p, q) return p.size > q.size end)
  local ncab = D >= 0.3 and #order or D >= 0.1 and 2 or 1
  for i = 1, ncab do
    local bi = biggest(function(x, y) local u = reach(x, y) return u < 0.45 and (1.3 - u) or 0 end)
    if not bi then break end
    local x, y, f = gx[bi], gy[bi], free[bi]
    local r = min(f * 0.95, RBIG * (1.05 - 0.1 * i))
    if r < 0.3 then break end
    lay(order[i], x, y, 2 * r, 5, 0.75, 0.25)
  end

  -- tufts of fine weed in the middle of the column, one of them in copper
  local NW = D >= 0.4 and layout.int(1, 3) or 0
  for i = 1, NW do
    local bi = biggest(function(x, y) local u = reach(x, y) return (u > 0.2 and u < 0.85) and 1 or 0 end)
    if not bi or free[bi] < 0.45 then break end
    local x, y, f = gx[bi], gy[bi], free[bi]
    local L = min(1.7, 1.6 * f)
    local a = layout.sym(35)
    local copper = i == 1
    local t = layout.range(0.3, 0.45)
    local fx, fy = x - L * 0.45 * sin(-a * RAD), y - L * 0.45 * cos(a * RAD)
    place(event(0.2), 4, fx, fy, function()
      ink.rotate(a)
      weed(rng.fork(), L, copper and ink.accent(0) or tone(t), 2, 0.045)
    end)
    disc(x, y, L * 0.45, 0.8)
    counts.weed = counts.weed + 1
  end

  -- 3. the rest, largest hole first: shells of the page's own kinds, a size that suits the
  -- hole and the kind's real size, overlapping a little, now and then one tucked under
  local area = 0
  for _, r in ipairs({ col, foot, spill }) do area = area + (r[3] - r[1]) * (r[4] - r[2]) end
  local NMAX = floor(D * area / 3.2 + 0.5)
  local LO, HI = log(15), log(150)
  local function pick(r)
    local want = LO + (HI - LO) * clamp((r - 0.2) / (RBIG - 0.2), 0, 1)
    local ws, total = {}, 0
    for i, s in ipairs(own) do
      -- the closer its real size, the likelier; the more there are of it, the less (as the
      -- garden's motifs, w / (1 + count / cap))
      ws[i] = (exp(-((log(s.size) - want) / 0.8) ^ 2) + 0.08) / (1 + (tally[s] or 0) / 4)
      total = total + ws[i]
    end
    local u = layout.u() * total
    for i, s in ipairs(own) do u = u - ws[i] if u <= 0 then return s end end
    return own[#own]
  end
  local n = 0
  while n < NMAX and #own > 0 do
    -- along the wrack first, the band along the bottom before the column (its holes are smaller)
    local bi = biggest(function(x, y, i)
      return (1.15 - 0.3 * min(1, reach(x, y))) * (sd[i] <= REACH and 1 or 0.3) * (x > col[3] and y < foot[4] and 1.8 or 1)
    end)
    if not bi then break end
    local x, y, f = gx[bi], gy[bi], free[bi]
    if f < 0.2 then break end
    local R = min(f, cap(x, y) * (sd[bi] <= REACH and 1 or 0.8))
    local tuck = layout.chance(0.18) and R > 0.3
    local r = R * (tuck and layout.range(1.15, 1.35) or layout.range(0.62, 1.0))
    lay(pick(r), x, y, 2 * r, tuck and 3 or 5, tuck and 0.55 or 0.72)
    n = n + 1
  end

  -- 4. grit along the strand line: sand, pebbles and broken shell, thinning out upward
  local NG = floor(70 * D + 0.5)
  for _ = 1, NG do
    local bi = biggest(function(x, y)
      local u = reach(x, y)
      return max(0, 1 - 1.6 * u) * layout.range(0.4, 1.6)
    end)
    if not bi then break end
    local x, y, f = gx[bi], gy[bi], free[bi]
    if f < 0.05 then break end
    local u = layout.u()
    if f > 0.14 and u < 0.25 then
      local r = min(f * 0.8, 0.22) * layout.range(0.6, 1.0)
      local t = layout.range(0.55, 0.78)
      place(event(0.02, 0.2), 4, x, y, function() fragment(rng.fork(), r, t) end)
      disc(x, y, r, 0.9)
    else
      local r = min(f * 0.6, 0.07) * layout.range(0.35, 1.0)
      local ring, t = layout.chance(0.3), layout.range(0.35, 0.8)
      place(event(0.02, 0.2), 1, x, y, function()
        if ring then
          ink.smooth(ink.blob(rng.fork(), 0, 0, r * 1.2, r, 0.15, 7), true) ink.fill(tone(0.88))
          ink.smooth(ink.blob(rng.fork(), 0, 0, r * 1.2, r, 0.15, 7), true) ink.stroke(tone(t - 0.2), 0.25, 0.9)
        else ink.circle(0, 0, r) ink.fill(tone(t), 0.85, true) end
      end)
      disc(x, y, max(r, 0.08), 0.9)
    end
    counts.grit = counts.grit + 1
  end

  -- a headpiece's vine (\florilegiumheadpiece) carries small tips of wrack
  local headpieces = false
  for _, mk in ipairs(g.marks or {}) do
    if mk.kind == "headpiece" and g.headpiece then
      local t = layout.range(0.16, 0.28)
      local function leaf(r, L)
        ink.scale(L)
        local pts = {}
        for i = 0, 8 do pts[#pts + 1] = { 0.06 * sin(i / 8 * pi), i / 8 * 0.6 } end
        local segs = { { pts = pts, w0 = 0.2, w1 = 0.16, bl = { 5 } } }
        local q = pts[#pts]
        for side = -1, 1, 2 do
          local tip = {}
          for i = 0, 5 do
            local a = (90 + side * 25 - side * 8 * i / 5) * RAD
            tip[#tip + 1] = { q[1] + 0.4 * i / 5 * cos(a), q[2] + 0.4 * i / 5 * sin(a) }
          end
          segs[#segs + 1] = { pts = tip, w0 = 0.15, w1 = 0.12, tip = true, rec = r.chance(0.3) }
        end
        for _, sg in ipairs(segs) do piece(r, sg, t, lx) end
      end
      local layer, tag = ink.layer(-1), ink.tag(nil)
      local px = g.headpiece(mk, leaf)
      ink.layer(layer) ink.tag(tag)
      if px then headpieces = true end
    end
  end

  -- assemble: a safety clip a little outside the regions, as the garden's
  ink.tag(nil)
  ink.layer(0)
  local bleed = g.bleed or 0
  for _, r in ipairs({ col, foot, spill }) do
    local x1, y1, x2, y2 = r[1] - 0.25, r[2] - 0.3, r[3] + (r == col and (headpieces and 0.5 or 0.25) or 0.3), r[4] + 0.3
    if bleed > 0 then
      if r[1] < 0.6 then x1 = x1 - bleed end
      if r[2] < 0.6 then y1 = y1 - bleed end
      if r[3] > g.pw - 0.6 then x2 = x2 + bleed end
      if r[4] > g.ph - 0.6 then y2 = y2 + bleed end
    end
    ink.poly({ { x1, y1 }, { x2, y1 }, { x2, y2 }, { x1, y2 } }, true)
  end
  ink.clip()
  ink.layer(99)
  ink.unclip()

  if texio then
    texio.write_nl(string.format("florilegium: %d shells, %d strands of wrack, %d tufts of weed, %d grains", counts.shell,
      counts.wrack, counts.weed, counts.grit))
  end
  if anim then
    local total = 0
    for _, e in ipairs(events) do total = max(total, e.t0 + e.dur) end
    return { rec = ink.take_recording(), total = max(total, 0.5) }
  end
  ink.flush()
  -- what lies on the page, for a page that describes itself (florilegium-svg.lua and the
  -- playground): the cabinet's four and the page's own, each with its words and how many
  local shells = {}
  for i, s in ipairs(order) do
    shells[#shells + 1] = { kind = s.kind, seed = s.seed, text = SPC.shdescribe(s), count = tally[s] or 0, cabinet = true, i = i }
  end
  for _, s in ipairs(own) do
    shells[#shells + 1] = { kind = s.kind, seed = s.seed, text = SPC.shdescribe(s), count = tally[s] or 0 }
  end
  return { stats = { motifs = counts.shell + counts.weed + counts.grit, counts = counts, shells = shells } }
end

-- the header's fleuron is a scallop
M.flora = { hedera = fleuron }

return M
