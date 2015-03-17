var music_select_id = '#select_music';
var rate_table_id = '#table_rate';

function initialize() {
	var musics = loadMusicData();

	createMusicSelector(musics);
}

function loadMusicData() {
	var musics = [];

	$.ajax({
		url: '../api/musics',
		async: false,
		success: function (json) {
			$.each(json, function(i, music) {
				musics[musics.length] = music;
			});
		}
	});

	musics.sort(function (a, b) {
		return a.number - b.number;
	});

	return musics;
}

function createMusicSelector(musics) {
	var selector = $(music_select_id);

	$.each(musics, function (i, music) {
		var option = $('<option />').attr({
			value: music.number
		});
		option.append(music.title);
		selector.append(option);
	});
}

function calcScoreRate() {
	var selected_music;
	var selected_diff = $('[name="diff"]:checked').val();
	var inputed_score = parseInt($('[name="score"]')[0].value);
	var table = $(rate_table_id);

	$.ajax({
		url: '../api/musics',
		async: false,
		success: function (json) {
			$.each(json, function(i, music) {
				if (music.number == parseInt($(music_select_id).val())) {
					selected_music = music;
					return true;
				}
			});
		}
	});

	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
	table_data.thead[0] = {
		values: ['タイトル', 'レベル', '理論値', 'スコア', '得点率']
	};
	table_data.tbody_column_classes = [
		'', 'number', 'number', 'number', 'number',
	];

	table_data.tbody[0] = {
		class_name: selected_diff,
		values: [
			selected_music.title + ' [' + getDiffName(selected_diff) + ']',
			selected_music[selected_diff].level, selected_music[selected_diff].notes * 100,
			inputed_score,
			new Number(inputed_score / selected_music[selected_diff].notes).toFixed(2)+'%'
		]
	}

	table.json2table(table_data);
}
