import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/robot_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/robo_ui.dart';
import 'home_shell.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.controller});
  final RobotController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkDeep,
    body: Stack(fit:StackFit.expand,children:[
      const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF0C2925),Color(0xFF06211D)],begin:Alignment.topLeft,end:Alignment.bottomRight))),
      const CustomPaint(painter:_SplashWavePainter()),
      SafeArea(child: Padding(padding:const EdgeInsets.fromLTRB(32,40,32,32),child:
        Column(children:[
          const Spacer(flex:2),
          const Icon(Icons.directions_car_outlined,color:AppColors.green,size:77),
          const SizedBox(height:3),
          const Text('RoboCar',style:TextStyle(color:Colors.white,fontSize:39,fontWeight:FontWeight.w900,letterSpacing:-1.9)),
          const Text('Controller',style:TextStyle(color:AppColors.green,fontSize:25,fontWeight:FontWeight.w600,letterSpacing:-.7)),
          const Spacer(flex:2),
          const CarArt(height:220),
          const Spacer(flex:3),
          GreenButton('Get Started',icon:Icons.arrow_forward_rounded,onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>OnboardingScreen(controller:controller)))),
        ]))),
    ]),
  );
}

class _SplashWavePainter extends CustomPainter {
  const _SplashWavePainter();
  @override
  void paint(Canvas canvas,Size size){
    final base=Paint()..color=AppColors.green.withValues(alpha:.09);
    final path=Path()..moveTo(0,size.height*.38)
      ..cubicTo(size.width*.35,size.height*.43,size.width*.55,size.height*.50,size.width,size.height*.33)
      ..lineTo(size.width,size.height*.70)
      ..cubicTo(size.width*.60,size.height*.55,size.width*.35,size.height*.49,0,size.height*.60)
      ..close();
    canvas.drawPath(path,base);
    final highlight=Path()..moveTo(0,size.height*.54)
      ..quadraticBezierTo(size.width*.17,size.height*.45,size.width*.42,size.height*.49)
      ..quadraticBezierTo(size.width*.15,size.height*.52,0,size.height*.58)
      ..close();
    canvas.drawPath(highlight,Paint()..color=AppColors.green.withValues(alpha:.82));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});
  final RobotController controller;
  @override
  State<OnboardingScreen> createState()=>_OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  int step=0;
  static const slides = [
    ('Control · Monitor · Program', 'A smart and simple app to control your robot car, read sensors, and run experiments.', Icons.smart_toy_outlined),
    ('Drive With Confidence', 'Move RoboCar in any direction using the manual controller and a precise speed slider.', Icons.sports_esports_rounded),
    ('Live Sensor Insights', 'Watch distance, orientation, calibration results, and analytics in one place.', Icons.query_stats_rounded),
    ('Ready For Experiments', 'Connect to your ESP32 using Wi-Fi or Bluetooth and test new movement programs.', Icons.code_rounded),
  ];
  void next(){ if(step==slides.length-1){openConnect();}else{setState(()=>step++);} }
  void openConnect()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ConnectScreen(controller:widget.controller)));
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor:Colors.white,body:SafeArea(child:
    Padding(padding:const EdgeInsets.fromLTRB(25,22,25,28),child:Column(children:[
      const Spacer(flex:2),
      Text(slides[step].$1,textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,letterSpacing:-.9,color:AppColors.ink)),
      const SizedBox(height:15),
      Padding(padding:const EdgeInsets.symmetric(horizontal:9),child:Text(slides[step].$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:14.5,height:1.5,color:AppColors.ink))),
      const Spacer(flex:2),
      if(step==0) const CarArt(height:235) else Column(children:[
        Container(height:95,width:95,decoration:const BoxDecoration(color:AppColors.greenSoft,shape:BoxShape.circle),child:Icon(slides[step].$3,size:49,color:AppColors.green)),
        const SizedBox(height:32),const CarArt(height:180),
      ]),
      const Spacer(flex:2),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(slides.length,(i)=>AnimatedContainer(duration:const Duration(milliseconds:200),height:10,width:10,margin:const EdgeInsets.symmetric(horizontal:4),decoration:BoxDecoration(color:i==step?AppColors.green:const Color(0xFFD5D8D6),shape:BoxShape.circle)))),
      const Spacer(flex:2),
      Row(children:[
        Expanded(child:SizedBox(height:49,child:FilledButton(onPressed:openConnect,style:FilledButton.styleFrom(backgroundColor:const Color(0xFFF4F4F4),foregroundColor:AppColors.ink,shape:const StadiumBorder()),child:const Text('Skip',style:TextStyle(fontWeight:FontWeight.bold))))),
        const SizedBox(width:14),
        Expanded(child:GreenButton(step==slides.length-1?'Connect':'Next',icon:Icons.arrow_forward_rounded,onPressed:next)),
      ]),
    ]))),
  );
}

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key,required this.controller});
  final RobotController controller;
  Future<void> wifiDialog(BuildContext context) async {
    final input=TextEditingController(text:controller.ipAddress);
    await showDialog<void>(context:context,builder:(dialogContext)=>AlertDialog(
      title:const Text('Connect via Wi-Fi'),
      content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Connect your phone to the robot Wi-Fi network, then enter its IP address.'),
        const SizedBox(height:13),
        TextField(controller:input,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Robot IP address',hintText:'192.168.4.1',prefixIcon:Icon(Icons.wifi_rounded))),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
        FilledButton(onPressed:()async{
          controller.setIp(input.text);
          Navigator.pop(dialogContext);
          final success=await controller.connectWifi();
          if(!context.mounted)return;
          if(success) {Navigator.push(context,MaterialPageRoute(builder:(_)=>ConnectionSuccessScreen(controller:controller)));}
          else {showNotice(context,controller.error);}
        },child:const Text('Connect'))],
    ));
    input.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor:Colors.white,body:SafeArea(child:Stack(children:[
    const Positioned(bottom:0,left:0,right:0,child:WaveFooter(height:120)),
    Column(children:[
      const SizedBox(height:24),
      Container(height:85,width:85,decoration:const BoxDecoration(shape:BoxShape.circle,color:AppColors.greenSoft),child:const Icon(Icons.link_rounded,color:AppColors.green,size:49)),
      const SizedBox(height:15),
      const Text('Connect to Robot',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.8)),
      const SizedBox(height:6),
      const Text('Choose a connection method',style:TextStyle(fontSize:13,color:AppColors.muted)),
      const SizedBox(height:27),
      Padding(padding:const EdgeInsets.symmetric(horizontal:19),child:Column(children:[
        RoboCard(border:AppColors.green,padding:const EdgeInsets.symmetric(horizontal:16,vertical:17),background:const Color(0xFFF6FCF5),onTap:()=>wifiDialog(context),child:const Row(children:[
          Icon(Icons.wifi_rounded,color:AppColors.green,size:33),SizedBox(width:15),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Wi-Fi (HTTP)',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),SizedBox(height:4),Text('Connect to the robot over your local network',style:TextStyle(fontSize:12,height:1.35))])),
          Icon(Icons.chevron_right_rounded,color:AppColors.green),
        ])),
        const SizedBox(height:16),
        RoboCard(padding:const EdgeInsets.symmetric(horizontal:16,vertical:17),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>BleDiscoverScreen(controller:controller))),child:const Row(children:[
          Icon(Icons.bluetooth_rounded,color:AppColors.blue,size:34),SizedBox(width:15),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Bluetooth (BLE)',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),SizedBox(height:4),Text('Connect directly to the robot via Bluetooth',style:TextStyle(fontSize:12,height:1.35))])),
          Icon(Icons.chevron_right_rounded,color:AppColors.muted),
        ])),
      ])),
      const Spacer(),const CarArt(height:185),const SizedBox(height:11),
      TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HomeShell(controller:controller))),child:const Text('Explore preview without connecting',style:TextStyle(color:AppColors.muted,fontWeight:FontWeight.w600))),
      const SizedBox(height:12),
    ]),
  ])));
}

class BleDiscoverScreen extends StatefulWidget {
  const BleDiscoverScreen({super.key,required this.controller});
  final RobotController controller;
  @override
  State<BleDiscoverScreen> createState()=>_BleDiscoverScreenState();
}
class _BleDiscoverScreenState extends State<BleDiscoverScreen> {
  @override
  void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_){widget.controller.scanBle();});}
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:widget.controller,builder:(context,_)=>AppScrollPage(title:'Bluetooth Devices',children:[
    const Text('Turn on Bluetooth. Choose your ESP32 robot from the discovered devices.',style:TextStyle(color:AppColors.muted)),
    const SizedBox(height:21),
    GreenButton(widget.controller.scanning?'Scanning…':'Scan Again',icon:Icons.bluetooth_searching_rounded,onPressed:widget.controller.scanning?null:()=>widget.controller.scanBle()),
    const SizedBox(height:20),
    if(widget.controller.devices.isEmpty) RoboCard(child:Padding(padding:const EdgeInsets.all(18),child:Center(child:Text(widget.controller.scanning?'Searching for nearby BLE devices…':'No devices found. Tap Scan Again.',style:const TextStyle(color:AppColors.muted)))))
    else ...widget.controller.devices.map((ScanResult result) => Padding(padding:const EdgeInsets.only(bottom:12),child:RoboCard(onTap:widget.controller.connecting?null:()async{
      final ok=await widget.controller.connectBle(result);
      if(!context.mounted)return;
      if(ok){Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ConnectionSuccessScreen(controller:widget.controller)));}
      else{showNotice(context,widget.controller.error);}
    },child:Row(children:[const Icon(Icons.bluetooth_rounded,color:AppColors.blue),const SizedBox(width:12),Expanded(child:Text(result.device.platformName.isEmpty?result.device.remoteId.toString():result.device.platformName,style:const TextStyle(fontWeight:FontWeight.bold))),const Icon(Icons.chevron_right_rounded)])))),
    if(widget.controller.connecting) const Center(child:Padding(padding:EdgeInsets.all(20),child:CircularProgressIndicator(color:AppColors.green))),
    if(widget.controller.error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(widget.controller.error!,style:const TextStyle(color:Colors.red))),
  ]));
}

class ConnectionSuccessScreen extends StatelessWidget {
  const ConnectionSuccessScreen({super.key,required this.controller});
  final RobotController controller;
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_)=>Scaffold(backgroundColor:Colors.white,body:SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(23,30,23,28),child:Column(children:[
    const Spacer(flex:2),
    Container(height:105,width:105,decoration:const BoxDecoration(shape:BoxShape.circle,color:AppColors.greenSoft),child:const Center(child:CircleAvatar(radius:36,backgroundColor:AppColors.green,child:Icon(Icons.check_rounded,size:50,color:Colors.white)))),
    const SizedBox(height:16),
    const Text('Connected!',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,letterSpacing:-.8)),
    const SizedBox(height:5),const Text('RoboCar is ready',style:TextStyle(color:AppColors.muted,fontSize:13)),
    const SizedBox(height:30),
    RoboCard(child:Column(children:[
      _info(Icons.wifi_rounded,'IP Address',controller.mode==ConnectionMode.wifi?controller.ipAddress:'—'),
      const Divider(height:23,color:AppColors.line),
      _info(Icons.bluetooth_rounded,'BLE Name',controller.bleName),
      const Divider(height:23,color:AppColors.line),
      _info(Icons.battery_full_rounded,'Battery',showNumber(controller.battery,digits:0,unit:'%')),
    ])),
    const Spacer(flex:4),
    GreenButton('Continue',onPressed:()=>Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>HomeShell(controller:controller)),(route)=>false)),
  ])))));
  Widget _info(IconData icon,String title,String value)=>Row(children:[Icon(icon,color:AppColors.dark,size:23),const SizedBox(width:14),Text(title,style:const TextStyle(fontSize:13)),const Spacer(),Text(value,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700))]);
}
