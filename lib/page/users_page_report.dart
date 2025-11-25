import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/page/report_page1.dart';
import 'package:omnifit_front/page/report_page2.dart';
import 'package:omnifit_front/page/report_page3.dart';
import 'package:omnifit_front/page/report_page4.dart';
import 'package:omnifit_front/page/users_page.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:omnifit_front/widget/web_pagination.dart';

class PickedPdf {
  final String name;
  final Uint8List bytes;
  PickedPdf({required this.name, required this.bytes});
}

class UsersPageReport extends StatefulWidget {
  static const route = '/users/report';

  const UsersPageReport({Key? key}) : super(key: key);

  @override
  State<UsersPageReport> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPageReport> {
  String? inputText;
  int count = 0;
  int perPage = 10;
  int currentPage = 1;
  String? next;
  String? previous;
  List<UserModel> users = [];
  String uri = '${BASE_URL}api/v1/exp/list/';
  String? name;
  int sortColumnIndex = 0;
  bool isAscSort = false;
  final Box storageBox = Hive.box('App Service Box');
  TextEditingController controller = TextEditingController();

  FocusNode focusNode = FocusNode();
  List<dynamic> sortList = ["pk", "name", "", "birth", "measurement_date"];
  List<String> isAscList = ["True", "False"];

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void initData({int? columnIndex, bool? sortAscending}) async {
    name = storageBox.get("name");
    controller.text = name ?? "";
    sortColumnIndex = columnIndex ?? storageBox.get("sortColumnIndex") ?? 0;
    isAscSort = sortAscending ?? storageBox.get("ascSort") ?? true;

    late Uri url;
    if (name != null && name != "") {
      url = Uri.parse(
          '$uri?page=$currentPage&name=$name&sorting=${sortList[sortColumnIndex]}&descending=${isAscList[isAscSort ? 0 : 1]}');
    } else {
      url = Uri.parse(
          '$uri?page=$currentPage&sorting=${sortList[sortColumnIndex]}&descending=${isAscList[isAscSort ? 0 : 1]}');
    }

    final response = await http.get(
      url,
      headers: {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'},
    );

    if (response.statusCode == 200) {
      users = [];

      Map valueMap = jsonDecode(utf8.decode(response.bodyBytes));
      count = valueMap['count'];
      next = valueMap['next'];
      previous = valueMap['previous'];

      valueMap['results'].forEach((e) {
        users.add(UserModel.fromJson(e));
      });
    } else if (response.statusCode == 401) {
      AppService.instance.manageAutoLogout();
    }
    setState(() {});
  }

  void sort(int columnIndex, bool sortAscending) async {
    await storageBox.put("sortColumnIndex", columnIndex);
    await storageBox.put("ascSort", sortAscending);
    initData(columnIndex: columnIndex, sortAscending: sortAscending);
  }

  Future<List<PickedPdf>> pickMultiplePdfsWithMeta() async {
    final input = html.FileUploadInputElement()
      ..accept = 'application/pdf'
      ..multiple = true;

    final completer = Completer<List<PickedPdf>>();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(<PickedPdf>[]);
        return;
      }

      final futures = <Future<PickedPdf>>[];
      for (final html.File file in files) {
        final reader = html.FileReader();
        final fileCompleter = Completer<PickedPdf>();

        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is ByteBuffer) {
            fileCompleter.complete(
              PickedPdf(name: file.name, bytes: result.asUint8List()),
            );
          } else if (result is Uint8List) {
            fileCompleter.complete(
              PickedPdf(name: file.name, bytes: result),
            );
          } else {
            fileCompleter.completeError('파일을 읽을 수 없습니다: ${file.name}');
          }
        });
        reader.onError
            .listen((e) => fileCompleter.completeError('파일 읽기 실패: $e'));
        reader.readAsArrayBuffer(file);
        futures.add(fileCompleter.future);
      }

      Future.wait(futures)
          .then((list) => completer.complete(list))
          .catchError((e) => completer.completeError(e));
    });

    // 파일 선택창
    input.click();
    return completer.future;
  }

  Future<List<PickedPdf>?> showReorderDialog(
      BuildContext context, List<PickedPdf> initial) async {
    final items = List<PickedPdf>.from(initial);
    return showDialog<List<PickedPdf>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('병합 순서를 정하세요'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Text('${items.length}개 파일',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            items.sort((a, b) => a.name
                                .toLowerCase()
                                .compareTo(b.name.toLowerCase()));
                            setState(() {});
                          },
                          child: const Text('이름↑'),
                        ),
                        TextButton(
                          onPressed: () {
                            items.sort((a, b) => b.name
                                .toLowerCase()
                                .compareTo(a.name.toLowerCase()));
                            setState(() {});
                          },
                          child: const Text('이름↓'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final moved = items.removeAt(oldIndex);
                          items.insert(newIndex, moved);
                          setState(() {});
                        },
                        itemBuilder: (context, index) {
                          final it = items[index];
                          return ListTile(
                            key: ValueKey(it.name),
                            leading: const Icon(Icons.drag_handle),
                            title: Text(it.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('순서: ${index + 1}'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, items),
                child: const Text('확인')),
          ],
        );
      },
    );
  }

  Future<Uint8List> mergePdfBytes(List<Uint8List> pdfFiles) async {
    final PdfDocument outDoc = PdfDocument();

    outDoc.pageSettings.margins.all = 0;

    for (final fileBytes in pdfFiles) {
      final PdfDocument src = PdfDocument(inputBytes: fileBytes);
      for (int i = 0; i < src.pages.count; i++) {
        final srcPage = src.pages[i];

        outDoc.pageSettings.size = Size(srcPage.size.width, srcPage.size.height);

        final PdfPage dstPage = outDoc.pages.add();

        dstPage.rotation = srcPage.rotation;

        final PdfTemplate template = srcPage.createTemplate();

        dstPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(srcPage.size.width, srcPage.size.height),
        );
      }
      src.dispose();
    }

    final bytes = await outDoc.save();
    outDoc.dispose();
    return Uint8List.fromList(bytes);
  }


  void downloadBytes(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> onClickMergePdf(UserModel user) async {
    try {
      final List<PickedPdf> picked = await pickMultiplePdfsWithMeta();
      if (picked.isEmpty) return;

      final List<PickedPdf>? ordered = await showReorderDialog(context, picked);
      if (ordered == null || ordered.isEmpty) return;

      final Uint8List merged =
          await mergePdfBytes(ordered.map((e) => e.bytes).toList());

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${user.name}_${user.id}_merged_$dateStr.pdf';
      downloadBytes(merged, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 병합이 완료되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 병합 실패: $e')),
        );
      }
    }
  }

  // ===========================
  // UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SelectionArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Spacer(),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            side:
                                const BorderSide(width: 2, color: Colors.green),
                            foregroundColor: Colors.green,
                            backgroundColor: Colors.green,
                            elevation: 10.0,
                          ),
                          onPressed: AppService.instance.manageAutoLogout,
                          child: const Text(
                            "로그아웃",
                            style: TextStyle(color: Colors.white),
                          ))
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Center(
                          child: svgIcon(Assets.img.icon_logo,
                              width: 80, height: 40)),
                      const SizedBox(width: 10),
                      Transform.translate(
                          offset: const Offset(0, -3),
                          child: Image.asset("assets/logo1.png",
                              width: 150, height: 70)),
                      const Spacer(),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          focusNode: focusNode,
                          controller: controller,
                          autofocus: true,
                          onChanged: (value) async {
                            await storageBox.put("name", value);
                            setState(() => inputText = value);
                          },
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                iconSize: 20,
                                icon: const Icon(Icons.search),
                                onPressed: () async {
                                  currentPage = 1;
                                  name = inputText;
                                  await storageBox.put("name", name);
                                  initData();
                                  focusNode.requestFocus();
                                },
                              ),
                              hintText: "이름 입력"),
                          onSubmitted: (value) async {
                            inputText = value;
                            currentPage = 1;
                            name = inputText;
                            await storageBox.put("name", name);
                            initData();
                            focusNode.requestFocus();
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 50),
                  custom.CustomDataTable(
                    sortAscending: isAscSort,
                    sortColumnIndex: sortColumnIndex,
                    columns: <custom.DataColumn>[
                      custom.DataColumn(
                          label: const Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                '번호',
                                style: TextStyle(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          onSort: sort),
                      custom.DataColumn(
                          label: const Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                '이름',
                                style: TextStyle(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          onSort: sort),
                      const custom.DataColumn(
                          label: Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '성별',
                            style: TextStyle(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                      custom.DataColumn(
                          label: const Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                '생년월일',
                                style: TextStyle(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          onSort: sort),
                      custom.DataColumn(
                          label: const Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                '등록시간',
                                style: TextStyle(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          onSort: sort),
                      const custom.DataColumn(
                        label: Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'hrv',
                              style: TextStyle(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const custom.DataColumn(
                        label: Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'eeg',
                              style: TextStyle(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const custom.DataColumn(
                        label: Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '설문결과',
                              style: TextStyle(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const custom.DataColumn(
                        label: Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '수면결과',
                              style: TextStyle(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      // 새로 추가: PDF 병합
                      const custom.DataColumn(
                        label: Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'PDF 병합',
                              style: TextStyle(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: users
                        .map((e) => custom.DataRow(cells: [
                              custom.DataCell(
                                Align(
                                    alignment: Alignment.center,
                                    child: Text("${e.id}",
                                        textAlign: TextAlign.center)),
                              ),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: Text(e.name,
                                      textAlign: TextAlign.center))),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: Text(e.sexName,
                                      textAlign: TextAlign.center))),
                              custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: Text(e.birth ?? "",
                                      textAlign: TextAlign.center))),
                              custom.DataCell(
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    DateFormat('yyyy/MM/dd HH:mm').format(e.measurement_date),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              custom.DataCell(Align(
                                alignment: Alignment.center,
                                child: MouseRegion(
                                  cursor: MaterialStateMouseCursor.clickable,
                                  child: GestureDetector(
                                      onTap: () {
                                        context.push(ReportPage1.route,
                                            extra: {"user": e});
                                      },
                                      child: const Icon(Icons.search)),
                                ),
                              )),
                              custom.DataCell(Align(
                                alignment: Alignment.center,
                                child: MouseRegion(
                                  cursor: MaterialStateMouseCursor.clickable,
                                  child: GestureDetector(
                                      onTap: () {
                                        context.push(ReportPage2.route,
                                            extra: {"user": e});
                                      },
                                      child: const Icon(Icons.search)),
                                ),
                              )),
                              custom.DataCell(Align(
                                alignment: Alignment.center,
                                child: MouseRegion(
                                  cursor: MaterialStateMouseCursor.clickable,
                                  child: GestureDetector(
                                      onTap: () {
                                        context.push(ReportPage3.route,
                                            extra: {"user": e});
                                      },
                                      child: const Icon(Icons.search)),
                                ),
                              )),
                              custom.DataCell(Align(
                                alignment: Alignment.center,
                                child: MouseRegion(
                                  cursor: MaterialStateMouseCursor.clickable,
                                  child: GestureDetector(
                                      onTap: () {
                                        context.push(ReportPage4.route,
                                            extra: {"user": e});
                                      },
                                      child: const Icon(Icons.search)),
                                ),
                              )),
                              // PDF 병합 버튼
                              custom.DataCell(
                                Align(
                                  alignment: Alignment.center,
                                  child: MouseRegion(
                                    cursor: MaterialStateMouseCursor.clickable,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      onPressed: () => onClickMergePdf(e),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('병합'),
                                    ),
                                  ),
                                ),
                              ),
                            ]))
                        .toList(),
                  ),
                  const SizedBox(height: 50),
                  WebPagination(
                      currentPage: currentPage,
                      totalPage: (count / perPage).ceil(),
                      displayItemCount: perPage,
                      onPageChanged: (page) {
                        currentPage = page;
                        initData();
                      }),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        side:
                            const BorderSide(width: 2, color: Colors.white),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white,
                        elevation: 10.0,
                      ),
                      onPressed: () {
                        context.go(UsersPage.route);
                      },
                      child: const Text(
                        "",
                        style: TextStyle(color: Colors.white),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
