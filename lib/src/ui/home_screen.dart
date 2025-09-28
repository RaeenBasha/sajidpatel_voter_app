import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/voter_service.dart';
import '../models/voter.dart';
import '../utils/pdf_slips.dart';

// WhatsApp icon
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = VoterService();
  Query<Map<String, dynamic>>? _query;
  String _search = '';
  bool _sortAsc = true;
  int _sortColumn = 0;

  @override
  void initState() {
    _query = FirebaseFirestore.instance.collection('voters').limit(200);
    super.initState();
  }

  void _runGlobalSearch() {
    if (_search.trim().isEmpty) {
      setState(() => _query =
          FirebaseFirestore.instance.collection('voters').limit(200));
    } else {
      setState(() => _query = _svc.globalSearch(_search));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voter List Dashboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Global search (Name, Sector, Building, ...)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _search = v,
                  onSubmitted: (_) => _runGlobalSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _runGlobalSearch, child: const Text('Search')),
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query!.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snap.data!.docs
                    .map((d) => Voter.fromMap(d.id, d.data()))
                    .toList();

                rows.sort((a, b) {
                  int cmp;
                  switch (_sortColumn) {
                    case 0:
                      cmp = a.sector.compareTo(b.sector);
                      break;
                    case 1:
                      cmp = a.buildingName.compareTo(b.buildingName);
                      break;
                    case 2:
                      cmp = a.flatNumber.compareTo(b.flatNumber);
                      break;
                    case 3:
                      cmp = a.name.compareTo(b.name);
                      break;
                    case 4:
                      cmp = a.rscNumber.compareTo(b.rscNumber);
                      break;
                    case 5:
                      cmp = a.phone.compareTo(b.phone);
                      break;
                    default:
                      cmp = 0;
                  }
                  return _sortAsc ? cmp : -cmp;
                });

                return Column(
                  children: [
                    Expanded(
                      child: DataTable2(
                        columnSpacing: 12,
                        headingRowHeight: 44,
                        horizontalMargin: 12,
                        columns: [
                          _col('Sector', 0),
                          _col('Building', 1),
                          _col('Flat', 2),
                          _col('Voter Name', 3),
                          _col('RSC No', 4),
                          _col('Mobile', 5),
                        ],
                        rows: rows.map((v) => DataRow(cells: [
                          DataCell(Text(v.sector)),
                          DataCell(Text(v.buildingName)),
                          DataCell(Text(v.flatNumber)),
                          DataCell(InkWell(
                            onTap: () => _showEditVoter(v),
                            child: Text(v.name,
                                style: const TextStyle(
                                    decoration:
                                    TextDecoration.underline)),
                          )),
                          DataCell(Text(v.rscNumber)),
                          DataCell(Row(
                            children: [
                              Text(v.phone),
                              IconButton(
                                tooltip: 'Send WhatsApp',
                                icon: Icon(FontAwesomeIcons.whatsapp), // ✅ no const
                                onPressed: () => _sendWhatsApp(v),
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(spacing: 8, children: [
                        ElevatedButton(
                          onPressed: () => _exportCSV(rows),
                          child: const Text('Export CSV'),
                        ),
                        ElevatedButton(
                          onPressed: () => _exportXLSX(rows),
                          child: const Text('Export XLSX'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              generateVoterSlipsPDF(rows, context),
                          child: const Text('Download Voter Slips (PDF)'),
                        ),
                      ]),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _col(String title, int idx) => DataColumn(
    label: Text(title),
    onSort: (i, asc) =>
        setState(() {
          _sortColumn = idx;
          _sortAsc = asc;
        }),
  );

  void _sendWhatsApp(Voter main) async {
    final mates =
    await _svc.votersByFlat(main.buildingName, main.flatNumber);
    final b = StringBuffer();
    b.writeln('Dear ${main.name},\n');
    b.writeln('Your voting details are as follows:\n');
    for (final v in mates) {
      b.writeln('-Voter Name: ${v.name}');
      b.writeln('- EPIC No: ${v.rscNumber}');
      b.writeln('- List No / Part No: ${v.yadiNo}');
      b.writeln('- Sr No: ${v.srNo}');
      b.writeln('- Polling Station Address: ${v.pollingBooth}');
      b.writeln('');
    }
    b.writeln(
        'Please keep this information handy for your upcoming vote. For any queries, feel free to contact us.');
    final msg = Uri.encodeComponent(b.toString());
    final phone = main.phone.replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportCSV(List<Voter> rows) async {
    final data = <List<dynamic>>[
      ['Sector', 'Building', 'Flat', 'Voter Name', 'RSC No', 'Mobile']
    ];
    for (final v in rows) {
      data.add([
        v.sector,
        v.buildingName,
        v.flatNumber,
        v.name,
        v.rscNumber,
        v.phone
      ]);
    }
    final csv = const ListToCsvConverter().convert(data);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/voters.csv');
    await f.writeAsString(csv);
    await Share.shareXFiles([XFile(f.path)], text: 'Voters Export');
  }

  Future<void> _exportXLSX(List<Voter> rows) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Voters'];
    sheet.appendRow([
      xls.TextCellValue('Sector'),
      xls.TextCellValue('Building'),
      xls.TextCellValue('Flat'),
      xls.TextCellValue('Voter Name'),
      xls.TextCellValue('RSC No'),
      xls.TextCellValue('Mobile'),
    ]);

    for (final v in rows) {
      sheet.appendRow([
        xls.TextCellValue(v.sector),
        xls.TextCellValue(v.buildingName),
        xls.TextCellValue(v.flatNumber),
        xls.TextCellValue(v.name),
        xls.TextCellValue(v.rscNumber),
        xls.TextCellValue(v.phone),
      ]);
    }

    final bytes = excel.encode()!;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voters.xlsx';
    final f = File(path)..writeAsBytesSync(bytes);
    await Share.shareXFiles([XFile(path)], text: 'Voters Export');
  }

  Future<void> _showEditVoter(Voter v) async {
    final ctrlName = TextEditingController(text: v.name);
    final ctrlPhone = TextEditingController(text: v.phone);
    final ctrlRSC = TextEditingController(text: v.rscNumber);
    final ctrlYadi = TextEditingController(text: v.yadiNo);
    final ctrlSr = TextEditingController(text: v.srNo);
    final ctrlSector = TextEditingController(text: v.sector);
    final ctrlBuilding = TextEditingController(text: v.buildingName);
    final ctrlFlat = TextEditingController(text: v.flatNumber);
    final ctrlBooth = TextEditingController(text: v.pollingBooth);

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Update Voter',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                  controller: ctrlName,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: ctrlPhone,
                  decoration: const InputDecoration(labelText: 'Phone')),
              TextField(
                  controller: ctrlRSC,
                  decoration: const InputDecoration(labelText: 'EPIC (RSC)')),
              TextField(
                  controller: ctrlYadi,
                  decoration: const InputDecoration(labelText: 'YADI / Part No')),
              TextField(
                  controller: ctrlSr,
                  decoration: const InputDecoration(labelText: 'Sr No')),
              TextField(
                  controller: ctrlSector,
                  decoration: const InputDecoration(labelText: 'Sector')),
              TextField(
                  controller: ctrlBuilding,
                  decoration:
                  const InputDecoration(labelText: 'Building Name')),
              TextField(
                  controller: ctrlFlat,
                  decoration:
                  const InputDecoration(labelText: 'Flat Number')),
              TextField(
                  controller: ctrlBooth,
                  decoration:
                  const InputDecoration(labelText: 'Polling Booth')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await VoterService().upsertVoter(v.id, {
                    'NAME': ctrlName.text,
                    'PHONE_NUMBER': ctrlPhone.text,
                    'RSC_NUMBER': ctrlRSC.text,
                    'YADI_NO': ctrlYadi.text,
                    'SR_NO': ctrlSr.text,
                    'SECTOR': ctrlSector.text,
                    'BUILDING_NAME': ctrlBuilding.text,
                    'FLAT_NUMBER': ctrlFlat.text,
                    'POLLING_BOOTH': ctrlBooth.text,
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
