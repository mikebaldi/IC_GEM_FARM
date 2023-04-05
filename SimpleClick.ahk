#SingleInstance, Force
SendMode Input

msgbox, Move Mouse to click location and press enter when ready.
i := 0
loop
{
    click
    sleep, 1000
    i++
}

#p::
Pause
return