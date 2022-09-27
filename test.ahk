SetFormat, Float, 0.15

formatFloat  := A_FormatFloat

cap1 := VarSetCapacity(myVar1, 8, 0)

NumPut(15.0, myVar1, 0, "Double")

int1 := NumGet(myVar1,0,"Int64")

doub1 := NumGet(myVar1,0,"Double")

cap2 := VarSetCapacity(myVar2, 8, 0)

NumPut(0x402E000000000000, myVar2, 0, "Int64")

int2 := NumGet(myVar2,0,"Int64")

doub2 := NumGet(myVar2,0,"Double")

test := myVar2