# Traits

The traits a species, a visitor, a window of tracery and a shell are sampled with, in the order
they are drawn, and what each may be fixed to: one of the names listed, or a number in the range
given (a whole number where it says so). Fix them with `\florilegiumspecies[...]`,
`\florilegiumvisitor[...]`, `\florilegiumtracery[...]`, `\florilegiumshell[...]` or a pic's `traits`
key; [the TikZ library](tikz.md#a-genome-of-your-own) shows how. `clade` and `group` follow from
the plan and the kind and are not fixed themselves.

This page is written by `tools/tikztables.lua` from `florilegium-species.lua`.

## A species

| trait | what it may be |
|---|---|
| `plan` | `borage`, `catkin`, `columbine`, `daisy`, `eudicot`, `fern`, `heath`, `iris`, `lily`, `mint`, `monocot`, `mustard`, `pea`, `rose`, `umbellifer` |
| `syndrome` | `bee`, `beetle`, `bird`, `butterfly`, `fly`, `moth`, `none`, `wind` |
| `color` | `blue`, `green`, `orange`, `pink`, `red`, `violet`, `white`, `yellow` |
| `form` | `bilabiate`, `campanulate`, `cruciform`, `funnelform`, `head`, `iris`, `lily`, `none`, `orchid`, `papilionaceous`, `rosaceous`, `rotate`, `salverform`, `spurred`, `tubular`, `urceolate` |
| `symmetry` | `bilateral`, `none`, `radial` |
| `fused` | a whole number from 0 to 1 |
| `merosity` | a whole number from 0 to 21 |
| `merovar` | a whole number from 0 to 1 |
| `petalshape` | `lanceolate`, `linear`, `none`, `oblong`, `obovate`, `orbicular`, `spatulate` |
| `petalaspect` | a number from 0.9 to 6 |
| `apex` | `acuminate`, `acute`, `bifid`, `emarginate`, `fringed`, `none`, `rounded` |
| `petalmargin` | `crenate`, `entire`, `fimbriate`, `laciniate`, `none`, `undulate` |
| `petalamp` | a number from 0 to 0.06 |
| `claw` | a number from 0 to 0.5 |
| `reflex` | a number from -80 to 30 |
| `overlap` | a number from 0 to 0.4 |
| `cup` | a number from 0 to 1 |
| `guides` | `blotch`, `dots`, `eye`, `lines`, `none` |
| `guidecount` | a whole number from 0 to 6 |
| `picotee` | a whole number from 0 to 1 |
| `corona` | `cup`, `none`, `trumpet` |
| `spurs` | `all`, `none` |
| `stamens` | `exserted`, `included`, `none` |
| `orient` | `erect`, `horizontal`, `nodding` |
| `inflo` | `catkin`, `corymb`, `cumbel`, `dichasium`, `head`, `monochasium`, `none`, `panicle`, `raceme`, `solitary`, `spike`, `thyrse`, `umbel` |
| `count` | a whole number from 0 to 80 |
| `rays` | a whole number from 0 to 20 |
| `depth` | a whole number from 0 to 3 |
| `openorder` | `base`, `center`, `none`, `outside` |
| `siderule` | `alternate`, `none`, `same` |
| `coil` | a number from 0 to 1 |
| `size` | a number from 0 to 90 |
| `compound` | `bipinnate`, `frond`, `palmate`, `pinnate`, `simple`, `trifoliate` |
| `leaflets` | a whole number from 0 to 9 |
| `leafshape` | `cordate`, `deltoid`, `elliptic`, `hastate`, `lanceolate`, `linear`, `oblong`, `obovate`, `orbicular`, `ovate`, `reniform`, `sagittate` |
| `leafaspect` | a number from 0.6 to 20 |
| `leafmargin` | `crenate`, `dentate`, `doubly`, `entire`, `lobed`, `palmatelobed`, `pinnatifid`, `serrate`, `undulate` |
| `teeth` | a whole number from 0 to 28 |
| `dissection` | a number from 0 to 0.92 |
| `leafapex` | `acuminate`, `acute`, `emarginate`, `mucronate`, `obtuse`, `rounded` |
| `leafbase` | `auriculate`, `cordate`, `cuneate`, `oblique`, `rounded`, `truncate` |
| `venation` | `arcuate`, `forked`, `palmate`, `parallel`, `pinnate` |
| `attachment` | `clasping`, `none`, `petiolate`, `sessile`, `sheathing` |
| `stipules` | `leafy`, `none`, `small` |
| `arrangement` | `alternate`, `crown`, `distichous`, `opposite`, `rosette`, `whorled` |
| `curl` | a number from -0.3 to 0.6 |
| `twist` | a number from 0 to 50 |
| `taper` | a number from 0.4 to 1 |
| `turns` | a whole number from 0 to 1 |
| `habit` | `climbing`, `erect`, `sprawling`, `woody` |
| `section` | `prickly`, `ribbed`, `round`, `square` |
| `hairy` | a whole number from 0 to 1 |
| `tendrils` | a whole number from 0 to 1 |
| `fruit` | `achene`, `berry`, `capsule`, `drupe`, `follicle`, `hip`, `legume`, `nut`, `nutlets`, `pappus`, `pome`, `samara`, `schizocarp`, `silicle`, `silique`, `spores` |
| `phenology` | a number from -0.15 to 0.15 |
| `division` | a whole number from 0 to 3 |
| `pinnae` | a whole number from 0 to 26 |
| `outline` | `deltoid`, `lanceolate`, `none`, `oblong`, `ovate` |
| `stipe` | a number from 0 to 0.4 |
| `sori` | `dots`, `lines`, `marginal`, `none` |
| `dimorphic` | a whole number from 0 to 1 |

## A visitor

| trait | what it may be |
|---|---|
| `kind` | `beetle`, `bird`, `bumblebee`, `butterfly`, `caterpillar`, `damselfly`, `dragonfly`, `hawkmoth`, `honeybee`, `hoverfly`, `hummingbird`, `ladybird`, `moth`, `snail`, `solitarybee` |
| `size` | a number from 4 to 140 |
| `tone` | a number from 0.26 to 0.5 |
| `ground` | `copper`, `dark`, `ink`, `pale` |
| `pose` | `closed`, `cross`, `curl`, `flat`, `fly`, `folded`, `glide`, `hover`, `loop`, `open`, `perch`, `rest`, `spread`, `straight`, `tent`, `visit`, `walk` |
| `apex` | `angular`, `falcate`, `pointed`, `rounded` |
| `wingedge` | `scalloped`, `smooth`, `toothed` |
| `tails` | a whole number from 0 to 2 |
| `basal` | a whole number from 0 to 1 |
| `central` | `band`, `none`, `spots` |
| `discal` | a whole number from 0 to 1 |
| `border` | `band`, `eyes`, `none`, `spots` |
| `eyes` | a whole number from 0 to 7 |
| `rings` | a whole number from 0 to 3 |
| `parafocal` | a whole number from 0 to 1 |
| `lunules` | a whole number from 0 to 2 |
| `veins` | a whole number from 0 to 1 |
| `antenna` | `clubbed`, `comb`, `elbowed`, `feathery`, `short`, `thread` |
| `bands` | a whole number from 0 to 8 |
| `hair` | a number from 0 to 1 |
| `pollen` | a whole number from 0 to 1 |
| `build` | a number from 0.1 to 0.9 |
| `paletail` | a whole number from 0 to 1 |
| `tint` | `clear`, `tinted` |
| `stigma` | a whole number from 0 to 1 |
| `pattern` | `plain`, `spots`, `stripes` |
| `spots` | a whole number from 0 to 22 |
| `spotsize` | a number from 0 to 0.2 |
| `stripes` | `back`, `none`, `side` |
| `tufts` | a whole number from 0 to 1 |
| `horn` | a whole number from 0 to 1 |
| `whorls` | a number from 3.5 to 6 |
| `expansion` | a number from 1.6 to 3.2 |
| `spire` | a number from 0.1 to 1.2 |
| `hand` | `dextral`, `sinistral` |
| `shellbands` | a whole number from 0 to 5 |
| `lip` | a whole number from 0 to 1 |
| `extension` | a number from 0.4 to 1 |
| `bill` | `conical`, `curved`, `straight` |
| `crest` | a whole number from 0 to 1 |
| `tail` | a number from 0.3 to 0.5 |
| `aperture` | a number from 0.85 to 1.3 |
| `suture` | a number from 0.15 to 0.8 |
| `sculpture` | `cords`, `ribs`, `smooth` |
| `ribs` | a whole number from 0 to 24 |
| `opencoil` | a whole number from 0 to 1 |
| `withdrawn` | a whole number from 0 to 1 |

## A window of tracery

| trait | what it may be |
|---|---|
| `kind` | `arcade`, `foil`, `headpiece`, `rose`, `window` |
| `period` | `curvilinear`, `early_english`, `flamboyant`, `geometric`, `perpendicular`, `rayonnant` |
| `masonry` | `bar`, `plate` |
| `arch` | `drop`, `equilateral`, `fourcentered`, `lancet`, `none`, `ogee`, `round`, `segmental` |
| `excess` | a number from 0 to 1.6 |
| `rise` | a number from 0 to 0.4 |
| `ogee` | a number from 0 to 0.7 |
| `shoulder` | a number from 0 to 0.25 |
| `jamb` | a number from 0 to 2.2 |
| `lights` | a whole number from 0 to 10 |
| `split` | `binary`, `center`, `flat` |
| `branch` | `Y`, `flowing`, `intersecting`, `none`, `panel`, `reticulated`, `screen`, `subarch` |
| `depth` | a whole number from 0 to 3 |
| `setdown` | a number from 0 to 0.12 |
| `bar` | a number from 0.012 to 0.03 |
| `border` | a number from 0.015 to 0.06 |
| `transoms` | a whole number from 0 to 2 |
| `figure` | `dagger`, `foiled`, `mouchettes`, `none`, `oculus`, `soufflet`, `triangle` |
| `foils` | a whole number from 0 to 8 |
| `foilshape` | `pointed`, `round` |
| `cusps` | a whole number from 0 to 4 |
| `cuspdepth` | a number from 0.12 to 0.28 |
| `orders` | a whole number from 1 to 3 |
| `hood` | `none`, `plain`, `stops` |
| `spandrel` | `blank`, `dagger`, `foliage`, `trefoil` |
| `spokes` | a whole number from 0 to 16 |
| `rings` | a whole number from 0 to 2 |
| `oculus` | a number from 0 to 0.3 |
| `tone` | a number from 0.3 to 0.5 |
| `accent` | `center`, `none`, `stops` |

## A shell

| trait | what it may be |
|---|---|
| `kind` | `ammonite`, `clam`, `cockle`, `cowrie`, `mussel`, `nautilus`, `oyster`, `scallop`, `topshell`, `turret`, `whelk` |
| `size` | a number from 12 to 220 |
| `tone` | a number from 0.28 to 0.42 |
| `ground` | `dark`, `ink`, `pale` |
| `pattern` | `bands`, `dots`, `flammules`, `none`, `rays`, `zigzags` |
| `contrast` | a number from 0 to 1 |
| `view` | `back`, `flank`, `inside`, `mouth`, `outside` |
| `preservation` | `mold`, `nacre`, `pyrite`, `shell` |
| `whorls` | a number from 3 to 15 |
| `expansion` | a number from 1.15 to 3.6 |
| `umbilicus` | a number from 0 to 0.38 |
| `spire` | a number from 0 to 6 |
| `aperture` | a number from 0.7 to 2.4 |
| `hand` | `dextral`, `sinistral` |
| `sculpture` | `branching`, `cancellate`, `cords`, `layers`, `nodes`, `ribs`, `ridges`, `smooth`, `tubercles` |
| `ribs` | a whole number from 0 to 48 |
| `cords` | a whole number from 0 to 7 |
| `ridges` | a whole number from 0 to 14 |
| `keel` | `grooved`, `keel`, `none` |
| `septa` | `ammonitic`, `ceratitic`, `goniatitic`, `none` |
| `broken` | a whole number from 0 to 1 |
| `aspect` | a number from 0.4 to 1.2 |
| `beak` | a number from 0 to 0.5 |
| `ears` | `equal`, `unequal` |
| `inflation` | a number from 0.2 to 0.8 |
| `shoulder` | `angular`, `none`, `rounded` |
| `suture` | a number from 0 to 0.7 |
| `canal` | `long`, `short` |
| `lip` | `flared`, `plain`, `thick`, `toothed` |
| `folds` | a whole number from 0 to 3 |
