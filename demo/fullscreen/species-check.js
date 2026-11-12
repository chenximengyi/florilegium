// Prove that the browser draws the same species as the package: read the reference
// that tools/genomes.lua --check prints from the Lua tables, sample the same species
// here, and compare every trait of every species of every document's pool.
//   lua tools/genomes.lua --check 4 > build/genome-reference.txt
//   node demo/fullscreen/species-check.js build/genome-reference.txt
const fs = require('fs')
const path = require('path')

const here = __dirname
require(path.join(here, 'species-data.js'))
require(path.join(here, 'species.js'))
const F = globalThis.FLORILEGIUM

const file = process.argv[2]
if (!file) {
  console.error('usage: node species-check.js REFERENCE')
  process.exit(2)
}

// as tools/genomes.lua writes a real trait
function values(sp) {
  return F.data.traits
    .map((k) => {
      const v = sp[k]
      return typeof v === 'number' && !Number.isInteger(v)
        ? `${k}=${Math.round(v * 65536)}sp`
        : `${k}=${v}`
    })
    .join(' ')
}

const lines = fs.readFileSync(file, 'utf8').split('\n').filter((l) => l.trim())
const pools = new Map()
const pool = (d) => {
  if (!pools.has(d)) pools.set(d, F.pool(d))
  return pools.get(d)
}

let checked = 0
let bad = 0
for (const line of lines) {
  const [kind, a, b, ...rest] = line.split(' ')
  if (kind === 'pool') {
    const d = Number(a)
    const i = Number(b)
    const [seed, ...traits] = rest
    const want = traits.join(' ')
    const sp = pool(d)[i - 1]
    if (sp && String(sp.seed) !== seed) {
      bad++
      console.error(`document ${d}, species ${i}: seed ${sp.seed} != ${seed}`)
    }
    const got = values(sp)
    if (!sp) {
      bad++
      console.error(`missing species ${i} of document ${d}`)
    } else if (got !== want) {
      bad++
      const w = want.split(' ')
      const o = got.split(' ')
      const diff = o.map((v, k) => (v === w[k] ? null : `  ${v}  !=  ${w[k]}`)).filter(Boolean)
      console.error(`document ${d}, species ${i} (${sp.plan}):\n${diff.slice(0, 8).join('\n')}`)
    }
    checked++
  }
}

if (bad) {
  console.error(`${bad} of ${checked} lines differ`)
  process.exit(1)
}
console.log(`${checked} lines agree: the browser samples the package's species`)
