import browser
import constants
import gfx/sprites
import framebuffer
import editor

type
  Editor32 = Editor[32,32]
  Editor64 = Editor[64,64]
  ViewType = enum
    Editor32View,
    Editor64View,
    BrowserView
  View = object
    case kind: ViewType
      of Editor32View:
        editor32: Editor32
      of Editor64View:
        editor64: Editor64
      of BrowserView:
        browser: Browser

var view = View(
  kind: BrowserView,
  browser: initBrowser(),
)
showBrowserSprites()

proc handleInput*(pressed: set[ButtonInput], instant: set[InstantInput]) =
  case view.kind
    of Editor32View:
      view.editor32.handleInput(pressed, instant)
    of Editor64View:
      view.editor64.handleInput(pressed, instant)
    of BrowserView:
      view.browser.handleInput(pressed, instant)

proc drawUI*(buffer: var framebuffer18) =
  case view.kind
    of Editor32View:
      view.editor32.draw(buffer)
    of Editor64View:
      view.editor64.draw(buffer)
    of BrowserView:
      view.browser.draw(buffer)
  drawSprites(buffer)
