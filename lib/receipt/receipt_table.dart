import 'package:blue_print_pos/receipt/receipt_alignment.dart';
import 'package:blue_print_pos/receipt/receipt_text_style.dart';
import 'package:blue_print_pos/receipt/receipt_text_style_type.dart';

class PaddingColumn {
  const PaddingColumn({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });
  final double top;
  final double right;
  final double bottom;
  final double left;

  String get css {
    return 'padding: ${top}px ${right}px ${bottom}px ${left}px;';
  }
}

class ColumnTextTable {
  ColumnTextTable(
    this.text, {
    this.isHeader = false,
    this.widthPercent = 100,
    this.textStyle,
    this.alignment = ReceiptAlignment.left,
    this.padding = const PaddingColumn(),
  });
  final String text;
  final bool isHeader;
  final double widthPercent;
  final ReceiptTextStyle? textStyle;
  final ReceiptAlignment alignment;
  final PaddingColumn padding;

  String get html {
    String alignmentClass = '';
    switch (alignment) {
      case ReceiptAlignment.left:
        alignmentClass = 'text-left';
        break;
      case ReceiptAlignment.center:
        alignmentClass = 'text-center';
        break;
      case ReceiptAlignment.right:
        alignmentClass = 'text-right';
        break;
    }

    final String style = 'width: $widthPercent%; ${padding.css}';
    String content = text;

    if (textStyle != null) {
      if (textStyle!.type == ReceiptTextStyleType.bold) {
        content = '<b>$content</b>';
      }
    }

    return '<td style="$style" class="$alignmentClass">$content</td>';
  }
}

class RowTextTable {
  RowTextTable(this.columns);
  final List<ColumnTextTable> columns;

  String get html {
    String rowHtml = '<tr>';
    for (final ColumnTextTable column in columns) {
      rowHtml += column.html;
    }
    rowHtml += '</tr>';
    return rowHtml;
  }
}

class ReceiptTextTable {
  ReceiptTextTable(this.rows);
  final List<RowTextTable> rows;

  String get html {
    String tableHtml = '<table style="width: 100%; border-collapse: collapse;">';
    for (final RowTextTable row in rows) {
      tableHtml += row.html;
    }
    tableHtml += '</table>';
    return tableHtml;
  }
}
