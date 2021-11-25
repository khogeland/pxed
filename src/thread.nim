import posix

type EspThread[TArg] = object
  fn: proc(arg: TArg) 
  data: TArg

proc threadProcWrapper[TArg](closure: pointer): pointer {.noconv.} =
  var thrd = cast[ptr EspThread[TArg]](closure)
  when TArg is void:
    thrd.fn()
  else:
    thrd.fn(thrd.data)

proc createThreadWithStack*[TArg](stackSize: int, tp: proc (arg: TArg), param: TArg,) =
  var pt: Pthread
  var t: EspThread[TArg]
  when TArg isnot void: t.data = param
  t.fn = tp
  var a {.noinit.}: Pthread_attr
  doAssert pthread_attr_init(addr a) == 0
  doAssert pthread_attr_setstacksize(addr a, stackSize) == 0
  if pthread_create(addr pt, addr a, threadProcWrapper[TArg], addr(t)) != 0:
    raise newException(ResourceExhaustedError, "cannot create thread")
  doAssert pthread_attr_destroy(addr a) == 0
