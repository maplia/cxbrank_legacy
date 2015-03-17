var select_music_id = '#select_music';
var chart_table_id = '#table_chart';

var ranks = new Array('S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C');
var rates = new Array(1.00, 0.98, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70);

var charts;

function initialize() {
	charts = loadChartData();

	createSelect($(select_music_id), charts);
	createChart($(select_music_id), $(chart_table_id), charts);
}

function changeChart() {
	createChart($(select_music_id), $(chart_table_id), charts);
}

function loadChartData() {
	var charts;

	$.ajax({
		url: '../api/musics',
		async: false,
		success: function (json) {
			charts = json;
		}
	});

	charts.sort(function (a, b) {
		return a.number - b.number;
	});

	return charts;
}

function createSelect(select, charts) {
	$.each(charts, function (i, chart) {
		var option = $('<option />', {
			value: i
		});
		option.html(chart.title);

		select.append(option);
	});
}

function createChart(select, table, charts) {
	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
	table_data.column_classes = ['number', 'number', 'number'];
	$.each(ranks, function (i, rank) {
		table_data.column_classes[table_data.column_classes.length] = 'number';
	});

	table_data.thead[0] = {
		values: ['＼', 'Lv', 'Notes']
	};
	$.each(ranks, function (i, rank) {
		table_data.thead[0].values[table_data.thead[0].values.length] = rank;
	});

	var chart = charts[parseInt(select.val())];

	$.each(diffs_legacy, function (i, diff) {
		var values = [getDiffName(diff), chart[diff].level, chart[diff].notes];

		table_data.tbody[i] = {
			class_name: diff,
			values: values
		};

		$.each(rates, function (j, rate) {
			var allow = Math.floor(chart[diff].notes * (1 - rate));
			table_data.tbody[i].values[table_data.tbody[i].values.length] = allow;
		});
	});

	table.json2table(table_data);
}
