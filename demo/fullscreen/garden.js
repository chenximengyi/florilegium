const garden = document.querySelector('#garden')
const plant = document.querySelector('#plant')
const botany = document.querySelector('#botany')

// The garden is the document's flora: ?seed=7 grows the eight species that
// \florilegiumseed{7} puts in its pool, species for species. Without a seed in the URL
// one is drawn for this visit and kept out of the address, so a reload grows a new garden
// and the URL stays as it was asked for.
const asked = new URLSearchParams(location.search).get('seed')
const docseed =
  asked === null ? 1 + Math.floor(Math.random() * 999) : Math.max(0, Math.floor(Number(asked) || 0))
const species = window.FLORILEGIUM.pool(docseed)
const seed = (docseed * 7919 + 307) >>> 0
const motion = matchMedia('(prefers-reduced-motion: reduce)')
const duration = 14000
let elapsed = 0
let lastFrame = null
let frame = 0
let events = []
let width = 0
let height = 0

function randomFrom(seed) {
  let state = 1 + (seed % 2147483646)
  return (min, max) => {
    state = (state * 48271) % 2147483647
    return min + ((max - min) * (state - 1)) / 2147483646
  }
}

function svg(parent, name, attributes) {
  const element = document.createElementNS(garden.namespaceURI, name)
  for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
  parent.append(element)
  return element
}

// All organs are drawn in local coordinates and instanced by the stems.
// Wash, pooled edges and pale strokes share a contour on each petal.
function makeBotany(random) {
  const ink = '#16296f',
    blue = '#254ba4',
    light = '#a9c4ec',
    copper = '#ad5b21'
  const group = (id) => svg(botany, 'g', { id })
  const path = (g, d, fill, attrs = {}) => svg(g, 'path', { d, fill, ...attrs })
  const pen = (g, d, color, width, opacity = 1) =>
    path(g, d, 'none', { stroke: color, 'stroke-width': width, opacity, 'stroke-linecap': 'round' })
  const bead = (g, x, y, r, fill) => svg(g, 'circle', { cx: x, cy: y, r, fill })
  function wash(id, colors) {
    const g = svg(botany, 'linearGradient', { id, x1: '0%', y1: '20%', x2: '95%', y2: '70%' })
    colors.forEach(([offset, color]) => svg(g, 'stop', { offset, 'stop-color': color }))
  }
  wash('cobalt', [
    [0, '#152776'],
    [0.15, '#244199'],
    [0.36, '#345cc1'],
    [0.58, '#214caa'],
    [0.84, '#244594'],
    [1, '#12276d'],
  ])
  wash('blade', [
    [0, '#213479'],
    [0.43, '#243f98'],
    [0.49, '#4869be'],
    [0.52, '#24489f'],
    [1, '#172d7d'],
  ])
  wash('porcelain', [
    [0, '#8dafe2'],
    [0.42, '#cddff9'],
    [0.72, '#9abdea'],
    [1, '#729edc'],
  ])

  const blade = group('lance')
  path(blade, 'M0 0 C-11 -9 -8 -33 3 -65 C8 -49 14 -15 0 0Z', 'url(#blade)')
  pen(blade, 'M0 0 Q4 -29 3 -63 M-2 -4 Q-4 -27 2 -56 M2 -4 Q9 -25 5 -50', light, 0.5)
  const small = group('leaflet')
  path(small, 'M0 0 C-10 -2 -12 -12 -8 -22 Q-3 -32 0 -36 C3 -25 16 -9 0 0Z', 'url(#blade)')
  pen(small, 'M0 -1 Q-3 -15 0 -32', '#cfddf6', 0.8)
  const oak = group('lobed')
  const edge = [
    [0, 0],
    [-5, -2],
    [-14, -6],
    [-21, -10],
    [-23, -14],
    [-16, -16],
    [-27, -24],
    [-29, -29],
    [-23, -28],
    [-17, -30],
    [-26, -39],
    [-25, -43],
    [-20, -42],
    [-14, -40],
    [-16, -48],
    [-12, -49],
    [-8, -46],
    [-7, -53],
    [-4, -51],
    [0, -60],
  ]
  const outline = edge.concat(
    edge
      .slice(1, -1)
      .reverse()
      .map(([x, y]) => [-x * 0.94, y + 1]),
  )
  path(oak, 'M' + outline.map((p) => p.join(' ')).join(' L') + 'Z', 'url(#blade)', {
    stroke: ink,
    'stroke-width': 0.5,
  })
  pen(oak, 'M0 2 Q-2 -28 0 -58', '#c2d5f0', 1)
  for (const side of [-1, 1]) {
    for (let n = 0; n < 5; n++) {
      const y = -5 - 8 * n,
        reach = [21, 25, 21, 13, 7][n] * side
      pen(
        oak,
        `M0 ${y} Q${reach * 0.46} ${y - 5} ${reach} ${y - 12} M${reach * 0.55} ${y - 6} l${reach * 0.1} -6`,
        light,
        0.72,
      )
    }
  }

  // A white species is painted in the porcelain, as the plates paint a white flower;
  // every other color keeps the cobalt. Only the corolla is washed: the stems and the
  // leaves are the ink's, as the margin paints them.
  const WASHES = [
    ['', 'url(#cobalt)', '#193582', '#a2c1e7', '#172f78', '#132976', '#85a9ed'],
    ['-p', 'url(#porcelain)', '#789fdf', '#f5faff', '#729edc', '#9abdea', '#ffffff'],
  ]
  for (const [suffix, wash, edge, veinlight, veindark, pool, poolpale] of WASHES) {
    for (let v = 0; v < 3; v++) {
      const flower = group('daisy-' + v + suffix),
        count = [10, 12, 9][v]
      for (let i = 0; i < count; i++) {
        const r = random(24, 30),
          w = random(2.65, 3.85)
        const p = svg(flower, 'g', {
          transform: `rotate(${(i * 360) / count + random(-3, 3)}) skewX(${random(-5, 5)})`,
        })
        path(
          p,
          `M-.65 -3 C-1.2 -7 ${-w - 1} ${-r * 0.6} ${-w} ${-r + 4}
        Q${-w - 0.25} ${-r + 1} -1.8 ${-r + 0.8} Q0 ${-r - 1.2} 1.6 ${-r + 0.4}
        Q${w} ${-r + 0.4} ${w + 0.2} ${-r + 4} C${w + 0.8} ${-r * 0.59} .9 -7 .65 -3Z`,
          wash,
          { stroke: edge, 'stroke-width': 0.45 },
        )
        for (let j = 0; j < 5; j++) {
          const x = ((j - 2) * w) / 3
          pen(
            p,
            `M${x * 0.14} -5 Q${x * 1.12} ${-r * 0.62} ${x * 0.83 + random(-0.5, 0.5)} ${-r + random(1.8, 5.8)}`,
            j % 2 ? veinlight : veindark,
            random(0.24, 0.65),
            random(0.38, 0.73),
          )
        }
        // Translucent pools follow the petal's folds, with darker pigment at the rim.
        for (let j = 0; j < 8; j++) {
          const x = random(-w * 0.51, w * 0.51),
            y = random(-r + 3.3, -r * 0.45)
          const breadth = random(0.38, 1.0),
            length = random(1.3, 3.7)
          path(
            p,
            `M${x} ${y} q${-breadth} .6 ${-breadth * 0.62} ${length} q${breadth * 1.6} -1 ${breadth * 0.62} ${-length}Z`,
            j % 3 ? pool : poolpale,
            { opacity: random(0.12, 0.28) },
          )
        }
      }
      bead(flower, 0, 0, 5.6, '#764420')
      for (let j = 0; j < 90; j++) {
        const a = j * 2.39996,
          r = 5.15 * Math.sqrt(j / 90)
        bead(
          flower,
          r * Math.cos(a),
          r * Math.sin(a),
          random(0.24, 0.47),
          ['#e7ae66', '#af702e', '#da9950', '#935023'][j % 4],
        )
      }
    }

    const lily = group('lily' + suffix)
    // A turned flower in profile: petals curl away from the long stamens.
    for (const [i, angle] of [-73, -41, -13, 20, 50, 77].entries()) {
      const p = svg(lily, 'g', { transform: `rotate(${angle}) scale(${i % 2 ? -1 : 1} 1)` })
      path(
        p,
        'M-1 1 C-8 -3 -13 -17 -7 -31 Q-4 -38 1 -40 C-9 -28 -4 -13 4 -4 Q5 1 -1 1Z',
        i % 2 || suffix ? wash : 'url(#blade)',
        { stroke: ink, 'stroke-width': 0.52 },
      )
      pen(p, 'M1 -2 C-6 -13 -10 -25 -3 -34', '#a6c4ed', 0.7, 0.85)
      for (let k = 0; k < 6; k++) bead(p, random(-4.4, -1), random(-12, -4), random(0.45, 0.9), '#102767')
    }
    for (let i = 0; i < 6; i++) {
      const x = (i - 2.5) * 5.2,
        y = random(19, 32)
      pen(lily, `M0 -2 Q${x * 0.37} 7 ${x} ${y}`, ink, 0.48)
      svg(lily, 'ellipse', {
        cx: x,
        cy: y,
        rx: 0.95,
        ry: 1.7,
        fill: copper,
        transform: `rotate(${-x * 2} ${x} ${y})`,
      })
    }
  }

  const spray = group('spray')
  for (let i = 0; i < 10; i++) {
    const x = (i % 2 ? -1 : 1) * random(3, 14) * (1 - i / 16) + i * 0.6,
      y = -i * 4 - random(0, 4)
    pen(spray, `M0 0 Q${i * 0.25} ${y * 0.7} ${x} ${y}`, ink, 0.52)
    for (let j = 0; j < 5; j++) {
      const a = (j * Math.PI * 2) / 5
      svg(spray, 'ellipse', {
        cx: x + 2 * Math.cos(a),
        cy: y + 2 * Math.sin(a),
        rx: 1.9,
        ry: 1.65,
        fill: j % 2 ? blue : ink,
      })
    }
    bead(spray, x, y, 0.8, '#f9f6ed')
  }

  const ghost = group('star')
  for (let j = 0; j < 6; j++) {
    const p = svg(ghost, 'g', { transform: `rotate(${60 * j + random(-5, 5)})` })
    path(p, 'M0 2 C-15 -5 -14 -19 -4 -38 Q-1 -44 0 -50 C4 -40 23 -21 11 -8 Q6 -3 0 2Z', 'url(#porcelain)', {
      stroke: '#789fdf',
      'stroke-width': 1,
    })
    pen(p, 'M0 0 Q0 -22 0 -46 M1 -2 Q10 -20 3 -37 M-1 -3 Q-9 -17 -4 -31', '#f5faff', 0.8)
  }
  bead(ghost, 0, 0, 2.4, copper)

  const beetle = group('beetle')
  for (const s of [-1, 1]) {
    for (let i = 0; i < 3; i++)
      pen(beetle, `M${s * 3} ${-2 + i * 3} q${s * 4} -2 ${s * 5} 1 l${s * 2} 3`, '#613e28', 0.65)
    pen(beetle, `M${s * 1.2} -7 q${s * 4} -3 ${s * 3} -6`, '#66442a', 0.6)
  }
  svg(beetle, 'ellipse', { cx: 0, cy: -6, rx: 3.8, ry: 3.5, fill: '#68422a' })
  svg(beetle, 'ellipse', {
    cx: 0,
    cy: 2.6,
    rx: 6.8,
    ry: 8.7,
    fill: '#946139',
    stroke: '#493c36',
    'stroke-width': 0.65,
  })
  for (const s of [-1, 1]) {
    const cover = svg(beetle, 'g', { transform: `scale(${s} 1)` })
    path(cover, 'M.2 -4 Q6 -4 6.5 2 Q7 8 1 11 Q-.3 4 .2 -4Z', 'url(#blade)')
    pen(cover, 'M1 -3 Q4 2 2 8 M2 -2 Q6 3 4 6', '#a8bedc', 0.55)
    for (const [x, y] of [
      [1.5, 0],
      [4, 3],
      [2, 6],
    ])
      bead(cover, x, y, 0.53, ink)
  }

  const butterfly = group('butterfly')
  for (const flip of [-1, 1]) {
    const wing = svg(butterfly, 'g', { transform: `scale(${flip} 1)` })
    path(wing, 'M0 -2 C5 -10 23 -28 32 -26 C38 -23 27 -4 16 0 C22 0 27 9 20 17 C15 24 4 17 1 5Z', '#4775c4', {
      stroke: ink,
      'stroke-width': 1.4,
    })
    path(wing, 'M2 -3 Q15 -20 29 -23 Q22 -8 5 -2Z', '#92b6e5')
    pen(wing, 'M1 0 L28 -22 M2 1 Q13 -4 23 -7 M2 4 Q11 10 17 16', ink, 0.6)
    for (const [x, y, r] of [
      [18, 12, 3],
      [24, -14, 1.3],
      [28, -19, 1.1],
      [13, 15, 1.2],
    ]) {
      bead(wing, x, y, r, ink)
      bead(wing, x, y, r * 0.51, '#d1a875')
    }
  }
  path(butterfly, 'M-1 -7 Q-4 1 0 14 Q4 3 1 -7Z', ink)
  pen(butterfly, 'M0 -6 Q-5 -19 -8 -17 M0 -6 Q3 -19 7 -19', ink, 0.75)
}

// A rotated organ occupies the convex hull of its anchor and its full-sized
// outline during growth. Fit that envelope before scheduling the animation.
const organBounds = new Map()
function roomForOrgan(id, point, angle, w, h) {
  const box = organBounds.get(id)
  const a = (angle * Math.PI) / 180,
    c = Math.cos(a),
    s = Math.sin(a)
  let limit = Infinity
  for (const x of [box.x - 2, box.x + box.width + 2]) {
    for (const y of [box.y - 2, box.y + box.height + 2]) {
      const dx = c * x - s * y,
        dy = s * x + c * y
      if (dx > 0) limit = Math.min(limit, (w - point.x) / dx)
      if (dx < 0) limit = Math.min(limit, -point.x / dx)
      if (dy > 0) limit = Math.min(limit, (h - point.y) / dy)
      if (dy < 0) limit = Math.min(limit, -point.y / dy)
    }
  }
  return limit
}

// ---------------------------------------------------------------- the document's plants
// This demo's vocabulary is eleven organs, not the package's fifteen flower forms, so a
// species is read into it: the form of its flower says which corolla, the leaf's edge and
// shape say which leaf, its cluster says how many flowers a twig carries, its size says
// how large. A white one is painted in the porcelain, all the rest in the cobalt.
function corollaOf(sp) {
  const f = sp.form
  if (f === 'none') return 'spray'                        // a catkin: no petals at all
  if (f === 'head') return 'daisy'
  if (f === 'orchid' || f === 'spurred') return 'star'
  if (f === 'lily' || f === 'iris' || f === 'campanulate' || f === 'urceolate' ||
      f === 'tubular' || f === 'funnelform' || f === 'bilabiate' || f === 'papilionaceous') {
    return 'lily'
  }
  return 'daisy'                                          // rotate, rosaceous, cruciform, salverform
}

const pale = (sp) => (sp.color === 'white' ? '-p' : '')

function flowerOf(sp) {
  const corolla = corollaOf(sp)
  if (corolla === 'daisy') return 'daisy-' + (sp.merosity % 3) + pale(sp)
  if (corolla === 'lily') return 'lily' + pale(sp)
  return corolla
}

function leafOf(sp) {
  if (/lobed|pinnatifid/.test(sp.leafmargin) || sp.dissection > 0.35) return 'lobed'
  if (/^(linear|lanceolate|oblong)$/.test(sp.leafshape)) return 'lance'
  return 'leaflet'
}

// how many flowers one twig carries, and how large this plant draws them
const clusterOf = (sp) =>
  sp.inflo === 'solitary' || sp.inflo === 'head'
    ? 1
    : Math.min(7, Math.max(2, Math.round(sp.count / 4)))
const sizeOf = (sp) => Math.min(1.5, 0.8 + sp.size / 100)
const tiltOf = (sp, random) =>
  sp.orient === 'nodding' ? random(130, 170) : sp.orient === 'horizontal' ? random(75, 105) : random(-25, 25)

function layout(w, h) {
  const random = randomFrom(seed)
  const drawing = document.createDocumentFragment()
  const mist = svg(drawing, 'g', { opacity: 0.81 })
  const stems = svg(drawing, 'g', { fill: 'none', stroke: '#182872', 'stroke-linecap': 'round' })
  const foliage = svg(drawing, 'g', {})
  const flowers = svg(drawing, 'g', {})
  const schedule = []
  const mirror = random(0, 1) < 0.5
  const rootX = random(0.04, 0.19)
  const root = { x: rootX * w, y: h - 2, angle: -Math.PI / 2, time: 0, sp: species[0] }
  const anchors = [root]
  const reserved = []
  const area = w * h
  const degrees = 180 / Math.PI
  // Scale the larger organs to the shorter side, so the specimen still has
  // small sprays and a few dominant flower heads on a phone.
  const scale = Math.max(0.65, Math.min(1.24, Math.min(w, h) / 720))

  function organ(layer, id, point, angle, size, delay = 0) {
    let limit = roomForOrgan(id, point, angle, w, h)
    if (limit < size && layer === foliage) {
      const inward = Math.atan2(h / 2 - point.y, w / 2 - point.x) * degrees + 90
      const inwardLimit = roomForOrgan(id, point, inward, w, h)
      if (inwardLimit > limit) {
        angle = inward
        limit = inwardLimit
      }
    }
    size = Math.min(size, limit)
    if (size <= 0) return
    const node = svg(layer, 'use', {
      href: '#' + id,
      transform: `translate(${point.x} ${point.y}) rotate(${angle})`,
    })
    node.style.visibility = 'hidden'
    const transform = garden.createSVGTransform()
    transform.setScale(0, 0)
    node.transform.baseVal.appendItem(transform)
    schedule.push({ node, start: point.time + delay, span: 22 + size * 32, scale: transform, size })
  }

  // Keep positions and arrival times together. Side shoots can take root at
  // any sampled point on the cubic, including between two main stem nodes.
  function shoot(from, x, y, startAngle, endAngle, width, speed = 1) {
    // A cubic stays within the hull of its four control points. Keeping that
    // hull inside the inset also keeps curved petioles and thick stems inside.
    const edge = Math.min(5 * scale, w / 4, h / 4)
    const insideX = (value) => Math.max(edge, Math.min(w - edge, value))
    const insideY = (value) => Math.max(edge, Math.min(h - edge, value))
    x = insideX(x)
    y = insideY(y)
    const length = Math.max(1, Math.hypot(x - from.x, y - from.y))
    const arm = length * 0.37
    const ax = insideX(from.x + arm * Math.cos(startAngle)),
      ay = insideY(from.y + arm * Math.sin(startAngle))
    const bx = insideX(x - arm * Math.cos(endAngle)),
      by = insideY(y - arm * Math.sin(endAngle))
    const d = `M${from.x} ${from.y} C${ax} ${ay} ${bx} ${by} ${x} ${y}`
    const node = svg(stems, 'path', {
      d,
      pathLength: 1,
      'stroke-width': width,
      'stroke-dasharray': 1,
      'stroke-dashoffset': 1,
    })
    const span = length * speed
    schedule.push({ node, start: from.time, span })
    return (t) => {
      const u = 1 - t
      const dx = u * u * (ax - from.x) + 2 * u * t * (bx - ax) + t * t * (x - bx)
      const dy = u * u * (ay - from.y) + 2 * u * t * (by - ay) + t * t * (y - by)
      return {
        x: u ** 3 * from.x + 3 * u * u * t * ax + 3 * u * t * t * bx + t ** 3 * x,
        y: u ** 3 * from.y + 3 * u * u * t * ay + 3 * u * t * t * by + t ** 3 * y,
        angle: Math.atan2(dy, dx),
        time: from.time + t * span,
      }
    }
  }

  // A stem carries the plant it grows: the leaves on it are that plant's, and so are any
  // branch, twig or flower that starts from one of its points.
  function spine(sp, from, x, y, bow, thickness) {
    const angle = Math.atan2(y - from.y, x - from.x)
    const curve = shoot(from, x, y, angle + bow, angle - bow, thickness * scale, 0.72)
    // A tapered ribbon gives the principal vine weight near its root.
    // Reveal it with the same animated centreline as the finer branches.
    const reveal = schedule[schedule.length - 1].node
    const masks = svg(drawing, 'defs', {})
    const id = 'stem-mask-' + schedule.length
    const pad = thickness * scale * 2
    const mask = svg(masks, 'mask', {
      id,
      maskUnits: 'userSpaceOnUse',
      x: -pad,
      y: -pad,
      width: w + pad * 2,
      height: h + pad * 2,
    })
    mask.append(reveal)
    reveal.setAttribute('stroke', 'white')
    reveal.setAttribute('fill', 'none')
    reveal.setAttribute('stroke-width', 3 * pad)
    reveal.setAttribute('stroke-linecap', 'round')
    const left = [],
      right = []
    for (let i = 0; i <= 60; i++) {
      const t = i / 60,
        p = curve(t),
        radius = thickness * scale * (0.89 - 0.72 * t)
      const nx = -Math.sin(p.angle) * radius,
        ny = Math.cos(p.angle) * radius
      left.push([p.x + nx, p.y + ny])
      right.push([p.x - nx, p.y - ny])
    }
    svg(stems, 'path', {
      d:
        'M' +
        left
          .concat(right.reverse())
          .map((p) => p.join(' '))
          .join(' L') +
        'Z',
      stroke: 'none',
      fill: '#19276f',
      mask: 'url(#' + id + ')',
    })
    const count = Math.max(3, Math.ceil(Math.hypot(x - from.x, y - from.y) / (56 * scale)))
    for (let j = 1; j <= count; j++) {
      const p = curve(j / count)
      p.sp = sp
      anchors.push(p)
      if (j % 2 === 1 && j < count) {
        organ(
          foliage,
          leafOf(sp),
          p,
          p.angle * degrees + 90 + (j % 4 === 1 ? -1 : 1) * random(36, 61),
          random(0.74, 1.43) * scale,
        )
      }
    }
    return curve
  }

  // The four main stems take the slots a document's pool keeps for them: the two heroes,
  // the monocot, and a spray on the two short stems at the foot and the head.
  const hero = species[0],
    second = species[1],
    monocot = species[4],
    sprayer = species[2]
  const upright = spine(hero, root, random(0.09, 0.23) * w, 12 * scale, random(0.29, 0.61), 3.1)
  const lower = spine(
    second,
    upright(random(0.1, 0.23)),
    w - 12 * scale,
    h * random(0.54, 0.72),
    random(0.12, 0.43),
    2.65,
  )
  const upper = spine(
    monocot,
    upright(random(0.47, 0.66)),
    w * random(0.9, 0.98),
    h * random(0.04, 0.13),
    random(0.1, 0.37),
    2.35,
  )
  spine(sprayer, lower(0.48), w * random(0.72, 0.9), h - 12 * scale, random(-0.5, -0.18), 1.6)
  spine(sprayer, upper(0.57), w * random(0.56, 0.77), 12 * scale, random(0.28, 0.65), 1.4)

  function nearest(x, y) {
    let best = Infinity,
      chosen = root
    for (const p of anchors) {
      const dx = x - p.x,
        dy = y - p.y
      const angle = Math.atan2(dy, dx)
      const cost = Math.hypot(dx, dy) * (1.18 - 0.18 * Math.cos(angle - p.angle))
      if (cost < best) {
        best = cost
        chosen = p
      }
    }
    return chosen
  }

  // A twig takes the plant of the stem point it springs from; what grows on it is that
  // plant's, so the four plants keep to their own places.
  function twig(x, y, width) {
    const base = nearest(x, y)
    const sp = base.sp
    const angle = Math.atan2(y - base.y, x - base.x)
    const turn = Math.atan2(Math.sin(base.angle - angle), Math.cos(base.angle - angle))
    const curve = shoot(base, x, y, angle + 0.7 * turn, angle + random(-0.84, 0.84), width)
    const mid = curve(0.55),
      late = curve(0.85)
    mid.sp = late.sp = sp
    anchors.push(mid, late)
    curve.sp = sp
    return curve
  }

  // A focal flower, as its plant holds it: a solitary flower or a head on the tip, a
  // cluster of two to seven along the last third of the twig.
  function displayFlower(x, y, sp, size, radius) {
    const branch = twig(x, y, 1.04 * scale)
    const n = clusterOf(sp)
    const one = size * sizeOf(sp)
    for (let k = 0; k < n; k++) {
      const at = n === 1 ? branch(1) : branch(0.62 + (0.38 * k) / (n - 1))
      organ(flowers, flowerOf(sp), at, tiltOf(sp, random), n === 1 ? one : one * 0.63)
    }
    const node = branch(0.5)
    organ(
      foliage,
      leafOf(sp),
      node,
      node.angle * degrees + 90 + random(32, 60),
      random(0.45, 0.83) * scale,
    )
    reserved.push({ x, y, r: radius })
  }

  // Stagger focal flowers across the page, reserving their space before
  // filling the openings with finer shoots. Each band has its own jitter.
  const bands = Math.max(2, Math.round(h / (250 * scale)))
  const across = Math.max(1, Math.round(w / (360 * scale)))
  for (let row = 0; row < bands; row++) {
    for (let col = 0; col < across; col++) {
      const x = ((col + random(0.18, 0.82)) * w) / across,
        y = ((row + random(0.18, 0.86)) * h) / bands
      // the document's species take turns as the focal ones; a plant that holds its
      // flowers alone or in one head is drawn larger than one in a cluster
      const sp = species[(row + col) % species.length]
      const many = clusterOf(sp) > 1
      const size = (many ? random(0.98, 1.48) : random(1.72, 2.46)) * scale
      displayFlower(x, y, sp, size, size * (many ? 31 : 28))
    }
  }
  for (const t of [0.23, 0.82]) {
    const p = upright(t)
    organ(mist, 'star', p, random(-40, 40), random(1.05, 1.63) * scale)
    reserved.push({ x: p.x, y: p.y, r: 32 * scale })
  }

  function spray(sp, point, direction, size) {
    const length = random(36, 64) * size
    // Choose an open side of the twig. Test the whole spray, not just its tip,
    // so the leaflets do not grow across the centres of the larger flowers.
    let best = -Infinity,
      bearing = direction
    for (const turn of [0, 0.55, -0.55, 1.08, -1.08]) {
      const a = direction + turn
      let room = 48 * scale
      for (const fraction of [0.38, 0.78, 1.2]) {
        const x = point.x + Math.cos(a) * length * fraction,
          y = point.y + Math.sin(a) * length * fraction
        room = Math.min(room, x, y, w - x, h - y)
        for (const disc of reserved) room = Math.min(room, Math.hypot(x - disc.x, y - disc.y) - disc.r)
      }
      const score = room - 6 * Math.abs(turn)
      if (score > best) {
        best = score
        bearing = a
      }
    }
    if (best < -6 * scale) return
    direction = bearing
    const tipX = point.x + Math.cos(direction) * length,
      tipY = point.y + Math.sin(direction) * length
    const line = shoot(
      point,
      tipX,
      tipY,
      direction + random(-0.65, 0.65),
      direction + random(-0.5, 0.5),
      0.67 * scale,
    )
    const pairs = Math.floor(random(2, 4))
    for (let j = 0; j < pairs; j++) {
      const stalk = line((j + 0.5) / pairs)
      for (const side of [-1, 1]) {
        const tilt = stalk.angle + side * random(0.46, 1.15)
        const petiole = random(7, 14) * size
        const end = shoot(
          stalk,
          stalk.x + Math.cos(tilt) * petiole,
          stalk.y + Math.sin(tilt) * petiole,
          stalk.angle,
          tilt,
          0.55 * scale,
        )(1)
        organ(foliage, leafOf(sp), end, tilt * degrees + 90, random(0.39, 0.73) * size)
      }
    }
    const end = line(1)
    reserved.push({ x: end.x, y: end.y, r: 12 * size })
    organ(foliage, leafOf(sp), end, end.angle * degrees + 90, 0.55 * size)
  }

  // Fill the whole field, while leaving clear paper around the large flowers.
  const cols = Math.max(2, Math.ceil(w / (96 * scale))),
    rows = Math.max(2, Math.ceil(h / (91 * scale)))
  const sites = []
  for (let row = 0; row < rows; row++)
    for (let col = 0; col < cols; col++) {
      sites.push({
        x: ((col + random(0.04, 0.96)) * w) / cols,
        y: ((row + random(0.04, 0.96)) * h) / rows,
        order: random(0, 1),
      })
    }
  sites.sort((a, b) => a.order - b.order)
  for (const { x, y } of sites) {
    if (reserved.some((p) => Math.hypot(x - p.x, y - p.y) < p.r)) continue
    const curve = twig(x, y, random(0.65, 1.08) * scale),
      tip = curve(1)
    const sp = curve.sp
    const choice = random(0, 1)
    // the plant of the nearest stem point fills the opening: a smaller flower of its own,
    // a leaf of its own, or a spray of its own leaflets
    if (choice < 0.48) {
      organ(flowers, flowerOf(sp), tip, tiltOf(sp, random), random(0.5, 1.0) * scale * sizeOf(sp))
    } else if (choice < 0.78) {
      organ(foliage, leafOf(sp), tip, tip.angle * degrees + 90, random(0.6, 1.09) * scale)
    } else {
      spray(sp, tip, tip.angle, random(0.8, 1.12) * scale)
    }
    if (choice < 0.78) reserved.push({ x, y, r: (choice < 0.48 ? 14 : 10) * scale })
    if (choice < 0.78 && random(0, 1) < 0.73) {
      const n = curve(random(0.27, 0.73))
      spray(sp, n, n.angle + (random(0, 1) < 0.5 ? -1 : 1) * random(0.66, 1.34), random(0.63, 0.91) * scale)
    }
  }

  if (area > 100000) {
    let p = upper(0.67),
      best = -Infinity
    for (let i = 0; i < 12; i++) {
      const candidate = upper(random(0.35, 0.85))
      const room = reserved.reduce(
        (d, r) => Math.min(d, Math.hypot(candidate.x - r.x, candidate.y - r.y) - r.r),
        Infinity,
      )
      if (room > best) {
        best = room
        p = candidate
      }
    }
    organ(flowers, 'butterfly', p, random(-39, 29), random(0.76, 1.04) * scale, 100)
    if (area > 320000) organ(flowers, 'beetle', lower(random(0.35, 0.83)), random(-60, 50), 1.25 * scale, 140)
  }
  if (mirror) plant.setAttribute('transform', `translate(${w} 0) scale(-1 1)`)
  else plant.removeAttribute('transform')
  plant.replaceChildren(drawing)
  events = schedule
  const finish = events.reduce((end, e) => Math.max(end, e.start + e.span), 0)
  for (const e of events) {
    e.start *= duration / finish
    e.span *= duration / finish
  }
}

function paint(time) {
  for (const e of events) {
    const t = time >= duration ? 1 : Math.min(1, Math.max(0, (time - e.start) / e.span))
    if (e.last === t) continue
    e.last = t
    // With reduced motion, reveal the same garden with fades in growth order.
    const amount = motion.matches ? 1 : t
    e.node.style.opacity = motion.matches ? t : 1
    if (e.scale) {
      const size = e.size * (1 - (1 - amount) ** 2)
      e.scale.setScale(size, size)
      e.node.style.visibility = t > 0 ? 'visible' : 'hidden'
    } else {
      e.node.setAttribute('stroke-dashoffset', 1 - amount)
    }
  }
}

function tick(now) {
  if (lastFrame !== null) elapsed = Math.min(duration, elapsed + now - lastFrame)
  lastFrame = now
  paint(elapsed)
  if (elapsed < duration) frame = requestAnimationFrame(tick)
}

function resume() {
  cancelAnimationFrame(frame)
  lastFrame = null
  paint(elapsed)
  if (!document.hidden && elapsed < duration) frame = requestAnimationFrame(tick)
}

function fit() {
  const rect = garden.getBoundingClientRect()
  if (!rect.width || !rect.height || (rect.width === width && rect.height === height)) return
  width = rect.width
  height = rect.height
  // Bound the amount of geometry on high-resolution and ultra-wide displays.
  const unit = Math.max(0.85, Math.sqrt((width * height) / 1150000), Math.max(width, height) / 2200)
  const w = width / unit,
    h = height / unit
  // Express the white border in screen pixels, independently of SVG scaling.
  const shortSide = Math.min(width, height)
  const paperMargin = Math.min(40, Math.max(16, shortSide * 0.035))
  // Reserve two more device-independent pixels for antialiased stroke edges.
  const margin = Math.min(paperMargin + 2, shortSide * 0.12) / unit
  garden.setAttribute('viewBox', `${-margin} ${-margin} ${w} ${h}`)
  layout(w - 2 * margin, h - 2 * margin)
  resume()
}

makeBotany(randomFrom(seed))
for (const g of botany.querySelectorAll(':scope > g[id]')) organBounds.set(g.id, g.getBBox())
fit()
new ResizeObserver(fit).observe(garden)
document.addEventListener('visibilitychange', resume)
motion.addEventListener('change', () => {
  for (const e of events) e.last = undefined
  resume()
})
