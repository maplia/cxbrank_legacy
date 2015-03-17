var diffs = ['std', 'hrd', 'mtr'];
var diffs_legacy = ['bsc', 'adv', 'ext'];
var diffs_name = ['STD', 'HRD', 'MAS'];

function getDiffName(diff) {
	var diff_name = '';

	$.each(diffs, function (i, diff_) {
		if ((diff == diff_) || (diff == diffs_legacy[i])) {
			diff_name = diffs_name[i];
			return false;
		}
	});

	return diff_name;
}
