
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


combo_t key_combos[COMBO_COUNT] = {
  [ZQ_CAPS] = COMBO(zq_combo, KC_CAPS),
  [JK_TAB] = COMBO(jk_combo, KC_TAB),
  [ZC_COPY] = COMBO_ACTION(copy_combo),
  [XV_PASTE] = COMBO_ACTION(paste_combo),
};

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
