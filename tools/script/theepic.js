var chart_table_id = '#table_chart';
var allow_rate_sp = 1 - 0.98;

function initialize() {
	var charts = loadChartData();

	createChartTable($(chart_table_id), charts);

	$(chart_table_id).tablesorter({sortList: [[0, 0],]});
}

function loadChartData() {
	var charts = [];

	$.ajax({
		url: '../api/musics',
		async: false,
		success: function (json) {
			$.each(json, function(i, music) {
				$.each(diffs_legacy, function (j, diff) {
					if (music[diff].level >= 60) {
						var chart = {};

						chart.title = music.title;
						chart.number = music.number;
						chart.diff = diff;
						chart.level = music[diff].level;
						chart.notes = music[diff].notes;

						charts[charts.length] = chart;
					}
				});
			});
		}
	});

	return charts;
}

function createChartTable(table, charts) {
	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
	table_data.tbody_column_classes = [
		'number', 'text', 'text', 'number', 'number', 'number',
	];

	table_data.thead[0] = {
		values: ['#', 'タイトル', '難易度', 'レベル', 'ノート数', '許容Cool未満']
	};

	$.each(charts, function (i, chart) {
		var text_diff = (chart.diff == 'bsc');
		var allow = Math.floor(chart.notes * allow_rate_sp);

		table_data.tbody[i] = {
			class_name: chart.diff,
			values: [
				chart.number, chart.title, getDiffName(chart.diff),
				chart.level, chart.notes, allow
			]
		};
	});

	table.json2table(table_data);
}
