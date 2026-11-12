// The species genome in the browser, sampled as florilegium-species.lua samples it.
// A port of three things only: ink.pgfrng (pgf's Lehmer generator, replayed step for
// step), the distribution draw of M.sample, and the pool of a document. The tables
// themselves are not ported: tools/genomes.lua writes them out of the Lua package into
// species-data.js, so this file holds no botany, only the interpreter.
// species-check.js proves the two agree, trait for trait.
(function (g) {
  const data = g.FLORILEGIUM_SPECIES
  if (!data) throw new Error('florilegium: load species-data.js before species.js')
  const TRAITS = data.traits
  const plans = new Map(data.plans.map((p) => [p.name, p]))

  // pgfmathfunctions.random.code.tex: Lehmer's generator, a = 69621, m = 2^31-1, by
  // Schrage's method; rnd is (z mod 100001) read as five decimals, random(a, b) is
  // a + z mod (b-a+1). florilegium-pgfmath.lua: pgfrng, to the scaled point.
  function pgfrng(seed) {
    let z = Math.floor(seed)
    if (!(z >= 1 && z <= 2147483646)) {
      throw new Error('florilegium: a pgf seed is an integer from 1 to 2147483646: ' + seed)
    }
    function step() {
      let t = 69621 * (z % 30845) - 23902 * Math.floor(z / 30845)
      if (t < 0) t += 2147483647
      z = t
      return t
    }
    // TeX's round_decimals of five digits, as a number of 1/65536ths
    const decimals = (n) => Math.floor((Math.floor((n * 131072) / 100000) + 1) / 2)
    return {
      step,
      rnd() {
        const c = step() % 100001
        return c === 100000 ? 1 : decimals(c) / 65536
      },
      random(a, b) {
        if (a > b) [a, b] = [b, a]
        return a + (step() % (b - a + 1))
      },
    }
  }

  // <factor><dimen> as tex.web 455 computes it (florilegium-pgfmath.lua: mulf)
  function mulf(x, y) {
    const neg = y < 0
    if (neg) y = -y
    const f = y % 65536
    let r = Math.floor(y / 65536) * x
    if (x >= 0) r += Math.floor((x * f) / 65536)
    else r -= Math.floor((-x * f) / 65536)
    return neg ? -r : r
  }

  // one draw from a distribution: C, I, R, W, BY, as florilegium-species.lua: draw. An R
  // arrives as the two integers pgfmath would hold, so no decimal is parsed here.
  function draw(d, rng, sp) {
    switch (d[0]) {
      case 'c':
        return d[1]
      case 'i':
        return rng.random(d[1], d[2])
      case 'r':
        return (d[1] + mulf(d[2], Math.floor(rng.rnd() * 65536 + 0.5))) / 65536
      case 'w': {
        let total = 0
        for (let i = 2; i < d.length; i += 2) total += d[i]
        let k = rng.random(1, total)
        for (let i = 1; i < d.length; i += 2) {
          k -= d[i + 1]
          if (k <= 0) return d[i]
        }
        throw new Error('florilegium: a weighted choice ran out')
      }
      case 'by': {
        const v = sp[d[1]]
        const sub = d[2][String(v)] || d[2]._
        if (!sub) throw new Error('florilegium: no distribution for ' + d[1] + ' = ' + v)
        return draw(sub, rng, sp)
      }
    }
    throw new Error('florilegium: unknown distribution ' + d[0])
  }

  // the plans a role may draw, as a weighted choice, M.roleplans
  function roleplans(role) {
    const plan = plans.get(role)
    if (plan && !data.roles[role]) return ['w', role, plan.w]
    const t = []
    for (const p of data.plans) {
      if ((role === 'any' && !p.apart) || p.roles[role]) t.push(p.name, p.w)
    }
    if (!t.length) throw new Error('florilegium: no plant for the role ' + role)
    return ['w', ...t]
  }

  // a species from a pgf seed, M.sample: the plan first, then every trait in order, two
  // draws of Lehmer's generator thrown away
  function sample(seed, role) {
    const rng = pgfrng(seed)
    for (let i = 0; i < data.warm; i++) rng.step()
    const sp = { seed, role: role || 'any' }
    sp.plan = draw(roleplans(sp.role), rng, sp)
    const plan = plans.get(sp.plan)
    for (let i = 1; i < TRAITS.length; i++) {
      const t = TRAITS[i]
      sp[t] = draw(plan.dist[t], rng, sp)
    }
    return sp
  }

  // a document's eight species, M.pool: no body plan twice, both heroes showy
  const showy = (sp) => !data.sprays[sp.inflo] && sp.color !== 'red' && sp.color !== 'orange'

  function pool(docseed) {
    const g = rng((docseed || 0) * 104729 + 307)
    const out = []
    const used = new Set()
    for (const role of data.slots) {
      let sp
      let tries = 0
      do {
        sp = sample(1 + Math.floor(g.u() * 2147483645), role)
        if (++tries > 10000) throw new Error('florilegium: no body plan left for the role ' + role)
      } while (used.has(sp.plan) || (role === 'hero' && !showy(sp)))
      used.add(sp.plan)
      sp.slot = out.length + 1
      out.push(sp)
    }
    return out
  }

  // ink.rng: mulberry32, as florilegium-ink.lua holds it
  function rng(seed) {
    let s = Math.floor(seed) >>> 0
    const u = () => {
      s = (s + 0x6d2b79f5) >>> 0
      let t = s
      t = Math.imul(t ^ (t >>> 15), t | 1) >>> 0
      t = (t ^ ((t + Math.imul(t ^ (t >>> 7), t | 61)) >>> 0)) >>> 0
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296
    }
    return {
      u,
      int: (a, b) => a + Math.floor((b - a + 1) * u()),
      chance: (p) => u() < p,
    }
  }

  // the demo reads the tables and a document's pool; the draws above stay internal
  g.FLORILEGIUM = { data, pool }
})(globalThis)
