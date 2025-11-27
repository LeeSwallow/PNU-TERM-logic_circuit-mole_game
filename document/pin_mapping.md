## Game Main pin mapping

| IO | pinMap | COMBO II-DLD BASE | Description |
|----|--------|---------------------|----------------|
| clk_1mhz | M8 | FPGA_CLK4 | 1MHz clock input |
| peizo_out | Y21 | piezo | Piezo buzzer output |
| rst | k6 | KEY12 | `#` btn (reset) |
| servo_out | AA22 | SERVO_CTRL | Servo motor PWM output |
| btn_in[10] | L1 | KEY11 | 11th btn (unused) |
| btn_in[9] | L7 | KEY10 | 10th btn (start) |
| btn_in[8] | K2 | KEY09 | 9th btn (unused)  |
| btn_in[7] | J2 | KEY08 | 8th btn  |
| btn_in[6] | L5 | KEY07 | 7th btn  |
| btn_in[5] | n6 | KEY06 | 6th btn  |
| btn_in[4] | p6 | KEY05 | 5th btn  |
| btn_in[3] | N1 | KEY04 | 4th btn  |
| btn_in[2] | N4 | KEY03 | 3rd btn  |
| btn_in[1] | N8 | KEY02 | 2nd btn  |
| btn_in[0] | K4 | KEY01 | 1st btn  |
| led_out[7] | N5 | LED_D8 | 8th mole LED |
| led_out[6] | M1 | LED_D7 | 7th mole LED |
| led_out[5] | M3 | LED_D6 | 6th mole LED |
| led_out[4] | M7 | LED_D5 | 5th mole LED |
| led_out[3] | N7 | LED_D4 | 4th mole LED |
| led_out[2] | M2 | LED_D3 | 3rd mole LED |
| led_out[1] | M4 | LED_D2 | 2nd mole LED |
| led_out[0] | L4 | LED_D1 | 1st mole LED |
| seg_arr_out[7] | K5 | AR_SEG_S7 | 7-seg array digit 8 (MSB) |
| seg_arr_out[6] | K3 | AR_SEG_S6 | 7-seg array digit 7 |
| seg_arr_out[5] | K1 | AR_SEG_S5 | 7-seg array digit 6 |
| seg_arr_out[4] | L6 | AR_SEG_S4 | 7-seg array digit 5 |
| seg_arr_out[3] | G3 | AR_SEG_S3 | 7-seg array digit 4 |
| seg_arr_out[2] | G1 | AR_SEG_S2 | 7-seg array digit 3 |
| seg_arr_out[1] | H6 | AR_SEG_S1 | 7-seg array digit 2 |
| seg_arr_out[0] | H4 | AR_SEG_S0 | 7-seg array digit 1 (LSB) |
| seg_out[7] | H2 | AR_SEG_DP | 7-seg array segment dp |
| seg_out[6] | J7 | AR_SEG_G | 7-seg array segment g |
| seg_out[5] | J3 | AR_SEG_F | 7-seg array segment f |
| seg_out[4] | J1 | AR_SEG_E | 7-seg array segment e |
| seg_out[3] | E4 | AR_SEG_D | 7-seg array segment d |
| seg_out[2] | E2 | AR_SEG_C | 7-seg array segment c |
| seg_out[1] | F5 | AR_SEG_B | 7-seg array segment b |
| seg_out[0] | F1 | AR_SEG_A | 7-seg array segment a |
| led_red_out[3] | T2 | LEDR_R4 | Red LED bit 4 |
| led_red_out[2] | U1 | LEDR_R3 | Red LED bit 3 |
| led_red_out[1] | P2 | LEDR_R2 | Red LED bit 2 |
| led_red_out[0] | R3 | LEDR_R1 | Red LED bit 1 |
| led_green_out[3] | U5 | LEDR_G4 | Green LED bit 4 |
| led_green_out[2] | V1 | LEDR_G3 | Green LED bit 3 |
| led_green_out[1] | R7 | LEDR_G2 | Green LED bit 2 |
| led_green_out[0] | T6 | LEDR_G1 | Green LED bit 1 |
| led_blue_out[3] | U3 | LEDR_B4 | Blue LED bit 4 |
| led_blue_out[2] | W2 | LEDR_B3 | Blue LED bit 3 |
| led_blue_out[1] | R5 | LEDR_B2 | Blue LED bit 2 |
| led_blue_out[0] | T3 | LEDR_B1 | Blue LED bit 1 |
| lcd_data[7] | D1 | LCD_D7 | LCD data bit 0 |
| lcd_data[6] | C1 | LCD_D6 | LCD data bit 1 |
| lcd_data[5] | C5 | LCD_D5 | LCD data bit 2  |
| lcd_data[4] | A2 | LCD_D4 | LCD data bit 3  |
| lcd_data[3] | D4 | LCD_D3 | LCD data bit 4  |
| lcd_data[2] | C3 | LCD_D2 | LCD data bit 5  |
| lcd_data[1] | B2 | LCD_D1 | LCD data bit 6  |
| lcd_data[0] | A4 | LCD_D0 | LCD data bit 7  |
| lcd_rs | G6 | LCD_RS | LCD register select |
| lcd_rw | D6 | LCD_RW | LCD read/write select |
| lcd_en | A6 | LCD_EN | LCD enable signal |
---

### Test in_game_manager pin mapping

| IO | pinMap | COMBO II-DLD BASE | Description |
|----|--------|---------------------|----------------|
| clk_1mhz | M8 | FPGA_CLK4 | 1MHz clock input |
| enable | U4 | DIP_SW8 | Enable signal (DIP switch 8) |
| rst | k6 | KEY12 | `#` btn (reset) |
| gsm_stage[1] | Y1 | DIP_SW1 | Game stage bit 1 (DIP switch 1) |
| gsm_stage[0] | W3 | DIP_SW2 | Game stage bit 0 (DIP switch 2) |
| mole_pos[3] | L4 | LED_D1 | 4th mole LED |
| mole_pos[2] | M4 | LED_D2 | 3rd mole LED |
| mole_pos[1] | M2 | LED_D3 | 2nd mole LED |
| mole_pos[0] | N7 | LED_D4 | 1st mole LED |

> reverse input/output mapping for binary number to one-hot LED display

### Test sound_manager pin mapping
| IO | pinMap | COMBO II-DLD BASE | Description |
|----|--------|---------------------|----------------|
| clk_1mhz | M8 | FPGA_CLK4 | 1MHz clock input |
| peizo_out | Y21 | piezo | Piezo buzzer output |
| playing | L4 | LED_D1 | Playing output (1st mole LED) |
| rst | k6 | KEY12 | `#` btn (reset) |
| trig | K4 | KEY01 | Trigger input (1st btn) |
| snd_mode[2] | Y1 | DIP_SW1 | Sound mode bit 2 (DIP switch 1) |
| snd_mode[1] | W3 | DIP_SW2 | Sound mode bit 1 (DIP switch 2) |
| snd_mode[0] | U2 | DIP_SW3 | Sound mode bit 0 (DIP switch 3) |

### Test servo_output pin mapping
| IO | pinMap | COMBO II-DLD BASE | Description |
|----|--------|---------------------|----------------|
| clk_1mhz | M8 | FPGA_CLK4 | 1MHz clock input |
| rst | k6 | KEY12 | `#` btn (reset) |
| enable | U4 | DIP_SW8 | Enable signal (DIP switch 8) |
| timer[6] | Y1 | DIP_SW1 | Timer bit 6 (DIP switch 1) |
| timer[5] | W3 | DIP_SW2 | Timer bit 5 (DIP switch 2) |
| timer[4] | U2 | DIP_SW3 | Timer bit 4 (DIP switch 3) |
| timer[3] | T1 | DIP_SW4 | Timer bit 3 (DIP switch 4) |
| timer[2] | W4 | DIP_SW5 | Timer bit 2 (DIP switch 5) |
| timer[1] | W1 | DIP_SW6 | Timer bit 1 (DIP switch 6) |
| timer[0] | V4 | DIP_SW7 | Timer bit 0 (DIP switch 7) |
| servo_out | AA22 | SERVO_CTRL | Servo motor PWM output |


### Test text_lcd_output pin mapping
| IO | pinMap | COMBO II-DLD BASE | Description |
|----|--------|---------------------|----------------|
| clk_1mhz | M8 | FPGA_CLK4 | 1MHz clock input |
| rst | k6 | KEY12 | `#` btn (reset) |
| lcd_data[7] | D1 | LCD_D7 | LCD data bit 0 |
| lcd_data[6] | C1 | LCD_D6 | LCD data bit 1 |
| lcd_data[5] | C5 | LCD_D5 | LCD data bit 2  |
| lcd_data[4] | A2 | LCD_D4 | LCD data bit 3  |
| lcd_data[3] | D4 | LCD_D3 | LCD data bit 4  |
| lcd_data[2] | C3 | LCD_D2 | LCD data bit 5  |
| lcd_data[1] | B2 | LCD_D1 | LCD data bit 6  |
| lcd_data[0] | A4 | LCD_D0 | LCD data bit 7  |
| lcd_rs | G6 | LCD_RS | LCD register select |
| lcd_rw | D6 | LCD_RW | LCD read/write select |
| lcd_en | A6 | LCD_EN | LCD enable signal |
| state[3] | Y1 | DIP_SW1 | State bit 3 (DIP switch 1) |
| state[2] | W3 | DIP_SW2 | State bit 2 (DIP switch 2) |
| state[1] | U2 | DIP_SW3 | State bit 1 (DIP switch 3) |
| state[0] | T1 | DIP_SW4 | State bit 0 (DIP switch 4) |
| stage[1] | W4 | DIP_SW5 | Game stage bit 1 (DIP switch 5) |
| stage[0] | W1 | DIP_SW6 | Game stage bit 0 (DIP switch 6) |