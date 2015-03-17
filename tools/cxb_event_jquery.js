var input_table_id = '#table_input';
var chart_table_id = '#table_chart';
var history_table_id = '#table_history';
var mtime_p_id = '#p_mtime';

$.cookie.json = true;
var cookie_expires = 10;

function getMusicTitle(require) {
	var title = require.title;
	if (require.diff == 'bsc') {
		title = title + ' [STD]';
	} else if (require.diff == 'adv') {
		title = title + ' [HRD]';
	} else if (require.diff == 'ext') {
		title = title + ' [MTR]';
	}

	return title;
}

function getMusicKey(require) {
	var name = require.mid;
	if (require.diff != undefined) {
		name = name + '_' + require.diff;
	}

	return name;
}

function getScoreDateKey(date) {
	return date.strftime('score_%Y%m%d');
}

function initialize(eid, requires, span) {
	loadMusicData(requires);
	var playData = loadPlayData(eid, requires);

	createInputTable($(input_table_id), requires, playData);
	createChartTable($(chart_table_id), requires, playData);

	if (span != undefined) {
		var dates = [];
		for (var date = new Date(span.start); date <= span.end; date.setDate(date.getDate() + 1)) {
			dates[dates.length] = new Date(date);
		}

		createHistoryTable($(history_table_id), requires, dates, playData);
	}

	if (playData.mtime != undefined) {
		$(mtime_p_id).text('最終更新時刻: ' + playData.mtime);
	}
}

function loadPlayData(eid, requires) {
	var playData = ($.cookie(eid) || {});

	$.each(requires, function (i, require) {
		var key = getMusicKey(require);

		if (playData[key] == undefined) {
			playData[key] = {};
		}
	});

	return playData;
}

function loadMusicData(requires) {
	$.each(requires, function (i, require) {
		$.ajax({
			url: '../api/music/' + require.mid,
			async: false,
			success: function (json) {
				require.title = json.title;
				if (require.diff != undefined) {
					require.notes = json[require.diff].notes;
				} else {
					require.notes = json.ext.notes;
				}
			}
		});
	});
}

function createInputTable(table, requires, playdata) {
	var table_data = {};
	table_data.tbody = [];

	$.each(requires, function (i, require) {
		var key = getMusicKey(require);

		var input = $('<input type="text" />').attr({
			name: getMusicKey(require), maxLength: 5, size: 5
		});
		if (!isNaN(playdata[key].score)) {
			input.attr({value: playdata[key].score});
		}

		table_data.tbody[i] = {
			class_name: require.diff,
			values: [getMusicTitle(require), input]
		};
	});

	table.json2table(table_data);
}

function createChartTable(table, requires, playdata) {
	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
	table_data.tfoot = [];
	table_data.column_classes = [
		'', 'number', 'number', 'number', 'number', 'number'
	];

	table_data.thead[0] = {
		values: ['Title', 'Notes', 'MAX', 'Score', 'Loss', '%']
	};

    var note_sum = 0;
    var max_score_sum = 0;
    var score_sum = 0;
	var loss_sum = 0;

	$.each(requires, function (i, require) {
		var key = getMusicKey(require);
        var max_score = require.notes * 100;

		var score = parseInt(playdata[key].score || '0');
		var loss = max_score - score;
        var rate_obj = new Number(score / max_score * 100);

        note_sum = note_sum + require.notes;
        max_score_sum = max_score_sum + max_score;
        score_sum = score_sum + score;
		loss_sum = loss_sum + loss;

		table_data.tbody[i] = {
			class_name: require.diff,
			values: [
				getMusicTitle(require),
				require.notes, max_score, score, loss, rate_obj.toFixed(2)+'%']
		}
	});

	var rate_sum_obj = new Number(score_sum / max_score_sum * 100);

	table_data.tfoot[0] = {
		values: [
			'Total',
			note_sum, max_score_sum, score_sum, loss_sum, rate_sum_obj.toFixed(2)+'%']
	};

	table.json2table(table_data);
}

function createHistoryTable(table, requires, dates, playdata) {
	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
//	table_data.tfoot = [];
	table_data.column_classes = [];
	table_data.column_classes[0] = '';
	$.each(dates, function (i, date) {
		table_data.column_classes[i+1] = 'number';
	});

	table_data.thead[0] = {};
	table_data.thead[0].values = [];
	table_data.thead[0].values[0] = 'Title';
	$.each(dates, function (i, date) {
		table_data.thead[0].values[i+1] = date.strftime('%m/%d');
	});

	$.each (requires, function (i, require) {
		table_data.tbody[i] = {};
		table_data.tbody[i].class_name = require.diff;

		table_data.tbody[i].values = [];
		table_data.tbody[i].values[0] = getMusicTitle(require);
		$.each(dates, function (j, date) {
			var music_key = getMusicKey(require);
			var date_key = getScoreDateKey(date);

			if (playdata[music_key] == undefined) {
				table_data.tbody[i].values[j+1] = '';
			} else {
				table_data.tbody[i].values[j+1] = playdata[music_key][date_key] || '';
			}
		});
	});

	table.json2table(table_data);
}

function submitScores(eid, requires, span) {
	var date = new Date();
	var playData = loadPlayData(eid, requires);

	$.each(requires, function (i, require) {
		var music_key = getMusicKey(require);
		var date_key = getScoreDateKey(date);
		var score = parseInt($('[name="' + music_key + '"]')[0].value);

		playData[music_key].score = score;
		playData[music_key][date_key] = score;
	});
	playData.mtime = date.strftime('%Y/%m/%d %H:%M:%S');

	$.cookie(eid, playData, {expires: cookie_expires});

	initialize(eid, requires, span);
}
