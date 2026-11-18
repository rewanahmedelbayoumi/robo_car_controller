import 'package:flutter/material.dart';
import '../services/robot_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/robo_ui.dart';
import 'robot_pages.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key,required this.controller});
  final RobotController controller;
  @override State<HomeShell> createState()=>_HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int tab=0;
  void open(Widget screen)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>screen));
  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppColors.paper,
    body:IndexedStack(index:tab,children:[
      _HomeDashboard(controller:widget.controller,open:open),
      ManualPage(controller:widget.controller,onBack:()=>setState(()=>tab=0)),
      LivePage(controller:widget.controller,onBack:()=>setState(()=>tab=0)),
      SettingsPage(controller:widget.controller,onBack:()=>setState(()=>tab=0)),
    ]),
    bottomNavigationBar:SafeArea(top:false,child:Container(
      decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:AppColors.line))),
      height:67,
      child:Row(children:[
        _bottom(Icons.home_rounded,'Home',0),
        _bottom(Icons.sports_esports_rounded,'Control',1),
        _bottom(Icons.bar_chart_rounded,'Data',2),
        _bottom(Icons.settings_outlined,'Settings',3),
      ]),
    )),
  );
  Widget _bottom(IconData icon,String label,int i)=>Expanded(child:InkWell(onTap:(){setState(()=>tab=i);},child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    Icon(icon,size:24,color:tab==i?AppColors.green:const Color(0xFF9CA4A3)),
    const SizedBox(height:2),Text(label,style:TextStyle(fontSize:11,fontWeight:tab==i?FontWeight.w800:FontWeight.w600,color:tab==i?AppColors.ink:AppColors.muted)),
  ])));
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.controller,required this.open});
  final RobotController controller;
  final void Function(Widget) open;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_)=>
    Container(color:AppColors.darkDeep,child:SafeArea(bottom:false,child:
      LayoutBuilder(builder:(context,constraints)=>SingleChildScrollView(child:Container(
        constraints:BoxConstraints(minHeight:constraints.maxHeight),
        padding:const EdgeInsets.fromLTRB(17,18,17,20),
        decoration:const BoxDecoration(gradient:LinearGradient(colors:[AppColors.darkDeep,AppColors.dark,Color(0xFF092C25)],begin:Alignment.topLeft,end:Alignment.bottomRight)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('RoboCar',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:-1)),
              Row(children:[Container(width:7,height:7,decoration:BoxDecoration(color:controller.connected?AppColors.green:Colors.amber,shape:BoxShape.circle)),const SizedBox(width:6),Text(controller.connected?'Connected':controller.demoPreview?'Preview Mode':'Disconnected',style:TextStyle(fontSize:12,color:controller.connected?AppColors.greenBright:Colors.white70))]),
            ])),
            IconButton(onPressed:()=>open(SettingsPage(controller:controller)),icon:const Icon(Icons.settings_outlined,color:Colors.white,size:27)),
          ]),
          const CarArt(height:143),
          const SizedBox(height:11),
          GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:11,crossAxisSpacing:11,childAspectRatio:1.70,children:[
            _tile(Icons.sports_esports_rounded,'Manual Control',true,()=>open(ManualPage(controller:controller))),
            _tile(Icons.code_rounded,'Run Program',false,()=>open(ProgramPage(controller:controller))),
            _tile(Icons.bar_chart_rounded,'Live Data',false,()=>open(LivePage(controller:controller))),
            _tile(Icons.sensors_rounded,'Sensors',false,()=>open(SensorsPage(controller:controller))),
            _tile(Icons.assignment_outlined,'Calibration',false,()=>open(CalibrationPage(controller:controller))),
            _tile(Icons.analytics_outlined,'Analytics',false,()=>open(AnalyticsPage(controller:controller))),
          ]),
        ]),
      ))),
    )))
  ;
  Widget _tile(IconData icon,String title,bool active,VoidCallback onTap)=>RoboCard(
    padding:EdgeInsets.zero,background:active?AppColors.green:const Color(0xFFFAFBFA),onTap:onTap,
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(icon,color:AppColors.dark,size:29),const SizedBox(height:8),
      Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:13.5,fontWeight:FontWeight.w800,color:AppColors.ink)),
    ]),
  );
}
