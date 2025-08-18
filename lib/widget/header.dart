import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';

class Header extends StatefulWidget {
  final String headText;
  final UserModel userModel;
  const Header({Key? key, required this.headText, required this.userModel}) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final TextStyle h3 = const TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black);
  final TextStyle h4 = const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
      child: Column(
        children: [
          Row(
            children: [
              Text(widget.headText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20)),
              const Spacer(),
              Center(child: svgIcon(Assets.img.icon_logo, width: 60, height: 30)),
              const SizedBox(width: 10),
              Transform.translate(
                  offset: const Offset(0, -3),
                  child: Image.asset("assets/logo1.png", width: 130, height: 55)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Text("측정 일시: ", style: h3),
                    const SizedBox(width: 10),
                    Text(DateFormat('yyyy.MM.dd').format(widget.userModel.int_dt), style: h4),
                  ],
                ),
                Row(
                  children: [
                    Text("성명: ", style: h3),
                    const SizedBox(width: 10),
                    Text(widget.userModel.name, style: h4),
                  ],
                ),
                Row(
                  children: [
                    Text("성별: ", style: h3),
                    const SizedBox(width: 10),
                    Text("${widget.userModel.sexName}", style: h4),
                  ],
                ),
                Row(
                  children: [
                    Text("나이: ", style: h3),
                    const SizedBox(width: 10),
                    Text("${widget.userModel.age ?? ""}세", style: h4),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
