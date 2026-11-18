import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class GreenButton extends StatelessWidget {
  const GreenButton(this.label, {super.key, required this.onPressed, this.icon, this.loading = false, this.width});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double? width;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52, width: width ?? double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green, foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.greenSoft,
        elevation: 1, shadowColor: AppColors.green.withValues(alpha: .40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink)) :
      Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 21)],
      ]),
    ),
  );
}

class RoboCard extends StatelessWidget {
  const RoboCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.background = Colors.white, this.border});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color background;
  final Color? border;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: background, borderRadius: BorderRadius.circular(17),
      border: border == null ? null : Border.all(color: border!),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .055), blurRadius: 16, offset: const Offset(0, 7))],
    ),
    child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(17),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17),
        child: Padding(padding: padding, child: child))),
  );
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader(this.title, {super.key, this.onBack, this.trailing});
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 21),
    child: Row(children: [
      IconButton(onPressed: onBack ?? () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21)),
      Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, letterSpacing: -.6, fontWeight: FontWeight.w800))),
      SizedBox(width: 44, child: trailing),
    ]),
  );
}

class WaveFooter extends StatelessWidget {
  const WaveFooter({super.key, this.height = 55, this.opacity = 1});
  final double height;
  final double opacity;
  @override
  Widget build(BuildContext context) => IgnorePointer(child: Opacity(opacity: opacity, child:
    SizedBox(height: height, width: double.infinity,
      child: CustomPaint(painter: _WavePainter()))));
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final light = Path()..moveTo(0, size.height * .58)
      ..cubicTo(size.width*.28, size.height*.08, size.width*.57, size.height*.99, size.width, size.height*.12)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(light, Paint()..color = AppColors.green.withValues(alpha: .13));
    final front = Path()..moveTo(0, size.height * .85)
      ..cubicTo(size.width*.22, size.height*.50, size.width*.64, size.height*.90, size.width, size.height*.40)
      ..lineTo(size.width,size.height)..lineTo(0,size.height)..close();
    canvas.drawPath(front, Paint()..color = AppColors.green.withValues(alpha: .18));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChartPanel extends StatelessWidget {
  const ChartPanel({super.key, required this.distance, this.yaw = const [], this.title = 'Distance Over Time', this.rangeLabel = '10s', this.isPreview = false});
  final List<double> distance;
  final List<double> yaw;
  final String title;
  final String rangeLabel;
  final bool isPreview;
  @override
  Widget build(BuildContext context) => Container(
    height: yaw.isEmpty ? 195 : 245,
    padding: const EdgeInsets.fromLTRB(13, 14, 12, 10),
    decoration: BoxDecoration(color: AppColors.darkDeep, borderRadius: BorderRadius.circular(17)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (yaw.isEmpty) Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      if (yaw.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legend(AppColors.green, 'Distance (cm)'), const SizedBox(width: 14), _legend(AppColors.purple, 'Yaw (°)'),
      ]),
      if (isPreview) Padding(padding: const EdgeInsets.only(top: 4), child: Text('SAMPLE DATA', style: TextStyle(color: Colors.white.withValues(alpha: .48), fontSize: 9, letterSpacing: 1.3))),
      const SizedBox(height: 9),
      Expanded(child: CustomPaint(painter: _ChartPainter(distance, yaw), child: const SizedBox.expand())),
      Padding(padding: const EdgeInsets.only(left: 21, top: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _timeLabels().map((v) => Text(v, style: const TextStyle(color: Colors.white70, fontSize: 10))).toList())),
    ]),
  );

  List<String> _timeLabels() {
    if(rangeLabel=='20s') return const ['0s','5s','10s','15s','20s'];
    if(rangeLabel=='1m') return const ['0s','15s','30s','45s','1m'];
    if(rangeLabel=='5m') return const ['0m','1m','2m','3m','5m'];
    if(rangeLabel=='10m') return const ['0m','2m','4m','6m','10m'];
    return ['0s','2s','4s','6s','8s',rangeLabel];
  }

  Widget _legend(Color color, String label) => Row(children: [Container(width: 8,height: 8,decoration: BoxDecoration(shape: BoxShape.circle,color:color)), const SizedBox(width: 5), Text(label,style:const TextStyle(color:Colors.white,fontSize:11))]);
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.distance, this.yaw);
  final List<double> distance;
  final List<double> yaw;
  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 25.0;
    final plot = Rect.fromLTRB(padLeft, 8, size.width-3, size.height-6);
    final grid = Paint()..color = Colors.white.withValues(alpha: .07)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left,y), Offset(plot.right,y), grid);
      final num = (yaw.isEmpty ? 120 - i * 10 : 120 - i * 30);
      final painter = TextPainter(text: TextSpan(text: '$num',style: const TextStyle(color:Colors.white70,fontSize:9)),textDirection: TextDirection.ltr)..layout();
      painter.paint(canvas, Offset(0,y-5));
    }
    for (var i=0;i<=5;i++) {
      final x=plot.left+plot.width*i/5;
      canvas.drawLine(Offset(x,plot.top),Offset(x,plot.bottom),grid);
    }
    void drawData(List<double> data,Color color,double min,double max) {
      if (data.length < 2) return;
      final path=Path();
      for(var i=0;i<data.length;i++) {
        final x=plot.left+plot.width*i/(data.length-1);
        final y=plot.bottom-(data[i]-min)/(max-min)*plot.height;
        if(i==0) { path.moveTo(x,y.clamp(plot.top,plot.bottom).toDouble()); }
        else { path.lineTo(x,y.clamp(plot.top,plot.bottom).toDouble()); }
      }
      canvas.save(); canvas.clipRect(plot);
      canvas.drawPath(path,Paint()..color=color.withValues(alpha:.14)..strokeWidth=6..style=PaintingStyle.stroke..strokeCap=StrokeCap.round);
      canvas.drawPath(path,Paint()..color=color..strokeWidth=2.25..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
      canvas.restore();
    }
    drawData(distance,AppColors.green,yaw.isEmpty?80:0,120);
    if (yaw.isNotEmpty) drawData(yaw,AppColors.purple,0,120);
  }
  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.distance != distance || old.yaw != yaw;
}

class CarArt extends StatelessWidget {
  const CarArt({super.key, this.height = 215});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(height: height, width: double.infinity, child:
      Image.asset('assets/images/robot_cutout.png', fit: BoxFit.contain));
}

class AppScrollPage extends StatelessWidget {
  const AppScrollPage({super.key, required this.title, required this.children, this.trailing});
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    body: SafeArea(child: Stack(children: [
      Positioned(left:0,right:0,bottom:0,child:const WaveFooter()),
      Column(children: [ScreenHeader(title,trailing:trailing), Expanded(child: ListView(padding:const EdgeInsets.fromLTRB(20,0,20,80),children:children))]),
    ])),
  );
}

String showNumber(double? value, {int digits=1, String unit=''}) => value == null ? '—' : '${value.toStringAsFixed(digits)}$unit';

void showNotice(BuildContext context, String? message) {
  if (message == null || message.isEmpty || !context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.dark, behavior: SnackBarBehavior.floating));
}
