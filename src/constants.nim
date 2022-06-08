const
  SCREEN_HEIGHT* = 128
  SCREEN_WIDTH* = 128
  #SCREEN_HEIGHT_2* = 64
  #SCREEN_WIDTH_2* = 96

type u6* = distinct uint8

func max*(a, b: u6): u6 = max(uint8(a), uint8(b)).u6
func min*(a, b: u6): u6 = min(uint8(a), uint8(b)).u6
func `==`*(a, b: u6): bool = uint8(a) == uint8(b)

type ButtonInput* = enum
  E_Up
  E_Down
  E_Left
  E_Right
  E_A
  E_B
  E_X
  E_Y

type InstantInput* = enum
  E_ScrollUp
  E_ScrollDown
  E_ScrollRight
  E_ScrollLeft

