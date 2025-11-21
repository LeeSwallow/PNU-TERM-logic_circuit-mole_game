## game_state_manager module description


### game logic change flags:

- 4'b0000: no change
- 4'b0001: increment score
- 4'b0010: decrement life
- 4'b0100: pause timer countdown
- 4'b0101: resume timer countdown

### state change flags:

- 4'b1000: to ready
- 4'b1010: to playing(from ready)
- 4'b1100: to stage clear(from playing)
- 4'b1101: to game over(from playing)
- 4'b1110: to game clear(from playing)

### state definitions:
- 3'b000: ready
- 3'b001: playing
- 3'b010: paused
- 3'b011: game over
- 3'b100: stage clear
- 3'b101: game clear

## in_game_manager module description

### mole_show(mapped to 8 leds)
- 4'b0000: no mole
- 4'b0001: 1st mole
- 4'b0010: 2nd mole
- 4'b0011: 3rd mole
- 4'b0100: 4th mole
- 4'b0101: 5th mole
- 4'b0110: 6th mole
- 4'b0111: 7th mole
- 4'b1000: 8th mole


## sound_manager module description

### sound effects codes
- idle : [end] -> [b'1111]
- BEEP : [D4, end] -> [b'0010, b'1111]
- start_beep : [C5, end] -> [b'1000, b'1111]
- hit: [C4, G4, end] -> [b'0001, b'0101, b'1111]
- miss: [E4, sleep, E4, end] -> [b'0011, b'0000, b'0011, b'1111]
- win: [C4, E4, G4, C5, end] -> [b'0001, b'0011, b'0101, b'1000, b'1111]
- gameover: [C5, G4, E4, C4, end] -> [b'1000, b'0101, b'0011, b'0001, b'1111]
- game_clear: [C4, E4, G4, sleep,  F4, A4, C5, end] -> [b'0001, b'0011, b'0101, b'0000, b'0010, b'0100, b'1000,b'1111]

