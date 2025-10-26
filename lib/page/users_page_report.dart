import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/page/users_page.dart';
import 'package:omnifit_front/page/page_1.dart';
import 'package:omnifit_front/page/page_2.dart';
import 'package:omnifit_front/page/report_page1.dart';
import 'package:omnifit_front/page/report_page2.dart';

import 'package:omnifit_front/page/sleep_result.dart'; 
import 'package:omnifit_front/page/survey_page.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:omnifit_front/widget/custom_data_table.dart' as custom;
import 'package:omnifit_front/widget/web_pagination.dart';
import 'package:http/http.dart' as http;

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
  List<dynamic> sortList = [
    "pk", "name", "", "birth", "measurement_date"
  ];
  List<String> isAscList = [
    "True", "False"
  ];

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
      url = Uri.parse('$uri?page=$currentPage&name=$name&sorting=${sortList[sortColumnIndex]}&descending=${isAscList[isAscSort ? 0 : 1]}');
    } else {
      url = Uri.parse('$uri?page=$currentPage&sorting=${sortList[sortColumnIndex]}&descending=${isAscList[isAscSort ? 0 : 1]}');
    }
    
    final response = await http.get(url, headers: {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'});

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
                            side: const BorderSide(width: 2, color: Colors.green),
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
                      Center(child: svgIcon(Assets.img.icon_logo, width: 80, height: 40)),
                      const SizedBox(width: 10),
                      Transform.translate(offset: const Offset(0, -3), child: Image.asset("assets/logo1.png", width: 150, height: 70)),
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
                                'hrv리포트',
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
                                'eeg리포트',
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
                                '설문결과리포트',
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
                                '수면결과리포트',
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
                                  Align(alignment: Alignment.center, child: Text("${e.id}", textAlign: TextAlign.center)),
                                ),
                                custom.DataCell(Align(alignment: Alignment.center, child: Text(e.name, textAlign: TextAlign.center))),
                                custom.DataCell(Align(alignment: Alignment.center, child: Text(e.sexName, textAlign: TextAlign.center))),
                                custom.DataCell(Align(alignment: Alignment.center, child: Text(e.birth ?? "", textAlign: TextAlign.center))),
                                custom.DataCell(Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      DateFormat.yMd().add_jm().format(e.measurement_date),
                                      textAlign: TextAlign.center,
                                    ))),
                                custom.DataCell(Align(
                                  alignment: Alignment.center,
                                  child: MouseRegion(
                                    cursor: MaterialStateMouseCursor.clickable,
                                    child: GestureDetector(
                                        onTap: () {
                                          context.push(ReportPage1.route, extra: {"user": e});
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
                                          context.push(ReportPage2.route, extra: {"user": e});
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
                                          context.push(SurveyPage.route, extra: {"user": e});
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
                                          context.push(SleepResult.route, extra: {"user": e});
                                        },
                                        child: const Icon(Icons.search)),
                                  ),
                                )),

                              ]))
                          .toList()),
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
                          side: const BorderSide(width: 2, color: Colors.white),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white,
                          elevation: 10.0,
                        ),
                        onPressed: () {
                          context.go(UsersPage.route);

                        },
                        child: const Text(
                          "돌아가기",
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
