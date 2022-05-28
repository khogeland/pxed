import files
#import gfx/sprites
import gfx/image
import tables
import opengl
import staticglfw
import framebuffer
import constants
#import ui/editor
#import ui/browser
import ui/boss

let
  w: int32 = 128
  h: int32 = 128

var
  window: Window

#var ed = initEditor[32, 32]()
var buffer: framebuffer18
var glBuffer: array[SCREEN_HEIGHT * SCREEN_WIDTH * 3, uint8]
for i in 0..len(glBuffer)-1:
  glBuffer[i] = 0xFF

#ed[0, 0] = 1
#ed[31, 31] = 5
#ed[0, 31] = 3

proc fbToGL*(fb: framebuffer18): array[SCREEN_HEIGHT*SCREEN_WIDTH*3, uint8] =
  var i = 0
  for pixel in fb:
    result[i] = uint8(pixel.r)*4
    result[i+1] = uint8(pixel.g)*4
    result[i+2] = uint8(pixel.b)*4
    i += 3

proc display() =
  drawUI(buffer)
  #ed.draw(buffer)
  glBuffer = fbToGl(buffer)
  var dataPtr = glBuffer[0].addr
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGB,
      GL_UNSIGNED_BYTE, dataPtr)

  # draw a quad over the whole screen
  glClear(GL_COLOR_BUFFER_BIT)
  glBegin(GL_QUADS)
  glTexCoord2d(0.0, 0.0); glVertex2d(-1.0, -1.0)
  glTexCoord2d(1.0, 0.0); glVertex2d(+1.0, -1.0)
  glTexCoord2d(1.0, 1.0); glVertex2d(+1.0, +1.0)
  glTexCoord2d(0.0, 1.0); glVertex2d(-1.0, +1.0)
  glEnd()

  swapBuffers(window)

if init() == 0:
  quit("Failed to Initialize GLFW.")

var pressed: set[ButtonInput]
var instant: set[InstantInput]

const GLMap = {
  KEY_UP: E_Up,
  KEY_DOWN: E_Down,
  KEY_LEFT: E_Left,
  KEY_RIGHT: E_Right,
  KEY_Z: E_A,
  KEY_X: E_B,
  KEY_A: E_X,
  KEY_S: E_Y,
}.toTable

proc keyProc(window: Window, key: cint, scancode: cint, action: cint, modifiers: cint) =
  if key == KEY_ESCAPE and action == PRESS:
    window.setWindowShouldClose(1)
  if key in GLMap:
    let ekey = GLMap[key]
    if action == PRESS:
      pressed.incl(ekey)
    elif action == RELEASE:
      pressed.excl(ekey)

proc scrollProc(window: Window, xoffset: cdouble, yoffset: cdouble) =
  if xoffset > 0.4:
    instant.incl(E_ScrollRight)
  elif xoffset < -0.4:
    instant.incl(E_ScrollLeft)
  # depends on natural scroll direction. whatever.
  if yoffset < -0.4:
    instant.incl(E_ScrollUp)
  elif yoffset > 0.4:
    instant.incl(E_ScrollDown)

windowHint(RESIZABLE, false.cint)
window = createWindow(w.cint, h.cint, "pxed", nil, nil)

discard window.setKeyCallback(cast[KeyFun](keyProc))
discard window.setScrollCallback(cast[ScrollFun](scrollProc))
makeContextCurrent(window)
loadExtensions()

var dataPtr = glBuffer[0].addr
#glPixelStorei(GL_UNPACK_LSB_FIRST, 1)
#glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
#glPixelStorei(GL_UNPACK_SWAP_BYTES, 1)

glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGB,
    GL_UNSIGNED_BYTE, dataPtr)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
glEnable(GL_TEXTURE_2D)

#let pointerSprite = loadImage(20, 20, 2, "resources/pointer.tga")

#var st: FileStream
#if openStorageStream("current_image.tga", st):
  #try:
    #ed.loadTGA(readTGA(st))
  #finally:
    #st.close()

try:
  while windowShouldClose(window) != 1:
    instant = {}
    pollEvents()
    handleInput(pressed, instant)
    #let st = openStorageStream("current_image.tga", fmWrite)
    #try:
      #st.writeTGA(ed.toTGA())
    #finally:
      #st.close()
    display()
except:
  # I have no idea why Nim refuses to print stack traces, so...
  let e = getCurrentException()
  echo e.msg
  echo e.getStackTrace()
