import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../providers/settings_provider.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');
final _numFmt = NumberFormat('#,##0.0', 'en_US');

class ExportService {
  Future<void> exportToCsv(
      List<Transaction> transactions, SettingsProvider sp) async {
    final rows = <List<String>>[
      ['Date', 'Type', 'Category', 'Description', 'Amount'],
      for (final t in transactions)
        [
          _dateFmt.format(t.date),
          t.type,
          t.category,
          t.description ?? '',
          '${sp.currencySymbol}${_numFmt.format(t.amount)}',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cashbook_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Cashbook Export',
    );
  }

  Future<void> exportToPdf(
      List<Transaction> transactions, SettingsProvider sp) async {
    final pdf = pw.Document();
    final rows = <List<String>>[
      ['Date', 'Type', 'Category', 'Description', 'Amount'],
      for (final t in transactions)
        [
          _dateFmt.format(t.date),
          t.type,
          t.category,
          t.description ?? '',
          '${sp.currencySymbol}${_numFmt.format(t.amount)}',
        ],
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Cashbook - Transaction Report',
                style: pw.TextStyle(fontSize: 20)),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: rows.first,
            data: rows.skip(1).toList(),
            border: pw.TableBorder.all(),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cashbook_export.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Cashbook Export',
    );
  }
}
