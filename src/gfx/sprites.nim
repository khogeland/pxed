import framebuffer
import constants
import color
import tables
import image
import files

type Sprite* = ref object
  id*: int
  x*, y*, w*, h*: int
  visible*: bool
  contents*: seq[uint8]
  palette*: int
  factor*: int

type Palette* = ref object
  id*: int
  p*: array[256, RGB18Color]

# z-order is just insertion order
var sprites: OrderedTable[int, Sprite]
var palettes: Table[int, array[256, RGB18Color]]
var composite: framebuffer18
var mask: array[BUFFER_LENGTH, bool]
var idN: int = 0
var modified = true

#this api might be a little stupid

proc addPalette*(p: array[256, RGB18Color]): int =
  let id = idN
  idN += 1
  palettes[id] = p
  return id

proc updatePalette*(palette: int, a: array[256, RGB18Color]): void =
  modified = true
  palettes[palette] = a

proc addSprite*(x, y, w, h, factor, palette: int, contents: seq[uint8]): Sprite =
  let id = idN
  idN += 1
  result = Sprite(
    id: id,
    palette: palette,
    x: x, y: y, w: w, h: h,
    contents: contents,
    factor: factor,
    visible: false,
  )
  sprites[id] = result

proc loadImage*(x, y, factor: int, path: string): Sprite =
  let img18 = readTGA(openResourceStream("sprites/" & path)).img18
  let palette = addPalette(img18.palette)
  return addSprite(x, y, img18.w, img18.h, factor, palette, img18.contents)

proc move*(s: var Sprite, x, y: int): void =
  s.x = x
  s.y = y
  modified = true

proc removeSprite*(s: Sprite): void =
  sprites.del(s.id)

proc clearSprites*(): void =
  sprites = OrderedTable[int, Sprite]()

proc clearPalettes*(): void =
  palettes = Table[int, array[256, RGB18Color]]()

proc show*(s: var Sprite): void =
  s.visible = true

proc hide*(s: var Sprite): void =
  s.visible = false

proc updateComposite(): void =
  for i in 0..BUFFER_LENGTH-1:
    composite[i] = rgb(0,0,0)
    mask[i] = false
  for sprite in sprites.values():
    if not sprite.visible:
      continue
    for y in 0..sprite.h-1:
      for x in 0..sprite.w-1:
        let i = (sprite.w*y)+x
        if sprite.contents[i] == 0:
          continue
        let color = palettes[sprite.palette][sprite.contents[i]]
        let ssX0 = (x*sprite.factor) + sprite.x
        let ssY0 = (y*sprite.factor) + sprite.y
        for cy in ssY0..ssY0+sprite.factor-1:
          for cx in ssX0..ssX0+sprite.factor-1:
            if cx < 0 or cx > SCREEN_WIDTH-1 or cy < 0 or cy > SCREEN_HEIGHT-1:
              continue
            let screenIdx = (cy*SCREEN_WIDTH)+cx
            composite[screenIdx] = color
            mask[screenIdx] = true

proc drawSprites*(fb: var framebuffer18): void =
  if modified:
    updateComposite()
  for i in 0..BUFFER_LENGTH-1:
    if mask[i]:
      fb[i] = composite[i]
