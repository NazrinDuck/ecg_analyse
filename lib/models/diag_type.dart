import 'package:flutter/material.dart';

enum DiagType {
  rAF(name: 'AF', icon: Icons.warning, color: Colors.red),
  rN(name: 'N', icon: Icons.check_circle, color: Colors.green),
  rPAT(name: 'PAT', icon: Icons.access_time, color: Colors.orange),
  unknown(name: 'Unknown', icon: Icons.help_outline, color: Colors.blue);

  const DiagType({required this.name, required this.icon, required this.color});

  factory DiagType.fromString(String name) {
    switch (name) {
      case 'AF':
        return DiagType.rAF;
      case 'N':
        return DiagType.rN;
      case 'PAT':
        return DiagType.rPAT;
      default:
        return DiagType.unknown;
    }
  }

  final String name;
  final IconData icon;
  final Color color;

  String translate() {
    switch (this) {
      case DiagType.rAF:
        return '房颤';
      case DiagType.rN:
        return '正常';
      case DiagType.rPAT:
        return '阵发性房性心动过速';
      case DiagType.unknown:
        return '未知';
    }
  }

  String get desc {
    switch (this) {
      case DiagType.rAF:
        return '房颤(AF)：心房颤动，心房快速不规则跳动，可能导致血栓和中风风险';
      case DiagType.rN:
        return '正常(N)：心电图显示正常心律，无异常';
      case DiagType.rPAT:
        return '阵发性心动过速(PAT)：突发性心跳加快，通常发作性且能自行终止';
      case DiagType.unknown:
        return '未知分类';
    }
  }
}
