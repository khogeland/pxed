import browser
import constants
import gfx/sprites
import framebuffer
import editor

type
  ViewType = enum
    EditorView,
    BrowserView
  View = object
    case kind: ViewType
      of EditorView:
        editor: Editor
      of BrowserView:
        browser: Browser

var view = View(
  kind: BrowserView,
  browser: initBrowser(),
)

proc handleInput*(pressed: set[ButtonInput], instant: set[InstantInput]) =
  case view.kind
    of EditorView:
      if view.editor.handleInput(pressed, instant):
        view.editor.saveImage()
        view = View(
          kind: BrowserView,
          browser: initBrowser(),
        )
    of BrowserView:
      if view.browser.handleInput(pressed, instant):
        let preview = view.browser.getSelection()
        # TODO inefficient, reloads image
        view = View(
          kind: EditorView,
          editor: initEditor(preview.path),
        )

proc drawUI*(buffer: var framebuffer18) =
  case view.kind
    of EditorView:
      view.editor.draw(buffer)
    of BrowserView:
      view.browser.draw(buffer)
  drawSprites(buffer)
