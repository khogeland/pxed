import browser
import os
import files
import strutils
import sequtils
import constants
import gfx/sprites
import framebuffer
import editor
import msgpack4nim

type
  ViewType = enum
    EditorView,
    BrowserView
  View = object
    case kind: ViewType
      of EditorView:
        browserIndex: int
        editor: Editor
      of BrowserView:
        browser: Browser
  ViewSaveState = object
    browserIndex: int
    case kind: ViewType
      of EditorView:
        path: string
      of BrowserView: discard

var file: File
var view: View
const savePath = resolveStoragePath("current_view")

try:
  if file.open(savePath, fmRead):
    var saveState: ViewSaveState
    var buf = file.readAll()
    unpack(buf, saveState)
    case saveState.kind
    of EditorView:
      view = View(
        kind: EditorView,
        browserIndex: saveState.browserIndex,
        editor: initEditor(saveState.path)
      )
    of BrowserView:
      view = View(
        kind: BrowserView,
        browser: initBrowser(saveState.browserIndex)
      )
  else:
    view = View(
      kind: BrowserView,
      browser: initBrowser(),
    )
except:
  let e = getCurrentException()
  echo e.msg
  echo e.getStackTrace()
  view = View(
    kind: BrowserView,
    browser: initBrowser(),
  )
finally:
  file.close()
  discard tryRemoveFile(savePath)

proc saveUI*() =
  var saveState: ViewSaveState
  case view.kind
  of EditorView:
    view.editor.saveImage()
    if fileExists(view.editor.path): #in case this is a new file we didn't edit
      saveState = ViewSaveState(
        kind: EditorView,
        path: view.editor.path,
        browserIndex: view.browserIndex,
      )
    else:
      saveState = ViewSaveState(
        kind: BrowserView,
        browserIndex: view.browserIndex,
      )
  of BrowserView:
    saveState = ViewSaveState(
      kind: BrowserView,
      browserIndex: view.browser.index,
    )
  var buf = pack(saveState)
  writeFile(savePath, buf)

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
          browser: initBrowser(view.browserIndex),
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
            browserIndex: view.browser.index,
            editor: initEditorNewFile(path, newFileSize, newFileSize)
          )
        else:
          view = View(
            kind: EditorView,
            browserIndex: view.browser.index,
            editor: initEditor(path),
          )

proc drawUI*(buffer: var framebuffer18) =
  case view.kind
    of EditorView:
      view.editor.draw(buffer)
    of BrowserView:
      view.browser.draw(buffer)
  drawSprites(buffer)

