import tables
import opengl
import staticglfw
import constants
import ../editor/editor
#

let
  w: int32 = 128
  h: int32 = 128

var
  window: Window

var ed = initEditor[32, 32]()
var buffer: framebuffer

ed[0, 0] = 1
ed[31, 31] = 5
ed[0, 31] = 3

proc display() =
  ed.draw(buffer)
  var dataPtr = buffer[0].addr
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGB,
      GL_UNSIGNED_SHORT_5_6_5_REV, dataPtr)

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

var dataPtr = buffer[0].addr
#glPixelStorei(GL_UNPACK_LSB_FIRST, 1)
#glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
glPixelStorei(GL_UNPACK_SWAP_BYTES, 1)

glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGB,
    GL_UNSIGNED_SHORT_5_6_5, dataPtr)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
glEnable(GL_TEXTURE_2D)

while windowShouldClose(window) != 1:
  instant = {}
  pollEvents()
  ed.handleInput(pressed, instant)
  display()
