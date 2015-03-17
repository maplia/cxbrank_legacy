Date.prototype.toLocaleString = function() {
	return [
		this.getFullYear(),
		('0' + (this.getMonth() + 1)).slice(-2),
		('0' + this.getDate()).slice(-2)
	].join('/') + ' ' + [
		('0' + this.getHours()).slice(-2),
		('0' + this.getMinutes()).slice(-2),
		('0' + this.getSeconds()).slice(-2)
	].join(':');
}

var cookie_mtime_name = 'mtime';

function getInputName(index) {
	return 'tune' + String(index+1);
}

function getCookieHistoryName(date, index) {
	return date.getFullYear() +
		('0' + (date.getMonth() + 1)).slice(-2) + ('0' + date.getDate()).slice(-2)
		+ '_' + getInputName(index);
}

function getTheadDateString(date) {
	return [('0' + (date.getMonth() + 1)).slice(-2)
		+ '/' + ('0' + date.getDate()).slice(-2)].join('/');
}

function initialize(ids, s_date, e_date, input_table_id, chart_table_id, history_table_id, mtime_p_id, form) {
	var xmlHttpRequest = new XMLHttpRequest();
	var input_table = document.getElementById(input_table_id);
	var chart_table = document.getElementById(chart_table_id);
	var history_table = document.getElementById(history_table_id);
	var mtime_p = document.getElementById(mtime_p_id);
	var saved_scores = new Array();
	var saved_history_scores = new Array();
	var titles = new Array();
	var notes = new Array();
	var mtime = getCookie(cookie_mtime_name);
	var date_span = (e_date - s_date) / (24*60*60*1000);

	for (var i = 0; i < ids.length; i++) {
		xmlHttpRequest.open('get', '../api/music/' + ids[i], false);
		xmlHttpRequest.send(null);
		var json = JSON.parse(xmlHttpRequest.responseText);

		titles[i] = json.title;
		notes[i] = json.ext.notes;
		saved_scores[i] = getCookie(getInputName(i));
		if (isNaN(saved_scores[i])) {
			saved_scores[i] = "";
		}
		for (var j = 0; j <= date_span; j++) {
			var date = new Date(s_date);
			date.setDate(date.getDate() + j);
			var history_name = getCookieHistoryName(date, i);

			saved_history_scores[history_name] = getCookie(history_name);
			if (isNaN(saved_history_scores[history_name])) {
				saved_history_scores[history_name] = "";
			}
		}
	}

	createInputTable(input_table, titles, saved_scores);
	createChartTable(chart_table, titles, notes, saved_scores);
	createHistoryTable(history_table, titles, s_date, e_date, saved_history_scores);
	if (mtime != "") {
		mtime_p.innerHTML = '最終更新時刻: ' + getCookie(cookie_mtime_name);
	}
}

function createInputTable(table, titles, saved_scores) {
    for (var i = 0; i < titles.length; i++) {
		var tr_element = document.createElement('tr');
		var cell_element;
		var input_element;

		input_element = document.createElement('input');
		input_element.type = 'text';
		input_element.name = getInputName(i);
		input_element.maxLength = 5;
		input_element.size = 5;
		if (saved_scores[i] != '') {
			input_element.value = saved_scores[i];
		}

		cell_element = document.createElement('th');
		cell_element.innerHTML = titles[i];
		tr_element.appendChild(cell_element);

		cell_element = document.createElement('td');
		cell_element.appendChild(input_element);
		tr_element.appendChild(cell_element);

		table.appendChild(tr_element);
	}
}

function createChartTable(table, titles, notes, saved_scores) {
	var thead_element = document.createElement('thead');
	var tfoot_element = document.createElement('tfoot');
	var tbody_element = document.createElement('tbody');
	var values;

    var note_sum = 0;
    var max_score_sum = 0;
    var score_sum = 0;

	values = new Array('Title', 'Notes', 'MAX', 'Score', '%');
	thead_element.appendChild(createTableRow(values, true));
	table.appendChild(thead_element);

    for (var i = 0; i < titles.length; i++) {
        var max_score = notes[i] * 100;
        var score = parseInt((saved_scores[i] == "" ? 0 : saved_scores[i]));
        var rate_obj = new Number(score / max_score * 100);

        note_sum = note_sum + notes[i];
        max_score_sum = max_score_sum + max_score;
        score_sum = score_sum + score;

		values = new Array(titles[i], notes[i], max_score, score, rate_obj.toFixed(2)+'%');
		tbody_element.appendChild(createTableRow(values, false));
    }
	table.appendChild(tbody_element);

    var rate_sum_obj = new Number(score_sum / max_score_sum * 100);

	values = new Array('Total', note_sum, max_score_sum, score_sum, rate_sum_obj.toFixed(2)+'%');
	tfoot_element.appendChild(createTableRow(values, false));
	table.appendChild(tfoot_element);
}

function createHistoryTable(table, titles, s_date, e_date, saved_scores) {
	var thead_element = document.createElement('thead');
	var tfoot_element = document.createElement('tfoot');
	var tbody_element = document.createElement('tbody');
	var values;
	var date_span = (e_date - s_date) / (24*60*60*1000);

	values = new Array();
	values[0] = 'Title';
	for (var i = 0; i <= date_span; i++) {
		var date = new Date(s_date);
		date.setDate(date.getDate() + i);

		values[i+1] = getTheadDateString(date);
	}
	thead_element.appendChild(createTableRow(values, true));
	table.appendChild(thead_element);

	for (var i = 0; i < titles.length; i++) {
		values = new Array();
		values[0] = titles[i];

		for (var j = 0; j <= date_span; j++) {
			var date = new Date(s_date);
			date.setDate(date.getDate() + j);

			values[j+1] = saved_scores[getCookieHistoryName(date, i)];
		}
		tbody_element.appendChild(createTableRow(values, false));
	}
	table.appendChild(tbody_element);
}

function createTableRow(values, is_header) {
	var tr_element = document.createElement('tr');

	for (var i = 0; i < values.length; i++) {
		var cell_element;

		if (is_header || (i == 0)) {
			cell_element = document.createElement('th');
		} else {
			cell_element = document.createElement('td');
		}
		cell_element.innerHTML = values[i];
		tr_element.appendChild(cell_element);
	}

	return tr_element;
}

function submitScores(ids, form) {
	var date = new Date();

	for (var i = 0; i < ids.length; i++) {
		var input_name = getInputName(i);
		var score = parseInt(document.getElementsByName(input_name)[0].value);

		setCookie(input_name, String(score));
		setCookie(getCookieHistoryName(date, i), String(score));
	}
	setCookie(cookie_mtime_name, date.toLocaleString());

	form.submit();
}
