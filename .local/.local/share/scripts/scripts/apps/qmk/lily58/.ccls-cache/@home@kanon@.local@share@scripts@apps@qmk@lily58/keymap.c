#include QMK_KEYBOARD_H

#include "sendstring_latam_colemak.h"
/* CM_O */
/* https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/sendstring_colemak.h */

/* latam colemak is LCM, default colemak is CM */
#include "latam_colemak.h"
/* #include "keymap_colemak.h" */
// CM_0
//https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/keymap_colemak.h

#include "keymap_spanish.h"
// ES_0
//https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/keymap_spanish.h

#ifdef PROTOCOL_LUFA
  #include "lufa.h"
  #include "split_util.h"
#endif
#ifdef SSD1306OLED
  #include "ssd1306.h"
#endif

//TODO PERMISSIVE HOLD
//https://beta.docs.qmk.fm/using-qmk/software-features/tap_hold
//
//TODO emojis
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_unicode
//
//TODO layers
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers
//
//TODO AUTO SHIFT
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_auto_shift
//
//TODO DYNAMIC MACROS
//https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_dynamic_macros
//
//TODO MOUSE KEYS
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_pointing_device
//https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_mouse_keys
//TODO OLED (NOT READ YET)
//TODOhttps://beta.docs.qmk.fm/using-qmk/hardware-features/displays/feature_oled_driver

extern uint8_t is_master;

// macros
enum my_macros {
    WK1 = SAFE_RANGE,
    WK2,
    WK3,
    WK4,
    WK5,
    WK6,
    WK7,
    WK8,
    WK9,
    WK0,
    COMM_SPC,
    SCLN_END,
    COLN_END,
    CAPS_EMU,
};

enum layer_number {
  _COLEMAK = 0,
  _LOWER,
  _RAISE,
  _ADJUST,
};

// you need to add the combo count to config.h each time you add a combo
//
// you can toggle them by defining to a key CMB_TOG
enum combos {
  ZQ_CAPS,
  JK_TAB,
   ZC_COPY,
  XV_PASTE,
};

const uint16_t PROGMEM zq_combo[] = {KC_Z, KC_Q, COMBO_END};
const uint16_t PROGMEM jk_combo[] = {LCM_J, LCM_K, COMBO_END};
const uint16_t PROGMEM copy_combo[] = {KC_Z, KC_C, COMBO_END};
const uint16_t PROGMEM paste_combo[] = {KC_X, KC_V, COMBO_END};

void process_combo_event(uint16_t combo_index, bool pressed) {
  switch(combo_index) {
    case ZC_COPY:
      if (pressed) {
        tap_code16(LCTL(KC_C));
      }
      break;
    case XV_PASTE:
      if (pressed) {
        tap_code16(LCTL(KC_V));
      }
      break;
  }
}

combo_t key_combos[COMBO_COUNT] = {
  [ZQ_CAPS] = COMBO(zq_combo, KC_CAPS),
  [JK_TAB] = COMBO(jk_combo, KC_TAB),
  [ZC_COPY] = COMBO_ACTION(copy_combo),
  [XV_PASTE] = COMBO_ACTION(paste_combo),
};

typedef struct {
    bool is_press_action;
    uint8_t state;
} tap;

// optional, for the most advanced use cases
enum {
    SINGLE_TAP = 1,
    SINGLE_HOLD,
    DOUBLE_TAP,
    DOUBLE_HOLD,
    DOUBLE_SINGLE_TAP, // Send two single taps
    TRIPLE_TAP,
    TRIPLE_HOLD
};

// Tap dance enums
enum {
    X_CTL,
    TD_DC, // . -> :
    TD_CS, // , -> ;
    TD_CIRC_PLUS, // ¿ -> par
    TD_CLOSE_RELOAD,
    TD_PAR, // ¿ -> par
    TD_PLUS, // - -> +
};

//https://beta.docs.qmk.fm/using-qmk/software-features/feature_tap_dance
// for every tap dance, make one of these
uint8_t cur_dance(qk_tap_dance_state_t *state);
void dc_finished(qk_tap_dance_state_t *state, void *user_data);
void dc_reset(qk_tap_dance_state_t *state, void *user_data);
void cs_finished(qk_tap_dance_state_t *state, void *user_data);
void cs_reset(qk_tap_dance_state_t *state, void *user_data);
void web_finished(qk_tap_dance_state_t *state, void *user_data);
void web_reset(qk_tap_dance_state_t *state, void *user_data);
void CIRC_PLUS(qk_tap_dance_state_t *state, void *user_data);

/* ========= */
/* MODS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/mod_tap */
/* for left control and shift when holding but esc when tapping */
/* MT(MOD_LCTL | MOD_LSFT, KC_ESC) */
/* there are also shortcuts for these */
/* LALT_T(kc) */

//space cadets (shift taps) are in config.h

/* ========= */
/* LAYERS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers */
/* OSL avtivates mapping until next key is pressed */
/* ========= */
/* MAPPINGS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/simple-keycodes/keycodes_basic */
/* https://en.wikipedia.org/wiki/QWERTY#/media/File:KB_United_States.svg */
/* KC_BSLS = } */
/* KC_MINS = ' */
/* KC_RALT = RIGHTALT  */
/* KC_ALGR = Alt-gr  */
/* KC_NUBS = <  */
/* KC_LSPO = LEFT SHIFT WHEN HOLD, ( WHEN TAPPED */
/* KC_RSPC = right SHIFT WHEN HOLD, ) WHEN TAPPED */
/* KC_LEAD = leaderkey  */
/* create macro for \ */

//https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

/* QWERTY
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * | ESC  |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  |  ~   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   E  |   R  |   T  |                    |   Y  |   U  |   I  |   O  |   P  |  -   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |LCTRL |   A  |   S  |   D  |   F  |   G  |-------.    ,-------|   H  |   J  |   K  |   L  |   ;  |  '   |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |LShift|   Z  |   X  |   C  |   V  |   B  |-------|    |-------|   N  |   M  |   ,  |   .  |   /  |RShift|
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */

 // OSL() layer for one keypress
 // TG() toggles layer

 [_COLEMAK] = LAYOUT( \
  CAPS_EMU,   WK1,    WK2,     WK3,     WK4,      WK5,                     WK6,     WK7,       WK8,     WK9,      WK0,    LGUI(LCM_W), \
  KC_TAB,   LCM_Q,   LCM_W,    LCM_F,    LCM_P,    LCM_G,               LCM_J,    LCM_L,    LCM_U,    LCM_Y,    LCM_NTIL, KC_LBRC, \
  KC_ESC, LCM_A,   LCM_R,    LCM_S,    LCM_T,    LCM_D,                 LCM_H,    LCM_N,    LCM_E,    LCM_I,    LCM_O, LCM_QUOT, \
  KC_LSPO,  LCM_Z,   LCM_X,    LCM_C,    LCM_V,    LCM_B, LCM_BSLS,   KC_LEAD, LCM_K,    LCM_M,    LCM_COMM, LCM_DOT,  LCM_MINS, KC_RSPC,\
              KC_LGUI, OSL(_RAISE), LALT_T(KC_ENT), CTL_T(KC_DEL),   KC_BSPC, LT(_LOWER,KC_SPC), ROPT_T(KC_F5), TG(_RAISE) \
),

 /* /1* [_QWERTY] = LAYOUT( \ */
 /*  KC_ESC,   KC_1,   KC_2,    KC_3,    KC_4,    KC_5,                     KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_GRV, \ */
 /*  KC_TAB,   KC_Q,   KC_W,    KC_E,    KC_R,    KC_T,                     KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_MINS, \ */
 /*  KC_LCTRL, KC_A,   KC_S,    KC_D,    KC_F,    KC_G,                     KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT, \ */
 /*  KC_LSFT,  KC_Z,   KC_X,    KC_C,    KC_V,    KC_B, KC_LBRC,  KC_RBRC,  KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH,  KC_RSFT, \ */
 /*              MO(_LOWER),KC_LGUI, KC_LALT, LT(_LOWER,KC_SPC),  LT(_RAISE,KC_ENT),  KC_BSPC, KC_RGUI, MO(_RAISE) \ */
/* ), */
/* LOWER
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |   !  |   @  |   #  |   $  |   %  |                    |   ^  |   &  |   *  |   (  |   )  |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |   1  |   2  |   3  |   4  |   5  |-------.    ,-------|   6  |   7  |   8  |   9  |   0  |      |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|   |  |   `  |   +  |   {  |   }  |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */
[_LOWER] = LAYOUT( \
  _______, _______, _______, _______, _______, _______,                          _______, _______, _______,_______, _______, _______,\
  _______, KC_EXLM, KC_AT,   KC_HASH, KC_DLR,  KC_PERC,                          KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, LCM_GRV, \
  _______, KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                             KC_6,    KC_7,    KC_8,    KC_9,    KC_0,  LCM_IQUE, \
  _______, LCM_LABK, LCM_AT, LCM_RABK, LCM_CIRC, LCM_TILD, _______,    _______, LCM_BSLS, LCM_PIPE, COMM_SPC, LCM_DOT , LCM_PLUS, _______, \
                             _______, _______, _______, _______,                  _______,  _______, _______, _______\
),
/* RAISE
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |                    |  F7  |  F8  |  F9  | F10  | F11  | F12  |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------.    ,-------|      | Left | Down |  Up  |Right |      |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|   +  |   =  |   [  |   ]  |   \  |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */

[_RAISE] = LAYOUT( \
          _______, _______, _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, \
        KC_PSCREEN,   KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,                           KC_F6,   KC_F7,   KC_F8,   KC_F9,  KC_F10,  LSFT(KC_PSCREEN), \
           KC_CAPS, KC_BRID, KC_BRIU, KC_MUTE, KC_VOLD, KC_VOLU,                         KC_LEFT, KC_DOWN, KC_UP, KC_RGHT,  KC_F11, KC_F12, \
  _______, XXXXXXX, KC_MEDIA_SELECT, KC_MEDIA_PLAY_PAUSE, LALT(KC_F4),_______,_______,  _______, XXXXXXX, KC_LALT,  SCLN_END, COLN_END, _______, _______, \
                             _______, _______, _______,  _______,               _______, RCTL_T(KC_SPC),  LT(_ADJUST,KC_SPC), _______ \
),

/* ADJUST
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------.    ,-------|      |      |      |      |      |      |
 * |------+------+------+------+------+------|       |    |       |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|      |      |      |      |      |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `----------------------------'           '------''--------------------'
 */
  [_ADJUST] = LAYOUT( \
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,                   XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, \
  XXXXXXX, KC_POWER, KC_HELP, XXXXXXX, XXXXXXX, XXXXXXX,                   XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, \
  XXXXXXX, LCM_A, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,         KC_HOME, KC_PGDOWN, KC_PGUP, KC_END, XXXXXXX, KC_LSFT, \
  _______, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, _______,\
                             _______, _______, _______, _______, _______,  _______, _______, _______ \
  )
};


// Setting ADJUST layer RGB back to default
void update_tri_layer_RGB(uint8_t layer1, uint8_t layer2, uint8_t layer3) {
  if (IS_LAYER_ON(layer1) && IS_LAYER_ON(layer2)) {
    layer_on(layer3);
  } else {
    layer_off(layer3);
  }
}

//SSD1306 OLED update loop, make sure to enable OLED_ENABLE=yes in rules.mk
#ifdef OLED_ENABLE

oled_rotation_t oled_init_user(oled_rotation_t rotation) {
    if (!is_keyboard_master()) {
      // for left master exchange the return values
        return OLED_ROTATION_180;
      }
        return rotation;
}
// When you add source files to SRC in rules.mk, you can use functions.
const char *read_layer_state(void);
const char *read_logo(void);
void set_keylog(uint16_t keycode, keyrecord_t *record);
const char *read_keylog(void);
const char *read_keylogs(void);

// const char *read_mode_icon(bool swap);
// const char *read_host_led_state(void);
// void set_timelog(void);
// const char *read_timelog(void);
bool oled_task_user(void) {
  if (is_keyboard_master()) {
    // If you want to change the display of OLED, you need to change here
    oled_write_ln(read_layer_state(), false);
    oled_write_ln(read_keylog(), false);
    oled_write_ln(read_keylogs(), false);
    //oled_write_ln(read_mode_icon(keymap_config.swap_lalt_lgui), false);
    //oled_write_ln(read_host_led_state(), false);
    //oled_write_ln(read_timelog(), false);
  } else {
    oled_write(read_logo(), false);
  }
    return false;
}
#endif // OLED_ENABLE

/* check the alt tab advanced to see fun stuff */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_macros */

/* you can use timers */

/* Software Timers */

/* It's possible to start timers and read values for time-specific events. Here's an example: */

/* static uint16_t key_timer; */
/* key_timer = timer_read(); */
/* ​ */
/* if (timer_elapsed(key_timer) < 100) { */
/*   // do something if less than 100ms have passed */
/* } else { */
/*   // do something if 100ms or more have passed */
/* } */

/* for colemak: #include "sendstring_colemak.h" */

/* There's also a couple of mod shortcuts you can use: */
/* SS_LCTL(string) */
/* SS_LSFT(string) */
/* SS_LALT(string) or SS_LOPT(string) */
/* SS_LGUI(string), SS_LCMD(string) or SS_LWIN(string) */
/* SS_RCTL(string) */
/* SS_RSFT(string) */
/* SS_RALT(string), SS_ROPT(string) or SS_ALGR(string) */
/* SS_RGUI(string), SS_RCMD(string) or SS_RWIN(string) */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_macros */

// MY HOLD AND TAP TIMINGS
uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case LALT_T(KC_ENT):
            return TAPPING_TERM - 10;

        /* case TD(TD_PLUS): */
        /*     return TAPPING_TERM + 40; */

        case KC_LSPO:
            return TAPPING_TERM - 20;
        case KC_RSPC:
            return TAPPING_TERM - 50;
        case LT(_LOWER,KC_SPC):
            return TAPPING_TERM - 10;

        /* case TD(TD_HTTP_TYPE): */
        /*     return TAPPING_TERM + 50; */
        /* case LT(1, KC_GRV): */
        /*     return 130; */
        default:
            return TAPPING_TERM;
    }
}

// MY SIMPLE MACROS
bool is_caps_emu_active = false;
uint16_t key_timer;
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  if (record->event.pressed) {
#ifdef OLED_ENABLE
    set_keylog(keycode, record);
#endif
    // set_timelog();

        switch (keycode) {
            case WK1:
                SEND_STRING(SS_LGUI("1"));
                return false; // Skip all further processing of this key
            case WK2:
                SEND_STRING(SS_LGUI("2"));
                return false; // Skip all further processing of this key
            case WK3:
                SEND_STRING(SS_LGUI("3"));
                return false; // Skip all further processing of this key
            case WK4:
                SEND_STRING(SS_LGUI("4"));
                return false; // Skip all further processing of this key
            case WK5:
                SEND_STRING(SS_LGUI("5"));
                return false; // Skip all further processing of this key
            case WK6:
                SEND_STRING(SS_LGUI("6"));
                return false; // Skip all further processing of this key
            case WK7:
                SEND_STRING(SS_LGUI("7"));
                return false; // Skip all further processing of this key
            case WK8:
                SEND_STRING(SS_LGUI("8"));
                return false; // Skip all further processing of this key
            case WK9:
                SEND_STRING(SS_LGUI("9"));
                return false; // Skip all further processing of this key
            case WK0:
                SEND_STRING(SS_LGUI("0"));
                return false; // Skip all further processing of this key
            case COMM_SPC:
                SEND_STRING(", ");
                return false; // Skip all further processing of this key
            case SCLN_END:
                tap_code16(KC_END);
                tap_code16(LCM_SCLN);
                return false; // Skip all further processing of this key
            case COLN_END:
                tap_code16(KC_END);
                tap_code16(LCM_COLN);
                return false; // Skip all further processing of this key
          case CAPS_EMU:
                if (!is_caps_emu_active) {
                  register_code16(KC_LSFT);
                  is_caps_emu_active = true;
                } else {
                  unregister_code16(KC_LSFT);
                  is_caps_emu_active = false;
                }
                return false;
                /* case KC_ENTER: */
                // Play a tone when enter is pressed
                /* PLAY_SONG(tone_qwerty); */
                /* return true; // Let QMK send the enter press/release events */
            default:
                return true; // Process all other keycodes normally
        }
  }
  return true;
}

// ============
// LEADER KEY
// ============
// for colemak codes
LEADER_EXTERNS();

void matrix_scan_user(void) {
    LEADER_DICTIONARY() {
      leading = false;
      leader_end();

    SEQ_ONE_KEY(LCM_M) {
        SEND_STRING("255.255.255.");
    }

    SEQ_ONE_KEY(LCM_H) {
        SEND_STRING("https:" SS_LSFT("77"));
    }
    SEQ_TWO_KEYS(KC_LSPO, LCM_H) {
        SEND_STRING("https:" SS_LSFT("77") "github.com" SS_LSFT("7"));
    }

      /* register_code(KC_LGUI); */
      /* register_code(KC_S); */
      /* unregister_code(KC_S); */
      /* unregister_code(KC_LGUI) */
    SEQ_ONE_KEY(KC_LEAD) {
        /* SEND_STRING(); */
        SEND_STRING("jbernal" SS_ALGR("2") "unal.edu.co");
    }
    SEQ_ONE_KEY(LCM_C) {
        //TEMPORAL
        // setxkbmap latam -variant colemak
        SEND_STRING("rfgxebma" SS_TAP(X_P) " iagam " SS_TAP(X_MINS) "vapuakg cyifmae\n");

    }
    SEQ_TWO_KEYS(KC_RSPC, LCM_C) {
        //PERMANENT
        // sudo localectl set-x11-keymap latam pc104 colemak && sudo localectl set-keymap colemak
        SEND_STRING("rlsy iycaifcgi rfg" SS_TAP(X_MINS) "x11" SS_TAP(X_MINS) "efjma" SS_TAP(X_P) " iagam " SS_TAP(X_P) "c104 cyifmae " SS_LSFT("77") " rlsy iycaifcgi rfg" SS_TAP(X_MINS) "efjma" SS_TAP(X_P) " cyifmae\n");
    }
    /* SEQ_TWO_KEYS(KC_E, KC_D) { */
    /*   SEND_STRING(SS_LGUI("r") "cmd\n" SS_LCTL("c")); */
      /* did_leader_succeed = true; */
    /* } */
    leader_end();
  }
}

/* void leader_start(void) { */
/*   // sequence started */
/* } */

/* void leader_end(void) { */
  // sequence ended (no success/failuer detection)
/* } */


// ============
// DANCE TAPS
// ============
/* Return an integer that corresponds to what kind of tap dance should be executed.
 *
 * How to figure out tap dance state: interrupted and pressed.
 *
 * Interrupted: If the state of a dance dance is "interrupted", that means that another key has been hit
 *  under the tapping term. This is typically indicitive that you are trying to "tap" the key.
 *
 * Pressed: Whether or not the key is still being pressed. If this value is true, that means the tapping term
 *  has ended, but the key is still being pressed down. This generally means the key is being "held".
 *
 * One thing that is currenlty not possible with qmk software in regards to tap dance is to mimic the "permissive hold"
 *  feature. In general, advanced tap dances do not work well if they are used with commonly typed letters.
 *  For example "A". Tap dances are best used on non-letter keys that are not hit while typing letters.
 *
 * Good places to put an advanced tap dance:
 *  z,q,x,j,k,v,b, any function key, home/end, comma, semi-colon
 *
 * Criteria for "good placement" of a tap dance key:
 *  Not a key that is hit frequently in a sentence
 *  Not a key that is used frequently to double tap, for example 'tab' is often double tapped in a terminal, or
 *    in a web form. So 'tab' would be a poor choice for a tap dance.
 *  Letters used in common words as a double. For example 'p' in 'pepper'. If a tap dance function existed on the
 *    letter 'p', the word 'pepper' would be quite frustating to type.
 *
 * For the third point, there does exist the 'DOUBLE_SINGLE_TAP', however this is not fully tested
 *
 */

// dont touch this
uint8_t cur_dance(qk_tap_dance_state_t *state) {
    if (state->count == 1) {
        if (state->interrupted || !state->pressed) return SINGLE_TAP;
        // Key has not been interrupted, but the key is still held. Means you want to send a 'HOLD'.
        else return SINGLE_HOLD;
    } else if (state->count == 2) {
        // DOUBLE_SINGLE_TAP is to distinguish between typing "pepper", and actually wanting a double tap
        // action when hitting 'pp'. Suggested use case for this return value is when you want to send two
        // keystrokes of the key, and not the 'double tap' action/macro.
        if (state->interrupted) return DOUBLE_SINGLE_TAP;
        else if (state->pressed) return DOUBLE_HOLD;
        else return DOUBLE_TAP;
    }

    // Assumes no one is trying to type the same letter three times (at least not quickly).
    // If your tap dance key is 'KC_W', and you want to type "www." quickly - then you will need to add
    // an exception here to return a 'TRIPLE_SINGLE_TAP', and define that enum just like 'DOUBLE_SINGLE_TAP'
    if (state->count == 3) {
        if (state->interrupted || !state->pressed) return TRIPLE_TAP;
        else return TRIPLE_HOLD;
    } else return 8; // Magic number. At some point this method will expand to work for more presses
}

// Create an instance of 'tap', finished and reset for each dance
static tap dctap_state = {
    .is_press_action = true,
    .state = 0
};

void dc_finished(qk_tap_dance_state_t *state, void *user_data) {
    dctap_state.state = cur_dance(state);
    switch (dctap_state.state) {
        case SINGLE_TAP: register_code(LCM_DOT); break;
        /* case SINGLE_HOLD: register_code(KC_LCTRL); break; */
        /* case DOUBLE_TAP: register_code(LCM_COLN); break; */
        /* case DOUBLE_HOLD: register_code(KC_LALT); break; */

        // Last case is for fast typing. Assuming your key is `f`:
        // For example, when typing the word `buffer`, and you want to make sure that you send `ff` and not `Esc`.
        // In order to type `ff` when typing fast, the next character will have to be hit within the `TAPPING_TERM`, which by default is 200ms.
        /* case DOUBLE_SINGLE_TAP: tap_code(KC_X); register_code(KC_X); */
    }
}

void dc_reset(qk_tap_dance_state_t *state, void *user_data) {
    switch (dctap_state.state) {
        case SINGLE_TAP: unregister_code(LCM_DOT); break;
        case SINGLE_HOLD: unregister_code(KC_LCTRL); break;
        case DOUBLE_TAP: unregister_code(KC_ESC); break;
        case DOUBLE_HOLD: unregister_code(KC_LALT);
        case DOUBLE_SINGLE_TAP: unregister_code(KC_X);
    }
    dctap_state.state = 0;
}

void CIRC_PLUS(qk_tap_dance_state_t *state, void *user_data) {
  // for ACTION_TAP_DANCE_FN you CANT use a switch, it only runs after a count
  switch (state->count) {
      case 1:
          tap_code16(ROPT(LCM_O));
          break;
      case 2:
          tap_code(LCM_PLUS);
          break;
    }
}

void HTTP_TYPE(qk_tap_dance_state_t *state, void *user_data) {
  // for ACTION_TAP_DANCE_FN you CANT use a switch, it only runs after a count
  switch (state->count) {
      case 1:
          tap_code16(LCM_NTIL);
          break;
      case 2:
          SEND_STRING("https:");
          tap_code16(LCM_SLSH);
          tap_code16(LCM_SLSH);
          reset_tap_dance(state);
          break;
    }
}


/* ========================================================== */
/* tap_code registers a key and unregisters it instantly */

/* theres also */

/* tap_code16(LCTL(KC_C)); */

// for more functions like tap_code : https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_macros#advanced-example
// use advanced when you need register and unregister
// for basic doubles do action_tap_dance_double(key1, key2)
//
// FOR DANCE_FN only BASIC keycodes work, no modifiers

qk_tap_dance_action_t tap_dance_actions[] = {
    /* [TD_CS] = ACTION_TAP_DANCE_DOUBLE(LCM_COMM, LCM_SCLN), */
    /* [TD_PLUS] = ACTION_TAP_DANCE_DOUBLE(LCM_NTIL, LCM_PLUS), */
    /* [TD_CIRC_PLUS] = ACTION_TAP_DANCE_FN(CIRC_PLUS), */
    /* [TD_DC] = ACTION_TAP_DANCE_FN_ADVANCED(NULL, dc_finished, dc_reset), */
};

/* ACTION_TAP_DANCE_LAYER_MOVE(kc, layer):
 * Sends the kc keycode when tapped once, or moves to layer.
 * (this functions like the TO layer keycode). */

/* ACTION_TAP_DANCE_LAYER_TOGGLE(kc, layer):
 * Sends the kc keycode when tapped once, or toggles the state of layer.
 * (this functions like the TG layer keycode). */

/* DEPRECATED  for the new way to add a different tapping term for each key */
/* ACTION_TAP_DANCE_FN_ADVANCED_TIME */
