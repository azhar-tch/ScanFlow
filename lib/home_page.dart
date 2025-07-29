import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Pour le presse-papier

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? qrText;
  MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isScanning = true;
  bool _cameraReady = false;
  String? scannedData;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraPermission();
    });
    _bannerAd = BannerAd(
      //adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      adUnitId: 'ca-app-pub-4010709320824476/8880785694',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Erreur chargement pub : $error');
        },
      ),
    )..load();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }


  Future<void> _checkCameraPermission() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedStatus = await Permission.camera.status;
    if (updatedStatus.isGranted) {
      setState(() {
        _cameraReady = true;
      });
    } else {
      setState(() {
        _cameraReady = false;
      });
    }
  }

  void _resetScanner() {
    setState(() {
      qrText = null;
      isScanning = true;
    });
    cameraController.start();
  }

  void _copyToClipboard() {
    if (qrText != null) {
      Clipboard.setData(ClipboardData(text: qrText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied to clipboard")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _cameraReady
          ? Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                  child:SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                isScanning
                                    ? 'Position the QR code in the frame'
                                    : 'QR code successfully detected !',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyan.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: MobileScanner(
                                        controller: cameraController,
                                        onDetect: (capture) {
                                          if (!isScanning) return;
                                          final List<Barcode> barcodes = capture.barcodes;
                                          for (final barcode in barcodes) {
                                            if (barcode.rawValue != null) {
                                              cameraController.stop();
                                              setState(() {
                                                qrText = barcode.rawValue;
                                                isScanning = false;
                                              });
                                              break;
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    if (isScanning) ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(padding: EdgeInsets.only(top: 60),
                                        child: Container(
                                          width: 250,
                                          height: 250,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.cyan,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Stack(
                                            children: [
                                              ...List.generate(4, (index) {
                                                final corners = [
                                                  Alignment.topLeft,
                                                  Alignment.topRight,
                                                  Alignment.bottomLeft,
                                                  Alignment.bottomRight,
                                                ];
                                                return Align(
                                                  alignment: corners[index],
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: index < 2 ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
                                                        bottom: index >= 2 ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
                                                        left: index.isEven ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
                                                        right: index.isOdd ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                              AnimatedBuilder(
                                                animation: _animation,
                                                builder: (context, child) {
                                                  return Positioned(
                                                    top: _animation.value * 220,
                                                    left: 10,
                                                    right: 10,
                                                    child: Container(
                                                      height: 2,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.cyan,
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.cyan,
                                                            blurRadius: 8,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        )
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: qrText != null
                                      ? [
                                    Colors.green.withOpacity(0.2),
                                    Colors.green.withOpacity(0.1),
                                  ]
                                      : [
                                    Colors.grey.withOpacity(0.1),
                                    Colors.grey.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: qrText != null
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    qrText != null ? Icons.check_circle : Icons.qr_code_scanner,
                                    color: qrText != null ? Colors.green : Colors.grey,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    qrText != null ? 'Result:' : 'Pending...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (qrText != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SelectableText(
                                        qrText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _resetScanner,
                                            icon: const Icon(Icons.refresh, color: Colors.white),
                                            label: const Text('Scan again', style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.cyan,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                              elevation: 8,
                                              shadowColor: Colors.cyan.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _copyToClipboard,
                                            icon: const Icon(Icons.copy, color: Colors.white),
                                            label: const Text('Copie', style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                              elevation: 8,
                                              shadowColor: Colors.green.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      'Scan a QR code',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              )
            ],
          )
        ),
      )
          : const Center(
        child: Text('Camera permission denied or not yet granted'),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}
