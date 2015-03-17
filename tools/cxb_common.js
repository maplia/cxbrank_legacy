function getDiffName(diff) {
	if ((diff == 'bsc') || (diff == 'std')) {
		return 'STD';
	} else if ((diff == 'adv') || (diff == 'hrd')) {
		return 'HRD';
	} else if ((diff == 'ext') || (diff == 'mtr')) {
		return 'MTR';
	} else {
		return '';
	}
}
