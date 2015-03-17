function calcRate(form, levels, notes) {
	var level;
	var s_notes;
	var judge_f;
	var judge_s;
	var judge_c;
	var judge_mc;
	var rate;
	var rate_obj;
	var rp;
	var rp_obj;

	for (var i = 0; i < form.diff.length; i++) {
		if (form.diff[i].checked) {
			level = levels[i];
			s_notes = notes[i];
			break;
		}
	}
	judge_f = parseInt(form.judge_f.value);
	judge_s = parseInt(form.judge_s.value);
	judge_c = parseInt(form.judge_c.value);
	judge_mc = parseInt(form.judge_mc.value);

	rate = ((judge_f + judge_s) * 0.8 + judge_c * 0.4 + judge_mc * 0.2) / s_notes;
	rate = parseInt(rate * 100) / 100;
	if (form.ult.checked) {
		rp = level * rate * 1.2;
	} else {
		rp = level * rate;
	}
	rp = parseInt(rp * 100) / 100;

	rate_obj = new Number(rate * 100);
	rp_obj = new Number(rp);

	if (rate == 100) {
		form.rate.value = '100%';
	} else {
		form.rate.value = rate_obj.toFixed(2)+'%';
	}
	form.rp.value = rp_obj.toFixed(2);
}
