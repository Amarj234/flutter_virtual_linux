import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LinuxVMConsole(),
    );
  }
}

class LinuxVMConsole extends StatefulWidget {
  const LinuxVMConsole({super.key});

  @override
  State<LinuxVMConsole> createState() => _LinuxVMConsoleState();
}

class _LinuxVMConsoleState extends State<LinuxVMConsole> {
  final List<String> _output = [];
  Process? _qemuProcess;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVM();
  }

  @override
  void dispose() {
    _qemuProcess!.kill(ProcessSignal.sigkill); // Force kill

    print('QEMU terminated');
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<String> _extractAssetToFile(String assetPath, String filename) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      if (!await file.exists()) {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);

        if (Platform.isMacOS) {
          // Remove quarantine attribute
          await Process.run('xattr', ['-d', 'com.apple.quarantine', filePath]);
          // Set executable permission if it's QEMU
          if (filename.contains('qemu-system')) {
            await Process.run('chmod', ['+x', filePath]);
          }
        }
      }

      return filePath;
    } catch (e) {
      throw Exception('Failed to extract $filename: $e');
    }
  }

  Future<String?> _findSystemQemu() async {
    try {
      final result = await Process.run('which', ['qemu-system-aarch64']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  String _outputBuffer = '';


  void _appendOutput(String data) {
    _outputBuffer += data;

    // Only process full lines
    final lines = _outputBuffer.split('\n');
    _outputBuffer = lines.removeLast(); // Save the incomplete line

    setState(() {
      _output.addAll(lines.where((line) => line.trim().isNotEmpty));
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }


  Future<void> _initializeVM() async {


    try {
      setState(() {
        _output.add('Initializing QEMU virtual machine...');
        _isLoading = true;
        _errorMessage = null;
      });

      // Try to use system QEMU first
      String qemuPath = await _findSystemQemu() ?? await _extractAssetToFile(
        'assets/qemu/qemu-system-aarch64',
        'qemu-system-aarch64',
      );

      // Extract other required files
      final diskPath = await _extractAssetToFile(
        'assets/qemu/alpine_disk.img',
        'alpine_disk.img',
      );

      final alpineIso = await _extractAssetToFile(
        'assets/qemu/alpine-virt-3.22.0-aarch64.iso',
        'alpine-virt-3.22.0-aarch64.iso',
      );

      final edk2Code = await _extractAssetToFile(
        'assets/qemu/edk2-aarch64-code.fd',
        'edk2-aarch64-code.fd',
      );

      setState(() {
        _output.add('Using QEMU at: $qemuPath');
        _output.add('Starting virtual machine...');
      });

      final args = [
        '-machine', 'virt',
        '-cpu', 'cortex-a72',
        '-m', '1024',
        '-nographic',
        '-drive', 'if=pflash,format=raw,readonly=on,file=$edk2Code',
        '-cdrom', alpineIso,
        '-drive', 'file=$diskPath,if=none,id=hd0,format=qcow2',
        '-device', 'virtio-blk-device,drive=hd0',
        '-serial', 'mon:stdio',
        '-boot', 'd',
        '-netdev', 'user,id=net0',
        '-device', 'virtio-net-device,netdev=net0',

      ];

      _qemuProcess = await Process.start(qemuPath, args);

      _qemuProcess!.stdout
          .transform(const Utf8Decoder())
          .listen(_appendOutput);

      _qemuProcess!.stderr
          .transform(const Utf8Decoder())
          .listen((data) => _appendOutput('[ERROR] $data'));

      _qemuProcess!.exitCode.then((code) {
        setState(() {
          _output.add('\nQEMU process exited with code $code');
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start VM: $e\n\n'
            'Possible solutions:\n'
            '1. Install QEMU with Homebrew: "brew install qemu"\n'
            '2. Disable app sandboxing in entitlements file\n'
            '3. Grant full disk access to your IDE in macOS Settings';
        _isLoading = false;
      });
    }
  }

  Future<void> _restartVM() async {
    if (_qemuProcess != null) {
      print('Terminating QEMU...');
      _qemuProcess!.kill(ProcessSignal.sigkill); // Force kill
      await _qemuProcess!.exitCode;
      print('QEMU terminated');
      _qemuProcess = null;
    }

    setState(() {
      _output.clear();
      _errorMessage = null;
      _isLoading = true;
    });
    await _initializeVM();
  }

  void _sendCommand(String command) {
    if (_qemuProcess != null) {
      _qemuProcess!.stdin.writeln(command);
      //_appendOutput('\$ $command');
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpine Linux VM Console'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _restartVM),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            ...[
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(
                    _output.join('\n'),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'Courier',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                  color: Colors.black87,
                ),
                child: Row(
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.greenAccent,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: _sendCommand,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'Courier',
                          fontSize: 14,
                        ),
                        cursorColor: Colors.greenAccent,
                        decoration: const InputDecoration(
                          hintText: 'Enter command...',
                          hintStyle: TextStyle(color: Colors.white38),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Colors.greenAccent,
            ),
        ],
      ),
    );
  }
}