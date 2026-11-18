import 'package:flutter/material.dart';
import '../services/robot_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/robo_ui.dart';
import 'welcome_screens.dart';

class ManualPage extends StatefulWidget {
  const ManualPage({super.key,required this.controller,this.onBack});
  final RobotController controller;
  final VoidCallback? onBack;
  @override State<ManualPage> createState()=>_ManualPageState();
}
class _ManualPageState extends State<ManualPage> {
  bool holding=false;
  Future<void> move(String command) async {
    if(!widget.controller.connected){showNotice(context,'Connect to RoboCar before driving. Preview mode does not move the robot.');return;}
    holding=true;
    final ok=await widget.controller.sendCommand(command);
    if(!ok && mounted)showNotice(context,widget.controller.error);
  }
  void release(){if(holding){holding=false;widget.controller.stop();}}
  @override void dispose(){release();super.dispose();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.controller,builder:(context,_)=>Scaffold(
    backgroundColor:AppColors.paper,body:SafeArea(child:Stack(children:[
      const Positioned(bottom:0,left:0,right:0,child:WaveFooter(height:74)),
      Column(children:[
        ScreenHeader('Manual Control',onBack:widget.onBack),
        Padding(padding:const EdgeInsets.symmetric(horizontal:25),child:Row(children:[
          Expanded(child:_statusChip(Icons.battery_full_rounded,showNumber(widget.controller.shownBattery,digits:0,unit:'%'))),
          const SizedBox(width:12),
          Expanded(child:_statusChip(Icons.wifi_rounded,widget.controller.connected?'Connected':'Preview')),
        ])),
        const Spacer(flex:2),
        SizedBox(width:275,height:275,child:Stack(alignment:Alignment.center,children:[
          Container(height:230,width:230,decoration:const BoxDecoration(color:Color(0xFFF6F8F6),shape:BoxShape.circle)),
          Align(alignment:const Alignment(0,-.81),child:_direction(Icons.keyboard_arrow_up_rounded,'FORWARD')),
          Align(alignment:const Alignment(-.78,0),child:_direction(Icons.keyboard_arrow_left_rounded,'LEFT')),
          Align(alignment:const Alignment(.78,0),child:_direction(Icons.keyboard_arrow_right_rounded,'RIGHT')),
          Align(alignment:const Alignment(0,.81),child:_direction(Icons.keyboard_arrow_down_rounded,'BACKWARD')),
          GestureDetector(onTap:()async{await widget.controller.stop();if(mounted)showNotice(context,'STOP command sent');},child:Container(height:68,width:68,decoration:BoxDecoration(shape:BoxShape.circle,color:AppColors.green,boxShadow:[BoxShadow(color:AppColors.green.withValues(alpha:.3),blurRadius:17)]),child:const Icon(Icons.stop_rounded,size:28,color:Colors.white))),
        ])),
        const Spacer(flex:2),
        Padding(padding:const EdgeInsets.symmetric(horizontal:28),child:Column(children:[
          Row(children:[const Text('Speed',style:TextStyle(fontSize:15,fontWeight:FontWeight.w800)),const Spacer(),Text('${widget.controller.speed.round()}%',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800))]),
          SliderTheme(data:SliderTheme.of(context).copyWith(activeTrackColor:AppColors.green,thumbColor:AppColors.green,inactiveTrackColor:const Color(0xFFD5DAD6),overlayColor:AppColors.greenSoft,trackHeight:5),
            child:Slider(value:widget.controller.speed,min:0,max:100,onChanged:widget.controller.setSpeed)),
          const SizedBox(height:8),
          const Text('Press and hold a direction to move. Release to stop.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted)),
        ])),
        const Spacer(),
      ]),
    ])),
  ));
  Widget _statusChip(IconData icon,String label)=>RoboCard(padding:const EdgeInsets.symmetric(horizontal:11,vertical:11),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:20,color:AppColors.dark),const SizedBox(width:8),Flexible(child:Text(label,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)))]));
  Widget _direction(IconData icon,String command)=>GestureDetector(
    behavior:HitTestBehavior.opaque,
    onTapDown:(_)=>move(command),onTapUp:(_)=>release(),onTapCancel:release,
    child:Container(height:66,width:66,decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFFF8F9F8),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.07),blurRadius:10,offset:const Offset(0,5))]),child:Icon(icon,color:AppColors.dark,size:37)),
  );
}

class LivePage extends StatelessWidget {
  const LivePage({super.key,required this.controller,this.onBack});
  final RobotController controller;
  final VoidCallback? onBack;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_)=>Scaffold(backgroundColor:AppColors.paper,body:SafeArea(child:Column(children:[
    ScreenHeader('Live Data',onBack:onBack,trailing:IconButton(onPressed:()=>controller.refreshStatus(),icon:const Icon(Icons.refresh_rounded,size:23))),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(17,0,17,34),children:[
      RoboCard(padding:const EdgeInsets.symmetric(horizontal:17,vertical:15),child:Row(children:[
        Container(width:55,height:55,decoration:const BoxDecoration(color:AppColors.greenSoft,shape:BoxShape.circle),child:const Icon(Icons.sensors_rounded,color:AppColors.green,size:32)),
        const SizedBox(width:15),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Distance (TOF)',style:TextStyle(fontWeight:FontWeight.w700,fontSize:13)),
          const SizedBox(height:3),Text(showNumber(controller.shownDistance,digits:2,unit:' cm'),style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,letterSpacing:-.9)),
        ]),
        const Spacer(),if(controller.isDemo)const Text('PREVIEW',style:TextStyle(fontSize:9,color:AppColors.muted)),
      ])),
      const SizedBox(height:14),
      RoboCard(child:Row(children:[
        Container(height:70,width:60,decoration:const BoxDecoration(color:AppColors.greenSoft,shape:BoxShape.circle),child:const Icon(Icons.device_hub_rounded,color:AppColors.green,size:32)),
        const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('IMU (MPU-6050)',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),
          const SizedBox(height:13),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
            _value('Roll',showNumber(controller.shownRoll,unit:'°')),
            _value('Pitch',showNumber(controller.shownPitch,unit:'°')),
            _value('Yaw',showNumber(controller.shownYaw,unit:'°')),
          ]),
        ])),
      ])),
      const SizedBox(height:21),
      ChartPanel(distance:controller.shownDistanceHistory,isPreview:controller.isDemo),
      const SizedBox(height:16),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(controller.connected?Icons.circle:Icons.info_outline,color:controller.connected?AppColors.green:AppColors.muted,size:12),const SizedBox(width:6),Flexible(child:Text(controller.isDemo?'Example values. Connect to ESP32 for live telemetry.':controller.connected?'Live readings update every 2 seconds.':'No sensor data; connect to robot.',style:const TextStyle(color:AppColors.muted,fontSize:11)))]),
    ])),
  ]))));
  Widget _value(String name,String value)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(fontSize:11,color:AppColors.muted)),const SizedBox(height:3),Text(value,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16))]);
}

class SensorsPage extends StatelessWidget {
  const SensorsPage({super.key,required this.controller});
  final RobotController controller;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_)=>AppScrollPage(title:'Sensors',children:[
    const Text('Sensor readings reported by the connected ESP32.',style:TextStyle(color:AppColors.muted)),const SizedBox(height:22),
    _sensor(Icons.sensors_rounded,'TOF400F · Distance',showNumber(controller.shownDistance,digits:2,unit:' cm'),'Long-range distance sensor'),
    const SizedBox(height:14),
    _sensor(Icons.screen_rotation_rounded,'MPU-6050 · Roll',showNumber(controller.shownRoll,unit:'°'),'Robot tilt along the roll axis'),
    const SizedBox(height:14),
    _sensor(Icons.screen_rotation_alt_rounded,'MPU-6050 · Pitch',showNumber(controller.shownPitch,unit:'°'),'Robot tilt along the pitch axis'),
    const SizedBox(height:14),
    _sensor(Icons.explore_outlined,'MPU-6050 · Yaw',showNumber(controller.shownYaw,unit:'°'),'Yaw estimate depends on firmware fusion'),
    const SizedBox(height:20),
    if(controller.isDemo)const Text('Preview values are illustrative, not sensor measurements.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted,fontSize:12)),
    const SizedBox(height:14),GreenButton('Refresh Sensors',icon:Icons.refresh,onPressed:controller.connected?()=>controller.refreshStatus():null),
  ]));
  Widget _sensor(IconData icon,String title,String value,String description)=>RoboCard(child:Row(children:[Icon(icon,color:AppColors.green,size:28),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(description,style:const TextStyle(fontSize:11,color:AppColors.muted))])),Text(value,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900))]));
}

class CalibrationPage extends StatelessWidget {
  const CalibrationPage({super.key,required this.controller});
  final RobotController controller;
  Future<void> editTarget(BuildContext context)async{
    final text=TextEditingController(text:controller.targetDistance.toStringAsFixed(2));
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Set Target Distance'),content:TextField(controller:text,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(suffixText:'cm',hintText:'100.00')),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),FilledButton(onPressed:(){final value=double.tryParse(text.text);if(value!=null&&value>0&&value<10000){controller.setTarget(value);Navigator.pop(dialog);}else{showNotice(context,'Enter a valid distance greater than 0 cm.');}},child:const Text('Save'))]));
    text.dispose();
  }
  Future<void> execute(BuildContext context,String kind)async{
    bool ok=false;
    if(kind=='measure'){
      if(!controller.connected){showNotice(context,'Connect to your robot before measuring.');return;}
      await controller.refreshStatus();
      if(!context.mounted)return;
      if(controller.distance==null){showNotice(context,'No distance value was returned by /status.');return;}
      showNotice(context,'Measured distance: ${showNumber(controller.distance,digits:2,unit:' cm')}');return;
    }
    if(kind=='bench')ok=await controller.requestCalibration('/bench',{'target':controller.targetDistance});
    if(kind=='auto')ok=await controller.requestCalibration('/calibrate',{'target':controller.targetDistance});
    if(!context.mounted)return;
    showNotice(context,ok?'Robot responded successfully. Check the latest setpoint.':controller.error);
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_)=>AppScrollPage(title:'Calibration',children:[
    const SizedBox(height:9),
    _option(Icons.gps_fixed_rounded,'Set Target Distance','${controller.targetDistance.toStringAsFixed(2)} cm',()=>editTarget(context)),
    const SizedBox(height:13),
    _option(Icons.tune_rounded,'Adjusted Setpoint','${controller.adjustedSetpoint.toStringAsFixed(2)} cm',()=>showNotice(context,'Adjusted setpoint is provided by compatible ESP32 firmware.')),
    const SizedBox(height:13),
    _option(Icons.play_circle_fill_rounded,'Start Measurement','Read TOF sensor value',()=>execute(context,'measure')),
    const SizedBox(height:13),
    _option(Icons.autorenew_rounded,'Run Bench Test','Requires POST /bench',()=>execute(context,'bench')),
    const SizedBox(height:13),
    _option(Icons.my_location_rounded,'Auto Calibration','Requires POST /calibrate',()=>execute(context,'auto')),
    const SizedBox(height:19),
    const Text('Calibration API endpoints are firmware-dependent. The original project did not include calibration endpoints; unsupported requests return a visible error.',style:TextStyle(color:AppColors.muted,fontSize:11,height:1.6)),
  ]));
  Widget _option(IconData icon,String title,String desc,VoidCallback action)=>RoboCard(onTap:action,padding:const EdgeInsets.symmetric(horizontal:16,vertical:17),child:Row(children:[Icon(icon,size:28,color:AppColors.green),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(desc,style:const TextStyle(fontSize:12,color:AppColors.muted))])),const Icon(Icons.chevron_right_rounded,color:AppColors.muted)]));
}

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key,required this.controller});
  final RobotController controller;
  @override State<ProgramPage> createState()=>_ProgramPageState();
}
class _ProgramPageState extends State<ProgramPage> {
  bool custom=false;
  int selected=0;
  final List<RobotStep> customSteps=[const RobotStep('FORWARD',Duration(seconds:2))];
  static const presets=['Move Forward (3 s)','Square Path','Obstacle Avoidance','Self Calibration'];
  Future<void> run()async{
    if(widget.controller.runningProgram){await widget.controller.stop();return;}
    if(!widget.controller.connected){showNotice(context,'Connect to RoboCar before running a program.');return;}
    if(custom){await widget.controller.runSteps(List.of(customSteps));}
    else if(selected==0){await widget.controller.runSteps([const RobotStep('FORWARD',Duration(seconds:3))]);}
    else if(selected==1){
      // Illustrative sequence; turn durations must be calibrated to hardware.
      final steps=<RobotStep>[];
      for(var i=0;i<4;i++) {steps.add(const RobotStep('FORWARD',Duration(milliseconds:1300)));steps.add(const RobotStep('RIGHT',Duration(milliseconds:500)));}
      await widget.controller.runSteps(steps);
    } else if(selected==2){showNotice(context,'Obstacle avoidance requires autonomous firmware and confirmed obstacle telemetry. It cannot be safely simulated with blind movement commands.');return;}
    else if(selected==3){await widget.controller.requestCalibration('/calibrate',{'target':widget.controller.targetDistance});}
    if(mounted && widget.controller.error!=null)showNotice(context,widget.controller.error);
  }
  Future<void> addCustom()async{
    String direction='FORWARD'; double seconds=2;
    await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(title:const Text('Add Movement Step'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(initialValue:direction,decoration:const InputDecoration(labelText:'Command'),items:const ['FORWARD','BACKWARD','LEFT','RIGHT','STOP'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)setDialog(()=>direction=v);}),
      const SizedBox(height:15),Text('Duration: ${seconds.toStringAsFixed(1)}s'),Slider(value:seconds,min:.5,max:8,divisions:15,onChanged:(v)=>setDialog(()=>seconds=v)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),FilledButton(onPressed:(){setState(()=>customSteps.add(RobotStep(direction,Duration(milliseconds:(seconds*1000).round()))));Navigator.pop(dialog);},child:const Text('Add'))])));
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.controller,builder:(context,_)=>AppScrollPage(title:'Run Program',children:[
    const SizedBox(height:9),
    Container(height:45,decoration:BoxDecoration(color:const Color(0xFFF2F4F1),borderRadius:BorderRadius.circular(12)),child:Row(children:[_segment('Preset',!custom,()=>setState(()=>custom=false)),_segment('Custom',custom,()=>setState(()=>custom=true))])),
    const SizedBox(height:18),
    if(!custom)...List.generate(presets.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:13),child:RoboCard(
      background:selected==i?const Color(0xFFF7FCF3):Colors.white,
      border:selected==i?AppColors.green:null,
      padding:const EdgeInsets.symmetric(vertical:15,horizontal:13),
      onTap:()=>setState(()=>selected=i),
      child:Row(children:[const Icon(Icons.play_circle_fill_rounded,color:AppColors.blue,size:24),const SizedBox(width:11),Expanded(child:Text(presets[i],style:const TextStyle(fontWeight:FontWeight.w700,fontSize:14))),const Icon(Icons.more_vert,color:AppColors.muted,size:19)]),
    ))) else ...[
      const Text('Custom Program Steps',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:14),
      ...List.generate(customSteps.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:12),child:RoboCard(child:Row(children:[CircleAvatar(backgroundColor:AppColors.greenSoft,child:Text('${i+1}',style:const TextStyle(color:AppColors.dark))),const SizedBox(width:12),Expanded(child:Text('${customSteps[i].command} (${(customSteps[i].duration.inMilliseconds/1000).toStringAsFixed(1)} s)',style:const TextStyle(fontWeight:FontWeight.bold))),IconButton(onPressed:()=>setState(()=>customSteps.removeAt(i)),icon:const Icon(Icons.close_rounded,size:18))])))),
      OutlinedButton.icon(onPressed:addCustom,icon:const Icon(Icons.add_rounded),label:const Text('Add Step')),
    ],
    const SizedBox(height:26),
    if(widget.controller.runningProgram)GreenButton('STOP',icon:Icons.stop_rounded,onPressed:()=>widget.controller.stop())
    else GreenButton('Run',icon:Icons.play_arrow_rounded,onPressed:run),
    const SizedBox(height:17),
    const Text('Movement steps automatically send STOP after each action. The robot must remain in a safe, clear test area.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted,height:1.55)),
  ]));
  Widget _segment(String title,bool active,VoidCallback onTap)=>Expanded(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),child:Container(margin:const EdgeInsets.all(3),decoration:BoxDecoration(color:active?AppColors.green:Colors.transparent,borderRadius:BorderRadius.circular(10)),child:Center(child:Text(title,style:TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:active?AppColors.ink:AppColors.muted))))));
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key,required this.controller});
  final RobotController controller;
  @override State<AnalyticsPage> createState()=>_AnalyticsPageState();
}
class _AnalyticsPageState extends State<AnalyticsPage> {
  int selected=0;
  List<double> take(List<double> data, List<DateTime> times){
    if(widget.controller.isDemo) return data;
    if(data.isEmpty || times.length!=data.length) return data;
    final lengthInSeconds=const [20,60,300,600][selected];
    final cutoff=DateTime.now().subtract(Duration(seconds:lengthInSeconds));
    return [for(var i=0;i<data.length;i++) if(times[i].isAfter(cutoff)) data[i]];
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.controller,builder:(context,_)=>AppScrollPage(title:'Analytics',children:[
    const SizedBox(height:7),
    Row(children:List.generate(4,(i) => Expanded(
      child: Padding(
        padding:const EdgeInsets.only(right:5),
        child:InkWell(
          onTap:()=>setState(()=>selected=i),
          child:Container(
            height:37,
            decoration:BoxDecoration(color:selected==i?AppColors.green:const Color(0xFFF2F4F2),borderRadius:BorderRadius.circular(9)),
            child:Center(child:Text(const ['Real-Time','1 Min','5 Min','10 Min'][i],style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:selected==i?AppColors.ink:AppColors.muted))),
          ),
        ),
      ),
    ))),
    const SizedBox(height:15),
    Row(children:[
      Expanded(child:_measure(Icons.sensors_rounded,'Distance',showNumber(widget.controller.shownDistance,digits:2,unit:' cm'))),
      const SizedBox(width:12),
      Expanded(child:_measure(Icons.device_hub_rounded,'Yaw',showNumber(widget.controller.shownYaw,unit:'°'))),
    ]),
    const SizedBox(height:18),
    ChartPanel(distance:take(widget.controller.shownDistanceHistory,widget.controller.distanceTimes),yaw:take(widget.controller.shownYawHistory,widget.controller.yawTimes),rangeLabel:const ['20s','1m','5m','10m'][selected],isPreview:widget.controller.isDemo),
    const SizedBox(height:17),
    Text(widget.controller.isDemo?'Showing illustrative sample curves.':widget.controller.connected?'Displaying available live telemetry samples.':'No recorded samples. Connect the ESP32 to start collection.',textAlign:TextAlign.center,style:const TextStyle(fontSize:11,color:AppColors.muted)),
  ]));
  Widget _measure(IconData icon,String title,String value)=>RoboCard(background:const Color(0xFFF6F8F6),padding:const EdgeInsets.all(16),child:Column(children:[Icon(icon,color:AppColors.green,size:30),const SizedBox(height:7),Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600)),const SizedBox(height:6),FittedBox(child:Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))) ]));
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key,required this.controller,this.onBack});
  final RobotController controller;
  final VoidCallback? onBack;
  @override State<SettingsPage> createState()=>_SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController ip;
  late TextEditingController ble;
  @override void initState(){super.initState();ip=TextEditingController(text:widget.controller.ipAddress);ble=TextEditingController(text:widget.controller.bleName);}
  @override void dispose(){ip.dispose();ble.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.controller,builder:(context,_)=>Scaffold(backgroundColor:AppColors.paper,body:SafeArea(child:Column(children:[
    ScreenHeader('Settings',onBack:widget.onBack),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,0,19,60),children:[
      _caption('CONNECTION'),
      RoboCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Robot Wi-Fi IP',style:TextStyle(fontWeight:FontWeight.bold,fontSize:13)),const SizedBox(height:10),
        TextField(controller:ip,decoration:const InputDecoration(prefixIcon:Icon(Icons.wifi_rounded),hintText:'192.168.4.1'),keyboardType:TextInputType.url),
        const SizedBox(height:12),
        GreenButton(widget.controller.connecting?'Connecting…':'Connect Wi-Fi',loading:widget.controller.connecting,onPressed:()async{
          widget.controller.setIp(ip.text);
          final ok=await widget.controller.connectWifi();
          if(!context.mounted)return;
          showNotice(context,ok?'Connected to RoboCar over Wi-Fi.':widget.controller.error);
        }),
        const SizedBox(height:15),
        const Text('BLE Device Name',style:TextStyle(fontWeight:FontWeight.bold,fontSize:13)),const SizedBox(height:10),
        TextField(controller:ble,decoration:const InputDecoration(prefixIcon:Icon(Icons.bluetooth_rounded),hintText:'RoboCar_BLE'),onSubmitted:widget.controller.setBleName),
        const SizedBox(height:10),OutlinedButton.icon(onPressed:(){widget.controller.setBleName(ble.text);Navigator.push(context,MaterialPageRoute(builder:(_)=>BleDiscoverScreen(controller:widget.controller)));},icon:const Icon(Icons.bluetooth_searching_rounded),label:const Text('Scan Bluetooth Devices')),
      ])),
      if(widget.controller.mode==ConnectionMode.ble && widget.controller.writableCharacteristics.isNotEmpty)...[
        const SizedBox(height:16),
        _caption('BLE COMMAND CHARACTERISTIC'),
        RoboCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Choose the GATT characteristic used by your firmware for commands.',style:TextStyle(fontSize:12,color:AppColors.muted)),
          const SizedBox(height:9),
          ...widget.controller.writableCharacteristics.map((characteristic)=>RadioListTile<String>(dense:true,contentPadding:EdgeInsets.zero,title:Text(characteristic.uuid.toString(),style:const TextStyle(fontSize:11)),value:characteristic.uuid.toString(),groupValue:widget.controller.bleWriteCharacteristic?.uuid.toString(),onChanged:(_)=>widget.controller.chooseCharacteristic(characteristic))),
        ])),
      ],
      const SizedBox(height:18),
      _caption('DISPLAY'),
      RoboCard(child:SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Sample Data Preview',style:TextStyle(fontWeight:FontWeight.bold,fontSize:14)),subtitle:const Text('Show illustrative sensor values only while disconnected.',style:TextStyle(fontSize:11,color:AppColors.muted)),activeThumbColor:AppColors.green,value:widget.controller.demoPreview,onChanged:widget.controller.setPreview)),
      const SizedBox(height:18),
      _caption('DEVICE STATUS'),
      RoboCard(child:Column(children:[
        _row('Connection',widget.controller.statusLabel),const Divider(color:AppColors.line),
        _row('Last Command',widget.controller.lastCommand),const Divider(color:AppColors.line),
        _row('Firmware State',widget.controller.robotMode??'Not reported'),
      ])),
      const SizedBox(height:15),
      OutlinedButton.icon(onPressed:widget.controller.connected?()async{await widget.controller.disconnect();if(context.mounted)showNotice(context,'Disconnected');}:null,icon:const Icon(Icons.link_off_rounded),label:const Text('Disconnect Robot')),
      const SizedBox(height:22),
      const Text('Wi-Fi API: GET /status, POST /command. BLE writes MANUAL:COMMAND to your selected GATT characteristic. Extra calibration endpoints must be implemented on the ESP32.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:AppColors.muted,height:1.6)),
    ])),
  ]))));
  Widget _caption(String name)=>Padding(padding:const EdgeInsets.only(bottom:10,left:3),child:Text(name,style:const TextStyle(color:AppColors.muted,fontSize:11,letterSpacing:1,fontWeight:FontWeight.w900)));
  Widget _row(String name,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[Text(name,style:const TextStyle(fontSize:13)),const Spacer(),Flexible(child:Text(value,textAlign:TextAlign.end,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)))]));
}
