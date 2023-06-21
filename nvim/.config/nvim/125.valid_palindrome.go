func isPalindrome(s string) bool {
	l := 0
	r := len(s) - 1
	for l < r {
		if !isAlphanumeric(s[l]) {
			l++
			continue
		}
		if !isAlphanumeric(s[r]) {
			r--
			continue
		}
		if lower(s[l]) == lower(s[r]) {
			l++
			r--
		} else {
			return false
		}
	}
	return true
}

func isAlphanumeric(char byte) bool {
	return (char >= '0' && char <= '9') || (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
}

func lower(char byte) byte {
	if char >= 'A' && char <= 'Z' {
		return char + 32
	}
	return char
}
