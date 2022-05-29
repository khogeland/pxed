import browser
import files
import strutils
import sequtils
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

var previousViewPressed: set[ButtonInput]

proc handleInput*(pressed: set[ButtonInput], instant: set[InstantInput]) =
  var newPressed = pressed
  newPressed.excl(previousViewPressed)
  var released = previousViewPressed
  released.excl(pressed)
  previousViewPressed.excl(released)
  case view.kind
    of EditorView:
      if view.editor.handleInput(newPressed, instant):
        previousViewPressed = pressed
        view.editor.saveImage()
        view = View(
          kind: BrowserView,
          browser: initBrowser(),
        )
    of BrowserView:
      if view.browser.handleInput(newPressed, instant):
        previousViewPressed = pressed
        let preview = view.browser.getSelection()
        var path = preview.path
        var newFile = false
        var newFileSize = 32
        # this is a little ugly..... whatever........
        if path.endsWith("newfile32.tga"):
          newFile = true
        elif path.endsWith("newfile64.tga"):
          newFile = true
          newFileSize = 64
        if newFile:
          let images = toSeq(listStorageDir("images", true))
          for i in 0..10000:
            let name = $i & ".tga"
            if not(name in images):
              path = resolveStoragePath("images/" & name)
              break
          view = View(
            kind: EditorView,
            editor: initEditorNewFile(path, newFileSize, newFileSize)
          )
        else:
          # TODO inefficient, reloads image
          view = View(
            kind: EditorView,
            editor: initEditor(path),
          )

proc drawUI*(buffer: var framebuffer18) =
  case view.kind
    of EditorView:
      view.editor.draw(buffer)
    of BrowserView:
      view.browser.draw(buffer)
  drawSprites(buffer)
