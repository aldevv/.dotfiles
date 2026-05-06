// ======================================================
// THIS IS ONLY FOR DOCUMENTATION, THIS FILE IS NOT USED
// ======================================================


// OLED rotation enum values are flags
typedef enum {
    OLED_ROTATION_0   = 0,
    OLED_ROTATION_90  = 1,
    OLED_ROTATION_180 = 2,
    OLED_ROTATION_270 = 3, // OLED_ROTATION_90 | OLED_ROTATION_180
} oled_rotation_t;

// Initialize the OLED display, rotating the rendered output based on the define passed in.
// Returns true if the OLED was initialized successfully
bool oled_init(oled_rotation_t rotation);

// Called at the start of oled_init, weak function overridable by the user
// rotation - the value passed into oled_init
// Return new oled_rotation_t if you want to override default rotation
oled_rotation_t oled_init_user(oled_rotation_t rotation);

// Clears the display buffer, resets cursor position to 0, and sets the buffer to dirty for rendering
void oled_clear(void);

// Renders the dirty chunks of the buffer to OLED display
void oled_render(void);

// Moves cursor to character position indicated by column and line, wraps if out of bounds
// Max column denoted by 'oled_max_chars()' and max lines by 'oled_max_lines()' functions
void oled_set_cursor(uint8_t col, uint8_t line);

// Advances the cursor to the next page, writing ' ' if true
// Wraps to the begining when out of bounds
void oled_advance_page(bool clearPageRemainder);

// Moves the cursor forward 1 character length
// Advance page if there is not enough room for the next character
// Wraps to the begining when out of bounds
void oled_advance_char(void);

// Writes a single character to the buffer at current cursor position
// Advances the cursor while writing, inverts the pixels if true
// Main handler that writes character data to the display buffer
void oled_write_char(const char data, bool invert);

// Writes a string to the buffer at current cursor position
// Advances the cursor while writing, inverts the pixels if true
void oled_write(const char *data, bool invert);

// Writes a string to the buffer at current cursor position
// Advances the cursor while writing, inverts the pixels if true
// Advances the cursor to the next page, wiring ' ' to the remainder of the current page
void oled_write_ln(const char *data, bool invert);

// Pans the buffer to the right (or left by passing true) by moving contents of the buffer
// Useful for moving the screen in preparation for new drawing
// oled_scroll_left or oled_scroll_right should be preferred for all cases of moving a static
// image such as a logo or to avoid burn-in as it's much, much less cpu intensive
void oled_pan(bool left);

// Writes a PROGMEM string to the buffer at current cursor position
// Advances the cursor while writing, inverts the pixels if true
// Remapped to call 'void oled_write(const char *data, bool invert);' on ARM
void oled_write_P(const char *data, bool invert);

// Writes a PROGMEM string to the buffer at current cursor position
// Advances the cursor while writing, inverts the pixels if true
// Advances the cursor to the next page, wiring ' ' to the remainder of the current page
// Remapped to call 'void oled_write_ln(const char *data, bool invert);' on ARM
void oled_write_ln_P(const char *data, bool invert);

// Returns a pointer to the requested start index in the buffer plus remaining
// buffer length as struct
oled_buffer_reader_t oled_read_raw(uint16_t start_index);

// Writes a string to the buffer at current cursor position
void oled_write_raw(const char *data, uint16_t size);

// Writes a single byte into the buffer at the specified index
void oled_write_raw_byte(const char data, uint16_t index);

// Writes a PROGMEM string to the buffer at current cursor position
void oled_write_raw_P(const char *data, uint16_t size);

// Sets a specific pixel on or off
// Coordinates start at top-left and go right and down for positive x and y
void oled_write_pixel(uint8_t x, uint8_t y, bool on);

// Can be used to manually turn on the screen if it is off
// Returns true if the screen was on or turns on
bool oled_on(void);

// Can be used to manually turn off the screen if it is on
// Returns true if the screen was off or turns off
bool oled_off(void);

// Returns true if the oled is currently on, false if it is
// not
bool is_oled_on(void);

// Sets the brightness level of the display
uint8_t oled_set_brightness(uint8_t level);

// Gets the current brightness level of the display
uint8_t oled_get_brightness(void);

// Basically it's oled_render, but with timeout management and oled_task_user calling!
void oled_task(void);

// Called at the start of oled_task, weak function overridable by the user
void oled_task_user(void);

// Set the specific 8 lines rows of the screen to scroll.
// 0 is the default for start, and 7 for end, which is the entire
// height of the screen.  For 128x32 screens, rows 4-7 are not used.
void oled_scroll_set_area(uint8_t start_line, uint8_t end_line);

// Sets scroll speed, 0-7, fastest to slowest. Default is three.
// Does not take effect until scrolling is either started or restarted
// the ssd1306 supports 8 speeds with the delay
// listed below betwen each frame of the scrolling effect
// 0=2, 1=3, 2=4, 3=5, 4=25, 5=64, 6=128, 7=256
void oled_scroll_set_speed(uint8_t speed);

// Begin scrolling the entire display right
// Returns true if the screen was scrolling or starts scrolling
// NOTE: display contents cannot be changed while scrolling
bool oled_scroll_right(void);

// Begin scrolling the entire display left
// Returns true if the screen was scrolling or starts scrolling
// NOTE: display contents cannot be changed while scrolling
bool oled_scroll_left(void);

// Turns off display scrolling
// Returns true if the screen was not scrolling or stops scrolling
bool oled_scroll_off(void);

// Returns the maximum number of characters that will fit on a line
uint8_t oled_max_chars(void);

// Returns the maximum number of lines that will fit on the OLED
uint8_t oled_max_lines(void);
