// json sample
// 
// {
//   column_classes: ['', 'text', 'number'],
//   thead: [
//     {
//       values: ['Rank', 'Name', 'Score']
//     },
//   ],
//   tbody: [
//     {
//       class_name: 'odd',
//       values: ['1st', 'Alex', '23000']
//     },
//     {
//       class_name: 'even',
//       values: ['2nd', 'Bob', '18000']
//     }
//   ]
// }

(function ($) {
	$.fn.json2table = function (data) {
		var container = $(this[0]);
		container.empty();

		if (data.thead != undefined) {
			var block = $('<thead />');
			container.append(block);
			createTableRows(block, data.thead, undefined, true);
		}
		if (data.tbody != undefined) {
			var block = $('<tbody />');
			container.append(block);
			createTableRows(block, data.tbody, data.column_classes, false);
		}
		if (data.tfoot != undefined) {
			var block = $('<tfoot />');
			container.append(block);
			createTableRows(block, data.tfoot, data.column_classes, false);
		}
	}

	function createTableRows(block, rows, column_classes, is_header) {
		$.each(rows, function (i, row) {
			var tr = createTableRow(row, column_classes, is_header);
			block.append(tr);
		});
	}

	function createTableRow(row, column_classes, is_header) {
		var tr = $('<tr />');
		if (!is_header && (row.class_name != undefined)) {
			tr.addClass(row.class_name);
		}

		$.each(row.values, function(i, value) {
			var cell;

			if (is_header || (i == 0)) {
				cell = $('<th />');
			} else {
				cell = $('<td />');
			}
			if ((column_classes != undefined) && (column_classes[i].length > 0)) {
				cell.addClass(column_classes[i]);
			}

			cell.append(value);
			tr.append(cell);
		});

		return tr;
	}
})(jQuery);
