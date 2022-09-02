import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

// Type definitions to enforce a consistent use of the API
typedef ARViewCreatedCallback = void Function(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager);

/// Factory method for creating a platform-dependent AR view
abstract class PlatformARView {
  factory PlatformARView(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return AndroidARView();
      case TargetPlatform.iOS:
        return IosARView();
      default:
        throw FlutterError;
    }
  }

  Widget build(
      {@required BuildContext context,
      @required ARViewCreatedCallback arViewCreatedCallback,
      @required PlaneDetectionConfig planeDetectionConfig});

  /// Callback function that is executed once the view is established
  void onPlatformViewCreated(int id);
}

/// Instantiates [ARSessionManager], [ARObjectManager] and returns them to the widget instantiating the [ARView] using the [arViewCreatedCallback]
createManagers(
    int id,
    BuildContext? context,
    ARViewCreatedCallback? arViewCreatedCallback,
    PlaneDetectionConfig? planeDetectionConfig) {
  if (context == null ||
      arViewCreatedCallback == null ||
      planeDetectionConfig == null) {
    return;
  }
  arViewCreatedCallback(ARSessionManager(id, context, planeDetectionConfig),
      ARObjectManager(id), ARAnchorManager(id), ARLocationManager());
}

/// Android-specific implementation of [PlatformARView]
/// Uses Hybrid Composition to increase peformance on Android 9 and below (https://flutter.dev/docs/development/platform-integration/platform-views)
class AndroidARView implements PlatformARView {
  late BuildContext? _context;
  late ARViewCreatedCallback? _arViewCreatedCallback;
  late PlaneDetectionConfig? _planeDetectionConfig;

  @override
  void onPlatformViewCreated(int id) {
    print("Android platform view created!");
    createManagers(id, _context, _arViewCreatedCallback, _planeDetectionConfig);
  }

  @override
  Widget build(
      {BuildContext? context,
      ARViewCreatedCallback? arViewCreatedCallback,
      PlaneDetectionConfig? planeDetectionConfig}) {
    _context = context;
    _arViewCreatedCallback = arViewCreatedCallback;
    _planeDetectionConfig = planeDetectionConfig;
    // This is used in the platform side to register the view.
    final String viewType = 'ar_flutter_plugin';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}

/// iOS-specific implementation of [PlatformARView]
class IosARView implements PlatformARView {
  BuildContext? _context;
  ARViewCreatedCallback? _arViewCreatedCallback;
  PlaneDetectionConfig? _planeDetectionConfig;

  @override
  void onPlatformViewCreated(int id) {
    print("iOS platform view created!");
    createManagers(id, _context, _arViewCreatedCallback, _planeDetectionConfig);
  }

  @override
  Widget build(
      {BuildContext? context,
      ARViewCreatedCallback? arViewCreatedCallback,
      PlaneDetectionConfig? planeDetectionConfig}) {
    _context = context;
    _arViewCreatedCallback = arViewCreatedCallback;
    _planeDetectionConfig = planeDetectionConfig;
    // This is used in the platform side to register the view.
    final String viewType = 'ar_flutter_plugin';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}

/// If camera permission is granted, [ARView] creates a platform-dependent view from the factory method [PlatformARView]. To instantiate an [ARView],
/// the calling widget needs to pass the callback function [onARViewCreated] to which the function [createManagers] returns managers such as the
/// [ARSessionManager] and the [ARObjectManager]. [planeDetectionConfig] is passed to the constructor to determine which types of planes the underlying
/// AR frameworks should track (defaults to none).
/// If camera permission is not given, the user is prompted to grant it. To modify the UI of the prompts, the following named parameters can be used:
/// [permissionPromptDescription], [permissionPromptButtonText] and [permissionPromptParentalRestriction].
class ARView extends StatefulWidget {
  /// Function to be called when the AR View is created
  final ARViewCreatedCallback onARViewCreated;

  /// Configures the type of planes ARCore and ARKit should track. defaults to none
  final PlaneDetectionConfig planeDetectionConfig;

  /// Configures whether or not to display the device's platform type above the AR view. Defaults to false

  ARView({
    Key? key,
    required this.onARViewCreated,
    this.planeDetectionConfig = PlaneDetectionConfig.none,
  }) : super(key: key);
  @override
  _ARViewState createState() => _ARViewState(
      );
}

class _ARViewState extends State<ARView> {
  PermissionStatus _cameraPermission = PermissionStatus.denied;


  @override
  void initState() {
    super.initState();
    initCameraPermission();
  }

  initCameraPermission() async {
    requestCameraPermission();
  }

  requestCameraPermission() async {
    final cameraPermission = await Permission.camera.request();
    setState(() {
      _cameraPermission = cameraPermission;
    });
  }

  requestCameraPermissionFromSettings() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
    setState(() {
      _cameraPermission = cameraPermission;
    });
  }

  @override
  build(BuildContext context) {
    switch (_cameraPermission) {
      case (PermissionStatus
          .limited): //iOS-specific: permissions granted for this specific application
      case (PermissionStatus.granted):
        {
          return PlatformARView(Theme.of(context).platform).build(
              context: context,
              arViewCreatedCallback: widget.onARViewCreated,
              planeDetectionConfig: widget.planeDetectionConfig);
        }
      case (PermissionStatus.denied):
        {
          return  Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    "Zur Nutzung von Augmented Reality, benötigen wir den Zugriff auf deine Kamera",
                    style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
                SizedBox(
                  height: 24,
                ),
                TextButton(
                    style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.fromLTRB(12, 0, 12, 0)),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                        backgroundColor:
                            MaterialStateProperty.all(const Color(0xff17c387)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ))),
                    onPressed: () async => {await requestCameraPermission()},
                    child: const Text("Zugriff erlauben"))
              ],
            ),
          );
        }
      case (PermissionStatus
          .permanentlyDenied): //Android-specific: User needs to open Settings to give permissions
        {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                 
              children: [
                Text(
                  "Zur Nutzung von Augmented Reality, benötigen wir den Zugriff auf deine Kamera",
                  style: TextStyle(color: Colors.white), textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 24,
                ),
                TextButton(
                    style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.fromLTRB(12, 0, 12, 0)),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                        backgroundColor:
                            MaterialStateProperty.all(const Color(0xff17c387)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ))),
                    onPressed: () async =>
                        {await requestCameraPermissionFromSettings()},
                    child: const Text("Zugriff erlauben"))
              ],
            ),
          );
        }
      case (PermissionStatus.restricted):
        {
          //iOS only
          return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    "Dert Zugriff auf deine Kamerawurde permanent untersagt. Bitte überprüfe die Berechtigungen in den Systemeinstellungen.", textAlign: TextAlign.center,  style: TextStyle(color: Colors.white)),
              ));
        }
      default:
        return Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Etwas ist schief gelaufen', textAlign: TextAlign.center,   style: TextStyle(color: Colors.white)),
        ));
    }
  }
}
